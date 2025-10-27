import os
import sys
import json
import argparse
import subprocess
import shlex
import glob
import shutil
from pathlib import Path
from xml.etree import ElementTree as ET

from cocotb.runner import get_runner, VHDL


# --------- Configuração base e defaults reprodutíveis ---------
REPO = Path(__file__).resolve().parents[2]
PLUSARGS_ENV = os.getenv("COCOTB_PLUSARGS", "")
plusargs = [a for a in PLUSARGS_ENV.split() if a.strip()]

os.environ.setdefault("PYTHONPATH", str(REPO))
os.environ.setdefault("ARCHTEST_REF_DIR", "tests/third_party/riscv-arch-test/tools/reference_outputs")
os.environ.setdefault("ARCHTEST_MAX_CYCLES", "200000")
os.environ.setdefault("PYTHONUNBUFFERED", "1")


# --------- Constantes usadas no pipeline de COMPLIANCE ---------
TOPLEVEL = "rv32i"
SOURCES = [
    "src/rv32i_ctrl_consts.vhd",
    "src/ALU.vhd",
    "src/RegFile.vhd",
    "src/RAM.vhd",
    "src/ROM_simulation.vhd",
    "src/InstructionDecoder.vhd",
    "src/ExtenderImm.vhd",
    "src/ExtenderRAM.vhd",
    "src/StoreManager.vhd",
    "src/genericAdder.vhd",
    "src/genericAdderU.vhd",
    "src/genericMux2x1.vhd",
    "src/genericMux3x1.vhd",
    "src/genericRegister.vhd",
    "src/rv32i.vhd",
]
TEST_MODULE_ARCHTEST = "tests.python.unittests.archtest.test_archtest"


# --------- Utilitários ---------
def _sh(cmd: str, cwd: str | None = None, env: dict | None = None) -> str:
    r = subprocess.run(shlex.split(cmd), cwd=cwd, env=env, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"cmd failed: {cmd}\nstdout:\n{r.stdout}\nstderr:\n{r.stderr}")
    return r.stdout


def _bin_to_romhex(bin_path: Path, hex_path: Path, warn_threshold_bytes: int = 16*1024*1024):
    import struct
    size = bin_path.stat().st_size
    if size > warn_threshold_bytes:
        print(f"[WARN] BIN muito grande ({size} bytes). "
              f"Isso indica que o ELF ainda tem seções altas (ex.: .signature/tohost). "
              f"Reveja os --only-section/--remove-section do objcopy.")

    with open(bin_path, "rb") as f_in, open(hex_path, "w") as f_out:
        while True:
            chunk = f_in.read(4)
            if not chunk:
                break
            if len(chunk) < 4:
                chunk = chunk + b"\x00"*(4-len(chunk))
            (word,) = struct.unpack("<I", chunk)
            f_out.write(f"{word:08x}\n")


def _junit_fail_error_counts(xml_path: Path) -> tuple[int, int]:
    if not xml_path.exists():
        return 0, 1
    root = ET.parse(xml_path).getroot()
    failures = 0
    errors = 0
    for tc in root.findall(".//testcase"):
        if tc.find("failure") is not None:
            failures += 1
        if tc.find("error") is not None:
            errors += 1

    def gi(n, k):
        try:
            return int(n.attrib.get(k, "0"))
        except Exception:
            return 0

    if root.tag == "testsuite":
        failures += gi(root, "failures")
        errors += gi(root, "errors")
    elif root.tag == "testsuites":
        for ts in root.findall("testsuite"):
            failures += gi(ts, "failures")
            errors += gi(ts, "errors")

    return failures, errors


def _read_symbols_with_nm(elf_path: 'Path | str', riscv_prefix: str) -> dict:
    import subprocess
    elf_str = str(elf_path)
    nm = riscv_prefix + "nm"
    r = subprocess.run([nm, "-g", elf_str], capture_output=True, text=True, check=True)
    syms = {}
    for line in r.stdout.splitlines():
        parts = line.strip().split()
        if len(parts) >= 3:
            addr, kind, name = parts[0], parts[1], parts[2]
            if name in ("begin_signature", "end_signature", "tohost", "_start", "rvtest_entry_point"):
                syms[name] = "0x" + addr.lower()
    return syms


