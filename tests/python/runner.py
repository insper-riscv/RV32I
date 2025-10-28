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

# defaults "hard"
DEFAULT_REF_DIR        = str(REPO / "tests/third_party/riscv-arch-test/tools/reference_outputs")
DEFAULT_SPIKE_MEM      = "-m2147483648:1048576,536870912:65536"
DEFAULT_ISA            = "rv32i"
DEFAULT_MAX_CYCLES     = "200000"
DEFAULT_RISCV_PREFIX   = "riscv32-unknown-elf-"

# garante que o processo atual tem esses valores
os.environ.setdefault("ARCHTEST_REF_DIR", DEFAULT_REF_DIR)
os.environ.setdefault("ARCHTEST_SPIKE_MEM", DEFAULT_SPIKE_MEM)
os.environ.setdefault("ARCHTEST_ISA", DEFAULT_ISA)
os.environ.setdefault("ARCHTEST_MAX_CYCLES", DEFAULT_MAX_CYCLES)
os.environ.setdefault("RISCV_PREFIX", DEFAULT_RISCV_PREFIX)

os.environ.setdefault("PYTHONPATH", str(REPO))
os.environ.setdefault("PYTHONUNBUFFERED", "1")
os.environ.setdefault("ARCHTEST_REF_POLICY", "auto")  # ou "regen" se você quer sempre regenerar


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


def _read_symbols_with_nm(elf_path, riscv_prefix):
    nmtool = riscv_prefix + "nm"
    out = subprocess.check_output([nmtool, "-n", str(elf_path)], text=True)
    syms = {}
    for line in out.splitlines():
        parts = line.strip().split()
        if len(parts) >= 3:
            addr, typ, name = parts[0], parts[1], parts[2]
            if name in ("tohost", "begin_signature", "end_signature"):
                syms[name] = "0x" + addr
    return syms


# --------- Geração de referência (Spike) ---------
def _ensure_reference_signature(meta: dict) -> None:
    isa = os.getenv("ARCHTEST_ISA", "rv32i")
    tools_dir = Path(os.getenv("ARCHTEST_TOOLS_DIR", "tests/third_party/riscv-arch-test/tools")).resolve()
    ref_dir = Path(os.getenv("ARCHTEST_REF_DIR", str(tools_dir / "reference_outputs"))).resolve()
    logs_dir = ref_dir / "spike-logs"
    policy = os.getenv("ARCHTEST_REF_POLICY", "auto").lower()

    elf = Path(meta["elf_spike"])
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
        mem_token = "-m2147483648:1048576,536870912:65536"

    cmd = [
        "spike",
        f"--isa={isa}",
        mem_token,
        f"+signature={ref_sig}",
        "+signature-granularity=4",
        str(elf),
    ]
    r = subprocess.run(cmd, text=True, capture_output=True)
    logf.write_text(
        "CMD: " + " ".join(cmd) + "\n\n"
        "returncode=" + str(r.returncode) + "\n\n"
        "STDOUT:\n" + r.stdout + "\n"
        "STDERR:\n" + r.stderr + "\n"
    )
    if r.returncode != 0 or not ref_sig.exists():
        raise RuntimeError(f"Spike falhou para {test_name}")


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

    base_env = os.environ.copy()
    if extra_env is not None:
        base_env.update(extra_env)

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
    base_env["WAVES"] = "1"
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


def build_for_spike(repo_root, test_name,
                    spike_env_dir,
                    common_env_dir,
                    isa_dir, out_dir,
                    riscv_prefix):
    cc = riscv_prefix + "gcc"

    out_dir.mkdir(parents=True, exist_ok=True)

    asm_test    = (isa_dir / f"{test_name}.S").resolve()
    obj_test    = out_dir / f"{test_name}.spike.test.o"

    boot_spike  = (spike_env_dir / "boot_spike.S").resolve()
    obj_boot    = out_dir / f"{test_name}.spike.boot.o"

    elf_spike   = out_dir / f"{test_name}.spike.elf"
    ld_spike    = (spike_env_dir / "low.ld").resolve()

    cflags_spike = [
        "-march=rv32i_zicsr",
        "-mabi=ilp32",
        "-nostdlib",
        "-nostartfiles",
        "-ffreestanding",
        "-Os",
        f"-I{common_env_dir}",
        "-D__riscv_xlen=32",
        "-DXLEN=32",
        "-DRVTEST_RV32I",
    ]

    ldflags_spike = [
        f"-T{ld_spike}",
        "-nostdlib",
        "-nostartfiles",
        "-Wl,-e,_start",
    ]

    subprocess.run([cc, *cflags_spike,
                    "-c", str(boot_spike),
                    "-o", str(obj_boot)], check=True)

    subprocess.run([cc, *cflags_spike,
                    "-c", str(asm_test),
                    "-o", str(obj_test)], check=True)

    subprocess.run([cc, *ldflags_spike,
                    str(obj_boot),
                    str(obj_test),
                    "-o", str(elf_spike)], check=True)

    return elf_spike


