import os, sys, json, argparse, subprocess, shlex, glob, shutil
from pathlib import Path
from cocotb.runner import get_runner, VHDL
from xml.etree import ElementTree as ET

PLUSARGS_ENV = os.getenv("COCOTB_PLUSARGS", "")
plusargs = [a for a in PLUSARGS_ENV.split() if a.strip()]
REPO = Path(__file__).resolve().parents[2]
os.environ.setdefault("PYTHONPATH", str(REPO))
os.environ.setdefault("ARCHTEST_REF_DIR", "tests/third_party/riscv-arch-test/tools/reference_outputs")
os.environ.setdefault("ARCHTEST_MAX_CYCLES", "200000")
os.environ.setdefault("PYTHONUNBUFFERED", "1")

def _sh(cmd, cwd=None, env=None):
    r = subprocess.run(shlex.split(cmd), cwd=cwd, env=env, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"cmd failed: {cmd}\nstdout:\n{r.stdout}\nstderr:\n{r.stderr}")
    return r.stdout

def _try_generate_ref_with_spike(build_dir: str):
    """
    Opcional: alguns fluxos tentam gerar .sig 'on the fly' p/ o primeiro teste.
    Mantemos isso robusto, sem variável 'out' em escopos errados.
    """
    env = os.environ.copy()
    env.setdefault("ARCHTEST_REF_POLICY", "regen")
    cmd = f"python3 tests/third_party/riscv-arch-test/tools/gen_reference_outputs.py --build-dir {build_dir}"
    try:
        _sh(cmd, env=env)
    except Exception as e:
        print(f"[WARN] Não foi possível gerar referência via Spike agora: {e}")

def _ensure_reference_signature(meta: dict):
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

    rom = os.getenv("ARCHTEST_SPIKE_MEM_ROM", "-m2147483648:131072")
    ram = os.getenv("ARCHTEST_SPIKE_MEM_RAM", "-m0x20000000:0x10000")

    cmd = f"spike --isa={isa} {rom} {ram} +signature={ref_sig} +signature-granularity=4 {elf}"
    r = subprocess.run(shlex.split(cmd), capture_output=True, text=True)
    logf.write_text(r.stdout + "\n" + r.stderr)
    if r.returncode != 0:
        raise RuntimeError(f"Falha no Spike ao gerar referência para {test_name}.\ncmd: {cmd}\nstdout:\n{r.stdout}\nstderr:\n{r.stderr}")

def _junit_fail_error_counts(xml_path: Path) -> tuple[int, int]:
    if not xml_path.exists():
        # Se não gerou XML, considere 1 erro (para marcar FAIL no agregador)
        return 0, 1

    root = ET.parse(xml_path).getroot()

    failures = 0
    errors = 0

    # Conta em todos os <testcase>
    for tc in root.findall(".//testcase"):
        if tc.find("failure") is not None:
            failures += 1
        if tc.find("error") is not None:
            errors += 1

    # Ainda tenta pegar atributos agregados, caso existam:
    def gi(n, k): 
        try:
            return int(n.attrib.get(k, "0"))
        except Exception:
            return 0

    # Soma (sem duplicar) — se os attrs faltarem, isso adiciona 0.
    if root.tag == "testsuite":
        failures += gi(root, "failures")
        errors   += gi(root, "errors")
    elif root.tag == "testsuites":
        for ts in root.findall("testsuite"):
            failures += gi(ts, "failures")
            errors   += gi(ts, "errors")

    return failures, errors

