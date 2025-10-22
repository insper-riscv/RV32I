import os, sys, json, argparse, subprocess, shlex, glob
from pathlib import Path
from cocotb.runner import get_runner, VHDL
from xml.etree import ElementTree as ET

def _sh(cmd, cwd=None):
    r = subprocess.run(shlex.split(cmd), cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"cmd failed: {cmd}\nstdout:\n{r.stdout}\nstderr:\n{r.stderr}")
    return r.stdout

def _junit_fail_error_counts(xml_path: Path) -> tuple[int, int]:
    if not xml_path.exists():
        return 0, 1  # considere erro se não gerou xml
    root = ET.parse(xml_path).getroot()
    def gi(n, k): return int(n.attrib.get(k, "0"))
    failures = errors = 0
    if root.tag == "testsuite":
        failures += gi(root, "failures")
        errors   += gi(root, "errors")
    elif root.tag == "testsuites":
        for ts in root.findall("testsuite"):
            failures += gi(ts, "failures")
            errors   += gi(ts, "errors")
    else:
        # fallback: conta <testcase> com <failure>/<error>
        for tc in root.findall(".//testcase"):
            if tc.find("failure") is not None: failures += 1
            if tc.find("error")   is not None: errors   += 1
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

    runner.build(
        vhdl_sources=vhdl_sources,
        hdl_toplevel=toplevel,
        always=True,
        build_dir=build_dir,
        build_args=[VHDL("--std=08")],
        parameters=parameters or {},
    )

    wave_file = build_dir / "waves.ghw"
    plusargs = [f"--wave={wave_file}"]

    runner.test(
        hdl_toplevel=toplevel,
        hdl_toplevel_lang="vhdl",
        test_module=test_module,
        build_dir=build_dir,
        plusargs=plusargs,
        test_args=["--std=08"],
        extra_env=extra_env or {},
    )

    results = build_dir / "results.xml"
    failures, errors = _junit_fail_error_counts(results)

    print(f"Waves: {wave_file} (gerado)")
    return failures, errors, build_dir

# -------------------- build de 1 teste --------------------
def build_archtest_one(repo_root, test_name, arch_env_dir, arch_isa_dir, arch_glue_dir, arch_out_dir, riscv_prefix):
    arch_out_dir.mkdir(parents=True, exist_ok=True)
    elf  = arch_out_dir / f"{test_name}.elf"
    binp = arch_out_dir / f"{test_name}.bin"
    hexp = arch_out_dir / f"{test_name}.hex"
    sym  = arch_out_dir / f"{test_name}.sym"
    meta = arch_out_dir / f"{test_name}.meta.json"

    test_src = arch_isa_dir / f"{test_name}.S"
    if not test_src.exists():
        raise FileNotFoundError(f"Teste ISA não encontrado: {test_src}")

    gcc    = f"{riscv_prefix}gcc"
    objcpy = f"{riscv_prefix}objcopy"
    nm     = f"{riscv_prefix}nm"

    cmd_gcc = (
        f'{gcc} -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles '
        f'-DXLEN=32 -D__riscv_xlen=32 '
        f'-T {arch_glue_dir / "link.ld"} '
        f'-I {arch_env_dir} -I {arch_glue_dir} '
        f'{arch_glue_dir / "start.S"} {test_src} -o {elf}'
    )
    _sh(cmd_gcc, cwd=repo_root)

    r = subprocess.run([nm, str(elf)], cwd=repo_root, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"nm failed:\nstdout:\n{r.stdout}\nstderr:\n{r.stderr}")
    Path(sym).write_text(r.stdout)
    syms_txt = Path(sym).read_text()

    def find_addr(label):
        for line in syms_txt.splitlines():
            parts = line.split()
            if len(parts) >= 3 and parts[-1] == label:
                return int(parts[0], 16)
        raise RuntimeError(f"símbolo não encontrado: {label} em {sym}")

    begin_sig = find_addr("begin_signature")
    end_sig   = find_addr("end_signature")
    rv_end    = None
    tohost    = None
    try: rv_end = find_addr("RVTEST_CODE_END")
    except: pass
    try: tohost = find_addr("tohost")
    except: pass

    _sh(f"{objcpy} -O binary -j .text -j .data {elf} {binp}")
    bs = Path(binp).read_bytes()
    pad = (-len(bs)) % 4
    if pad:
        bs += b"\x00" * pad

    with open(hexp, "w") as f:
        for i in range(0, len(bs), 4):
            w = int.from_bytes(bs[i:i+4], "little")
            f.write(f"{w:08x}\n")

    meta_obj = {
        "test": test_name,
        "elf": str(elf),
        "hex": str(hexp),
        "symbols": {
            "begin_signature": begin_sig,
            "end_signature": end_sig,
            "rvtest_code_end": rv_end,
            "tohost": tohost,
        }
    }
    Path(meta).write_text(json.dumps(meta_obj, indent=2))
    return meta_obj

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
    repo_root    = Path(__file__).resolve().parents[3]
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
        "src/ROM_cocotb.vhd",
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
        print(f"\n============ COMPLIANCE: {t} ============")
        meta = build_archtest_one(
            repo_root,
            t,
            arch_env_dir,
            arch_isa_dir,
            arch_glue_dir,
            arch_out_dir,
            riscv_prefix
        )
        hex_path = meta["hex"]
        extra_env = {"ARCHTEST_META": json.dumps(meta)}
        try:
            failures, errors, _ = run_cocotb_test(
                toplevel=TOPLEVEL,
                sources=SOURCES,
                test_module=test_module,
                parameters={"ROM_FILE": str(hex_path)},
                extra_env=extra_env,
                build_suffix=f"arch_{t}",
            )
            if failures or errors:
                failed += 1
            else:
                passed += 1
        except Exception as e:
            print(f"[FAIL {t}] {e}")
            failed += 1

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

    parser = argparse.ArgumentParser(description="Runner de Testes Cocotb para o projeto RV32I")
    parser.add_argument("test_name", nargs="?", default="all",
                        help=f"Nome do teste/grupo. Opções: {list(TEST_CONFIGS.keys()) + ['all','compliance']}")
    parser.add_argument("arch_one_pos", nargs="?", help="(apenas para 'compliance') um teste do suite, ex.: add")

    args = parser.parse_args()
    arch_one = args.arch_one_pos or os.getenv("ARCH_ONE")

    if args.test_name == "all":
        print("Executando TODOS os testes definidos em tests.json...")
        for name, config in TEST_CONFIGS.items():
            print(f"\n{'='*20} INICIANDO TESTE: {name.upper()} {'='*20}")
            try:
                run_cocotb_test(**config)
                print(f"{'-'*20} TESTE {name.upper()} FINALIZADO COM SUCESSO {'-'*20}")
            except Exception as e:
                print(f"[ERRO] O teste '{name}' falhou: {e}")
        print("\n=== Iniciando COMPLIANCE (rv32i_m) ===")
        run_archtest_suite(one=arch_one)
        print("\nTodos os testes foram executados.")

    elif args.test_name == "compliance":
        run_archtest_suite(one=arch_one)

    elif args.test_name in TEST_CONFIGS:
        print(f"Executando teste específico: {args.test_name}")
        run_cocotb_test(**TEST_CONFIGS[args.test_name])
        print(f"\nTeste {args.test_name} finalizado.")

    else:
        print(f"Erro: Teste '{args.test_name}' não encontrado em tests.json.")
        print(f"Opções disponíveis: {list(TEST_CONFIGS.keys()) + ['all','compliance']}")
        sys.exit(1)