# --------- Build de um teste da suíte arch-test ---------
def build_for_dut(repo_root, test_name,
                  dut_env_dir,
                  common_env_dir,
                  isa_dir, out_dir,
                  riscv_prefix):
    cc      = riscv_prefix + "gcc"
    objcopy = riscv_prefix + "objcopy"

    out_dir.mkdir(parents=True, exist_ok=True)

    asm_test   = (isa_dir / f"{test_name}.S").resolve()
    obj_test   = out_dir / f"{test_name}.dut.test.o"

    elf_dut    = out_dir / f"{test_name}.dut.elf"
    binfile    = out_dir / f"{test_name}.bin"
    hexfile    = out_dir / f"{test_name}.hex"
    meta_json  = out_dir / f"{test_name}.meta.json"

    ld_dut     = (repo_root / "tests/compliance/archtest_dut_env/link.ld").resolve()

    cflags_dut = [
        "-march=rv32i",
        "-mabi=ilp32",
        "-nostdlib",
        "-nostartfiles",
        "-ffreestanding",
        "-Os",
        f"-I{dut_env_dir}",
        f"-I{common_env_dir}",
        "-D__riscv_xlen=32",
        "-DXLEN=32",
        "-DRVTEST_RV32I",
    ]

    ldflags_dut = [
        f"-T{ld_dut}",
        "-nostdlib",
        "-nostartfiles",
        "-Wl,-e,_start",
    ]

    dut_objs = []
    for path in sorted(dut_env_dir.glob("*.S")):
        o = out_dir / f"{test_name}.dut.env_{path.stem}.o"
        subprocess.run([cc, *cflags_dut,
                        "-c", str(path),
                        "-o", str(o)], check=True)
        dut_objs.append(o)

    for path in sorted(dut_env_dir.glob("*.c")):
        o = out_dir / f"{test_name}.dut.env_{path.stem}.o"
        subprocess.run([cc, *cflags_dut,
                        "-c", str(path),
                        "-o", str(o)], check=True)
        dut_objs.append(o)

    subprocess.run([cc, *cflags_dut,
                    "-c", str(asm_test),
                    "-o", str(obj_test)], check=True)

    all_objs_dut = [*dut_objs, obj_test]

    subprocess.run([cc,
                    *ldflags_dut,
                    *map(str, all_objs_dut),
                    "-o", str(elf_dut)],
                   check=True)

    subprocess.run([
        objcopy,
        "-O", "binary",
        "--only-section=.init", "--only-section=.fini",
        "--only-section=.text", "--only-section=.text.*",
        "--only-section=.rodata", "--only-section=.rodata.*",
        "--only-section=.srodata", "--only-section=.srodata.*",
        "--only-section=.data", "--only-section=.data.*",
        "--only-section=.sdata", "--only-section=.sdata.*",
        str(elf_dut), str(binfile)
    ], check=True)

    _bin_to_romhex(binfile, hexfile)

    syms = _read_symbols_with_nm(elf_dut, riscv_prefix)

    meta = {
        "test": test_name,
        "elf_spike": str(out_dir / f"{test_name}.spike.elf"),
        "elf_dut": str(elf_dut),
        "hex": str(hexfile),
        "symbols": syms,
    }
    meta_json.write_text(json.dumps(meta, indent=2))

    return meta