# --------- Geração de referência (Spike) ---------
def _ensure_reference_signature(meta: dict) -> None:
    isa = os.getenv("ARCHTEST_ISA", "rv32i")
    tools_dir = Path(os.getenv("ARCHTEST_TOOLS_DIR", "tests/third_party/riscv-arch-test/tools")).resolve()
    ref_dir = Path(os.getenv("ARCHTEST_REF_DIR", str(tools_dir / "reference_outputs"))).resolve()
    logs_dir = ref_dir / "spike-logs"
    policy = os.getenv("ARCHTEST_REF_POLICY", "auto").lower()

    elf = Path(meta["elf"])
    test_name = meta["test"]
    ref_dir.mkdir(parents=True, exist_ok=True)
    logs_dir.mkdir(parents=True, exist_ok=True)
    ref_sig = ref_dir / f"{test_name}.sig"
    logf = logs_dir / f"{test_name}.log"

    if policy == "skip":
        return
    if policy != "regen" and ref_sig.exists():
        return

    mem_token = os.getenv("ARCHTEST_SPIKE_MEM", "").strip()
    if not mem_token:
        # fallback portável: UM único -m com ROM e RAM em decimal
        mem_token = "-m2147483648:1048576,536870912:65536"

    cmd = f"spike --isa={isa} {mem_token} +signature={ref_sig} +signature-granularity=4 {elf}"
    r = subprocess.run(shlex.split(cmd), capture_output=True, text=True)
    logf.write_text("CMD: " + cmd + "\n\nSTDOUT:\n" + r.stdout + "\n\nSTDERR:\n" + r.stderr)
    if r.returncode != 0 or not ref_sig.exists():
        raise RuntimeError(
            f"Falha no Spike ao gerar referência para {test_name}.\n"
            f"cmd: {cmd}\nstdout:\n{r.stdout}\nstderr:\n{r.stderr}"
        )


# --------- Build e execução (Cocotb/GHDL) ---------
def run_cocotb_test(
    toplevel: str,
    sources: list[str],
    test_module: str,
    parameters: dict | None = None,
    extra_env: dict | None = None,
    build_suffix: str | None = None,
):
    tests_root = Path(__file__).resolve().parents[1]
    repo_root = Path(__file__).resolve().parents[2]
    sys.path.append(str(repo_root))

    sim = os.getenv("SIM", "ghdl")
    vhdl_sources = [(Path(src) if Path(src).is_absolute() else (repo_root / src)) for src in sources]
    runner = get_runner(sim)

    if ".entities." in test_module:
        group = "entities"
    elif ".instructions." in test_module:
        group = "instructions"
    elif ".archtest." in test_module:
        group = "archtest"
    else:
        group = "misc"

    if group == "instructions":
        test_name = test_module.split(".")[-2]
        build_dir = tests_root / "python" / "sim_build" / group / test_name
    else:
        build_dir = tests_root / "python" / "sim_build" / group / toplevel
    if build_suffix:
        build_dir = build_dir.with_name(build_dir.name + f"_{build_suffix}")

    if build_dir.exists():
        shutil.rmtree(build_dir)
    build_dir.mkdir(parents=True, exist_ok=True)

    # Normaliza possíveis parâmetros de caminho
    if parameters:
        abs_params: dict[str, str] = {}
        for k, v in parameters.items():
            if isinstance(v, bool):
                abs_params[k] = "true" if v else "false"
            else:
                vpath = Path(str(v))
                if vpath.exists():
                    abs_params[k] = str(vpath.resolve())
                else:
                    cand = repo_root / str(v)
                    abs_params[k] = str(cand.resolve()) if cand.exists() else str(v)
        parameters = abs_params

    runner.build(
        vhdl_sources=vhdl_sources,
        hdl_toplevel=toplevel,
        always=True,
        build_dir=build_dir,
        build_args=[VHDL("--std=08"), VHDL("--work=top")],
        parameters=parameters or {},
    )

    base_env = {} if extra_env is None else dict(extra_env)
    for k in [
        "WAVES",
        "GHDL_DUMP_VCD",
        "GHDL_DUMP_FST",
        "GHDL_DUMP_GHW",
        "COCOTB_VCD_FILE",
        "COCOTB_WAVEFORM",
        "COCOTB_WAVES",
        "GHDL_TRACE_FORMAT",
        "TRACEFILE",
        "TRACE_FILE",
    ]:
        os.environ.pop(k, None)
        base_env.pop(k, None)
    base_env["WAVES"] = "0"
    base_env["PYTHONPATH"] = os.environ.get("PYTHONPATH", str(repo_root))

    runner.test(
        hdl_toplevel=toplevel,
        hdl_toplevel_lang="vhdl",
        test_module=test_module,
        build_dir=build_dir,
        plusargs=plusargs,
        test_args=["--std=08", "--work=top"],
        extra_env=base_env,
    )

    results = build_dir / "results.xml"
    failures, errors = _junit_fail_error_counts(results)
    ok = (failures == 0 and errors == 0)
    return ok, failures, errors, build_dir