def run_cocotb_test(
    toplevel: str,
    sources: list,
    test_module: str,
    parameters: dict = None,
    extra_env: dict = None,
    build_suffix: str | None = None,
):
    tests_root = Path(__file__).resolve().parents[1]
    repo_root  = Path(__file__).resolve().parents[2] 
    sys.path.append(str(repo_root))

    sim = os.getenv("SIM", "ghdl")
    vhdl_sources = [
        (Path(src) if Path(src).is_absolute() else (repo_root / src))
        for src in sources
    ]

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
        build_dir = tests_root / "python/sim_build" / group / test_name
    else:
        build_dir = tests_root / "python/sim_build" / group / toplevel
    build_dir.mkdir(parents=True, exist_ok=True)

    if parameters:
        abs_params = {}
        for k, v in parameters.items():
            if isinstance(v, bool):
                abs_params[k] = "true" if v else "false"
            else:
                # tenta resolver como caminho absoluto relativo ao ambiente atual
                vpath = Path(v)
                if vpath.exists():
                    abs_params[k] = str(vpath.resolve())
                else:
                    # se não existe no cwd atual, tente relative ao repo_root
                    candidate = repo_root / v
                    if candidate.exists():
                        abs_params[k] = str(candidate.resolve())
                    else:
                        # fallback: mantenha o original (para flags não-caminho)
                        abs_params[k] = str(v)
        parameters = abs_params

    if build_dir.exists():
        shutil.rmtree(build_dir)
    build_dir.mkdir(parents=True, exist_ok=True)

    runner.build(
        vhdl_sources=vhdl_sources,
        hdl_toplevel=toplevel,
        always=True,
        build_dir=build_dir,
        build_args=[VHDL("--std=08"), VHDL("--work=top")],
        parameters=parameters or {},
    )

    # --- SANITIZAÇÃO DE AMBIENTE / WAVES ---
    _base_env = {} if extra_env is None else dict(extra_env)

    # Remova gatilhos de VCD/waves do shell e do env do filho
    _block = [
        "WAVES", "GHDL_DUMP_VCD", "GHDL_DUMP_FST", "GHDL_DUMP_GHW",
        "COCOTB_VCD_FILE", "COCOTB_WAVEFORM", "COCOTB_WAVES",
        "GHDL_TRACE_FORMAT", "TRACEFILE", "TRACE_FILE",
    ]
    for k in _block:
        os.environ.pop(k, None)
        _base_env.pop(k, None)

    # Por padrão, rode sem waveform (estável)
    _base_env["WAVES"] = "0"
    _base_env["PYTHONPATH"] = os.environ.get("PYTHONPATH", str(repo_root)) 

    runner.test(
        hdl_toplevel=toplevel,
        hdl_toplevel_lang="vhdl",
        test_module=test_module,
        build_dir=build_dir,
        plusargs=plusargs,
        test_args=["--std=08","--work=top"],
        extra_env=_base_env,
    )

    results = build_dir / "results.xml"
    failures, errors = _junit_fail_error_counts(results)

    wave = build_dir / "waves.fst"
    if wave.exists():
        print(f"Waves: {wave} (gerado)")

    ok = (failures == 0 and errors == 0)
    return ok, failures, errors, build_dir

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
                syms[name] = addr
    return syms

# -------------------- build de 1 teste --------------------
def build_archtest_one(repo_root: Path, test_name: str, env_dir: Path, isa_dir: Path, glue_dir: Path, out_dir: Path, riscv_prefix: str) -> dict:
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

    ldscript = Path("tests/third_party/riscv-arch-test/tools/spike/low.ld").resolve()
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
        # >>> DEFINES CRÍTICAS PARA OS ARCH-TESTS:
        "-D__riscv_xlen=32",
        "-DXLEN=32",
        "-DRVTEST_RV32I"
    ]
    ldflags = [f"-T{ldscript}", "-nostdlib", "-nostartfiles"]

    # Compila (arquivo .S já passa pelo pré-processador via gcc)
    subprocess.run([cc, *cflags, "-c", str(asm), "-o", str(build_o)], check=True)
    # Linka com low.ld
    subprocess.run([cc, *ldflags, str(build_o), "-o", str(elf)], check=True)
    # HEX para ROM
    subprocess.run([objcopy, "-O", "verilog", str(elf), str(hexfile)], check=True)

    syms = _read_symbols_with_nm(elf, riscv_prefix)
    meta = {"test": test_name, "elf": str(elf), "hex": str(hexfile), "symbols": syms}
    meta_json.write_text(json.dumps(meta, indent=2))
    return meta

