import json, subprocess, shlex
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
TESTS_DIR = ROOT / "tests"
RUNNER = TESTS_DIR / "python" / "cocotb" / "utils" / "runner.py"
BASE_JSON = TESTS_DIR / "tests.json"
TESTLIST = TESTS_DIR / "testlists" / "rv32i.txt"

def sh(cmd, cwd=None, env=None):
    p = subprocess.run(cmd if isinstance(cmd, list) else shlex.split(cmd),
                       cwd=cwd, env=env)
    if p.returncode != 0:
        raise SystemExit(p.returncode)

def nm_bounds(elf):
    out = subprocess.check_output(["riscv32-unknown-elf-nm", "-n", str(elf)], text=True)
    b=e=None
    for line in out.splitlines():
        if "begin_signature" in line: b=int(line.split()[0],16)
        if "end_signature"   in line: e=int(line.split()[0],16)
    return b,e

def build_hex(srel: str) -> tuple[Path, Path]:
    s_abs = (TESTS_DIR / srel).resolve()
    elf = s_abs.with_suffix(".elf")
    hexp = s_abs.with_suffix(".hex")
    sh(f"make {elf.name}", cwd=TESTS_DIR)
    sh(f"make {hexp.name}", cwd=TESTS_DIR)
    return elf, hexp

def load_testlist():
    for line in TESTLIST.read_text().splitlines():
        p=line.strip()
        if p and not p.startswith("#"):
            yield p

def main():
    base_cfg = json.loads(BASE_JSON.read_text())

    for srel in load_testlist():
        elf, hexp = build_hex(srel)
        b,e = nm_bounds(elf)

        # sobrescreve ROM_FILE
        cfg = json.loads(json.dumps(base_cfg))  # cópia profunda simples
        cfg["compliance_rv32i"]["parameters"]["ROM_FILE"] = str(hexp.resolve())
        BASE_JSON.write_text(json.dumps(cfg, indent=2))

        # passa bounds e caminho do ELF p/ o teste
        env = dict(**os.environ)
        env["BEGIN_SIG"] = hex(b)
        env["END_SIG"]   = hex(e)
        env["ELF_PATH"]  = str(elf.resolve())

        print(f"\n=== {srel} ===")
        sh(f"python {RUNNER} compliance_rv32i", cwd=ROOT, env=env)

    # restaura o arquivo original se quiser
    BASE_JSON.write_text(json.dumps(base_cfg, indent=2))

if __name__ == "__main__":
    import os
    main()