# --------- Build de um teste da suíte arch-test ---------
def build_archtest_one(
    repo_root: Path,
    test_name: str,
    env_dir: Path,
    isa_dir: Path,
    glue_dir: Path,
    out_dir: Path,
    riscv_prefix: str,
) -> dict:
    cc = riscv_prefix + "gcc"
    objcopy = riscv_prefix + "objcopy"
    out_dir.mkdir(parents=True, exist_ok=True)

    asm = (isa_dir / f"{test_name}.S").resolve()
    if not asm.exists():
        raise FileNotFoundError(f"Não achei o fonte: {asm}")

    build_o = out_dir / f"{test_name}.o"
    elf = out_dir / f"{test_name}.elf"
    hexfile = out_dir / f"{test_name}.hex"
    meta_json = out_dir / f"{test_name}.meta.json"

    ldscript = (repo_root / "tests/third_party/riscv-arch-test/tools/spike/low.ld").resolve()
    if not ldscript.exists():
        raise FileNotFoundError(f"low.ld não encontrado em {ldscript}")

    cflags = [
        "-march=rv32i",
        "-mabi=ilp32",
        "-nostdlib",
        "-nostartfiles",
        "-ffreestanding",
        "-Os",
        f"-I{env_dir}",
        f"-I{glue_dir}",
        "-D__riscv_xlen=32",
        "-DXLEN=32",
        "-DRVTEST_RV32I",
    ]
    ldflags = [f"-T{ldscript}", "-nostdlib", "-nostartfiles"]

    subprocess.run([cc, *cflags, "-c", str(asm), "-o", str(build_o)], check=True)
    subprocess.run([cc, *ldflags, str(build_o), "-o", str(elf)], check=True)

    binfile = out_dir / f"{test_name}.bin"
    subprocess.run([
        objcopy, "-O", "binary",
        "--only-section=.init", "--only-section=.fini",
        "--only-section=.text", "--only-section=.text.*",
        "--only-section=.rodata", "--only-section=.rodata.*",
        "--only-section=.srodata", "--only-section=.srodata.*",
        "--only-section=.data", "--only-section=.data.*",
        "--only-section=.sdata", "--only-section=.sdata.*",
        str(elf), str(binfile)
    ], check=True)

    _hex = out_dir / f"{test_name}.hex"
    _bin_to_romhex(binfile, _hex)

    syms = _read_symbols_with_nm(elf, riscv_prefix)
    meta = {"test": test_name, "elf": str(elf), "hex": str(hexfile), "symbols": syms}
    meta_json.write_text(json.dumps(meta, indent=2))
    return meta


# --------- Helpers de seleção ---------
def _normalize_one_name(arch_isa_dir: Path, one: str) -> str:
    cand = arch_isa_dir / f"{one}.S"
    if cand.exists():
        return one
    m = list(arch_isa_dir.glob(f"{one}-*.S"))
    if not m:
        raise FileNotFoundError(f"Não achei {one}.S nem {one}-*.S em {arch_isa_dir}")
    return m[0].stem