# ----------------- rodar a suíte (ou um) -----------------
def _normalize_one_name(arch_isa_dir: Path, one: str) -> str:
    """
    Aceita 'add' e resolve para o stem real do arquivo em src/, por ex. 'add-01'.
    Se já vier 'add-01', mantém.
    """
    cand = arch_isa_dir / f"{one}.S"
    if cand.exists():
        return one
    # procura qualquer arquivo que comece com 'one-*.S'
    m = list(arch_isa_dir.glob(f"{one}-*.S"))
    if not m:
        raise FileNotFoundError(f"Não achei {one}.S nem {one}-*.S em {arch_isa_dir}")
    return m[0].stem  # ex.: 'add-01'

def run_archtest_suite(one=None):
    repo_root    = Path(__file__).resolve().parents[2]
    arch_env_dir = (repo_root / "tests/third_party/riscv-arch-test/riscv-test-suite/env").resolve()
    arch_isa_dir = (repo_root / "tests/third_party/riscv-arch-test/riscv-test-suite/rv32i_m/I/src").resolve()
    arch_glue_dir = (repo_root / "tests/third_party/archtest-utils").resolve()
    arch_out_dir  = (repo_root / "build/archtest").resolve()
    riscv_prefix  = os.getenv("RISCV_PREFIX", "riscv-none-elf-")

    # --- seu DUT ---
    TOPLEVEL = "rv32i"
    SOURCES  = [
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

    if one:
        tests = [_normalize_one_name(arch_isa_dir, one)]
    else:
        tests = [Path(p).stem for p in glob.glob(str(arch_isa_dir / "*.S"))]
        tests.sort()

    test_module = "tests.python.unittests.archtest.test_archtest"

    passed = failed = 0
    for t in tests:
        print(f"\n=================== COMPLIANCE: {t} ===================")
        meta = build_archtest_one(
            repo_root,
            t,
            arch_env_dir,
            arch_isa_dir,
            arch_glue_dir,
            arch_out_dir,
            riscv_prefix
        )

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
                test_module=test_module,
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

    print(f"\nCompliance RV32I_m: PASS={passed} FAIL={failed} TOTAL={passed+failed}")

# ------------------------------ main ------------------------------
if __name__ == "__main__":
    tests_root = Path(__file__).resolve().parents[1]
    json_path  = tests_root / "python/tests.json"

    try:
        with open(json_path, "r") as f:
            TEST_CONFIGS = json.load(f)
    except FileNotFoundError:
        print(f"Erro: Arquivo de configuração '{json_path}' não encontrado.")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Erro: O arquivo JSON '{json_path}' está mal formatado.")
        sys.exit(1)

    parser = argparse.ArgumentParser()
    parser.add_argument("test_name", nargs="?", default="all")
    parser.add_argument("one_name", nargs="?", default="")
    args = parser.parse_args()

    if args.test_name == "assemble":
        # Monta todos os ELFs/HEX/META sem rodar simulação
        repo_root    = Path(__file__).resolve().parents[2]
        arch_env_dir = (repo_root / "tests/third_party/riscv-arch-test/riscv-test-suite/env").resolve()
        arch_isa_dir = (repo_root / "tests/third_party/riscv-arch-test/riscv-test-suite/rv32i_m/I/src").resolve()
        arch_glue_dir = (repo_root / "tests/third_party/archtest-utils").resolve()
        arch_out_dir  = (repo_root / "build/archtest").resolve()
        riscv_prefix  = os.getenv("RISCV_PREFIX", "riscv-none-elf-")

        if args.one_name:
            tests = [ _normalize_one_name(arch_isa_dir, args.one_name) ]
        else:
            import glob
            tests = [Path(p).stem for p in glob.glob(str(arch_isa_dir / "*.S"))]
            tests.sort()

        for t in tests:
            print(f"[assemble] {t}")
            build_archtest_one(
                repo_root,
                t,
                arch_env_dir,
                arch_isa_dir,
                arch_glue_dir,
                arch_out_dir,
                riscv_prefix
            )
        print("Montagem concluída. ELFs/HEX/META em build/archtest.")
        sys.exit(0)