def build_archtest_pair(repo_root, test_name,
                        dut_env_dir,
                        spike_env_dir,
                        common_env_dir,
                        isa_dir, out_dir,
                        riscv_prefix):

    meta = build_for_dut(
        repo_root,
        test_name,
        dut_env_dir,
        common_env_dir,
        isa_dir,
        out_dir,
        riscv_prefix
    )

    elf_spike = build_for_spike(
        repo_root,
        test_name,
        spike_env_dir,
        common_env_dir,
        isa_dir,
        out_dir,
        riscv_prefix
    )

    meta["elf_spike"] = str(elf_spike)
    (out_dir / f"{test_name}.meta.json").write_text(json.dumps(meta, indent=2))

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
def run_compliance(one: str | None,
                   repo_root: Path,
                   dut_env_dir: Path,
                   spike_env_dir: Path,
                   common_env_dir: Path,
                   isa_dir: Path,
                   out_dir: Path,
                   riscv_prefix: str) -> bool:

    tests = [_normalize_one_name(isa_dir, one)] if one else sorted(p.stem for p in isa_dir.glob("*.S"))

    passed = failed = 0
    for t in tests:
        print(f"\n=================== COMPLIANCE: {t} ===================")

        meta = build_archtest_pair(
            repo_root, t,
            dut_env_dir,
            spike_env_dir,
            common_env_dir,
            isa_dir, out_dir,
            riscv_prefix
        )

        try:
            _ensure_reference_signature(meta)
        except Exception as e:
            print(f"[WARN] Não foi possível gerar referência via Spike para {t}: {e}")

        hex_path = meta["hex"]

        tools_dir = repo_root / "tests/third_party/riscv-arch-test/tools"
        ref_dir = Path(os.environ["ARCHTEST_REF_DIR"]).resolve()

        extra_env = {
            "ARCHTEST_META": json.dumps(meta),
            "ARCHTEST_REF_DIR": str(ref_dir),
            "ARCHTEST_MAX_CYCLES": os.environ["ARCHTEST_MAX_CYCLES"],
            "PYTHONPATH": os.environ["PYTHONPATH"],
            "ARCHTEST_ISA": os.environ["ARCHTEST_ISA"],
        }

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
    parser.add_argument("mode", nargs="?", default="unit",
                        choices=["assemble", "compliance", "unit"])
    parser.add_argument("arg", nargs="?", default="")
    args = parser.parse_args()

    repo_root      = Path(__file__).resolve().parents[2]

    # seus diretórios atuais
    dut_env_dir    = (repo_root / "tests/compliance/archtest_dut_env").resolve()
    spike_env_dir  = (repo_root / "tests/compliance/archtest_spike_env").resolve()
    common_env_dir = (repo_root / "tests/compliance/archtest_common_env").resolve()

    isa_dir        = (repo_root / "tests/third_party/riscv-arch-test/riscv-test-suite/rv32i_m/I/src").resolve()
    out_dir        = (repo_root / "build/archtest").resolve()

    riscv_prefix   = os.environ["RISCV_PREFIX"]

    if args.mode == "assemble":
        # gera TODOS os artefatos (elf_dut, elf_spike, hex, meta.json) em build/archtest
        if args.arg:
            tests = [_normalize_one_name(isa_dir, args.arg)]
        else:
            tests = sorted(p.stem for p in isa_dir.glob("*.S"))

        for t in tests:
            print(f"[assemble] {t}")
            build_archtest_pair(
                repo_root,
                t,
                dut_env_dir,
                spike_env_dir,
                common_env_dir,
                isa_dir,
                out_dir,
                riscv_prefix,
            )

        print("Montagem concluída. ELFs/HEX/META em build/archtest.")
        sys.exit(0)

    if args.mode == "compliance":
        ok = run_compliance(
            one=(args.arg or None),
            repo_root=repo_root,
            dut_env_dir=dut_env_dir,
            spike_env_dir=spike_env_dir,
            common_env_dir=common_env_dir,
            isa_dir=isa_dir,
            out_dir=out_dir,
            riscv_prefix=riscv_prefix,
        )
        sys.exit(0 if ok else 1)

    # modo default = unit (testes unitários de componentes isolados)
    ok = run_unit(selection=(args.arg or None))
    sys.exit(0 if ok else 1)