# --------- Pipelines de alto nível ---------
def run_compliance(one: str | None) -> bool:
    repo_root = Path(__file__).resolve().parents[2]
    arch_env_dir = (repo_root / "tests/third_party/riscv-arch-test/riscv-test-suite/env").resolve()
    arch_isa_dir = (repo_root / "tests/third_party/riscv-arch-test/riscv-test-suite/rv32i_m/I/src").resolve()
    arch_glue_dir = (repo_root / "tests/third_party/archtest-utils").resolve()
    arch_out_dir = (repo_root / "build/archtest").resolve()
    riscv_prefix = os.getenv("RISCV_PREFIX", "riscv-none-elf-")

    tests = [_normalize_one_name(arch_isa_dir, one)] if one else sorted(p.stem for p in arch_isa_dir.glob("*.S"))

    passed = failed = 0
    for t in tests:
        print(f"\n=================== COMPLIANCE: {t} ===================")
        meta = build_archtest_one(repo_root, t, arch_env_dir, arch_isa_dir, arch_glue_dir, arch_out_dir, riscv_prefix)
        try:
            _ensure_reference_signature(meta)
        except Exception as e:
            print(f"[WARN] Não foi possível gerar referência via Spike para {t}: {e}")

        hex_path = meta["hex"]
        extra_env = {"ARCHTEST_META": json.dumps(meta)}
        try:
            ok, failures, errors, _ = run_cocotb_test(
                toplevel=TOPLEVEL,
                sources=SOURCES,
                test_module=TEST_MODULE_ARCHTEST,
                parameters={"ROM_FILE": str(hex_path)},
                extra_env=extra_env,
                build_suffix=f"arch_{t}",
            )
            if ok:
                passed += 1
                print(f"[PASS {t}]")
            else:
                failed += 1
                print(f"[FAIL {t}] junit: failures={failures} errors={errors}")
        except Exception as e:
            failed += 1
            print(f"[FAIL {t}] exception: {e}")

    print(f"\nResumo compliance: PASS={passed}  FAIL={failed}  TOTAL={passed+failed}")
    return failed == 0


def run_unit(selection: str | None) -> bool:
    tests_root = Path(__file__).resolve().parents[1]
    json_path = tests_root / "python" / "tests.json"
    cfg = json.loads(json_path.read_text())

    names = [selection] if selection else sorted(cfg.keys())

    passed = failed = 0
    for name in names:
        if name not in cfg:
            failed += 1
            print(f"[FAIL {name}] ausente em tests.json")
            continue

        c = cfg[name]
        toplevel = c.get("toplevel", TOPLEVEL)
        sources = c.get("sources", SOURCES)
        test_module = c.get("test_module", "")
        parameters = c.get("parameters", {})

        try:
            ok, failures, errors, _ = run_cocotb_test(
                toplevel=toplevel,
                sources=sources,
                test_module=test_module,
                parameters=parameters,
                extra_env={},
                build_suffix=f"unit_{name}",
            )
            if ok:
                passed += 1
                print(f"[PASS {name}]")
            else:
                failed += 1
                print(f"[FAIL {name}] junit: failures={failures} errors={errors}")
        except Exception as e:
            failed += 1
            print(f"[FAIL {name}] exception: {e}")

    print(f"\nResumo unit: PASS={passed}  FAIL={failed}  TOTAL={passed+failed}")
    return failed == 0


# --------- CLI ---------
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", nargs="?", default="unit", choices=["assemble", "compliance", "unit"])
    parser.add_argument("arg", nargs="?", default="")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    arch_env_dir = (repo_root / "tests/third_party/riscv-arch-test/riscv-test-suite/env").resolve()
    arch_isa_dir = (repo_root / "tests/third_party/riscv-arch-test/riscv-test-suite/rv32i_m/I/src").resolve()
    arch_glue_dir = (repo_root / "tests/third_party/archtest-utils").resolve()
    arch_out_dir = (repo_root / "build/archtest").resolve()
    riscv_prefix = os.getenv("RISCV_PREFIX", "riscv-none-elf-")

    if args.mode == "assemble":
        if args.arg:
            tests = [_normalize_one_name(arch_isa_dir, args.arg)]
        else:
            tests = sorted(p.stem for p in arch_isa_dir.glob("*.S"))
        for t in tests:
            print(f"[assemble] {t}")
            build_archtest_one(repo_root, t, arch_env_dir, arch_isa_dir, arch_glue_dir, arch_out_dir, riscv_prefix)
        print("Montagem concluída. ELFs/HEX/META em build/archtest.")
        sys.exit(0)

    if args.mode == "compliance":
        ok = run_compliance(one=(args.arg or None))
        sys.exit(0 if ok else 1)

    ok = run_unit(selection=(args.arg or None))
    sys.exit(0 if ok else 1)