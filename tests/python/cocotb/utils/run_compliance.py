import os, subprocess, shlex
from pathlib import Path

# Caminhos base
UTILS_DIR = Path(__file__).resolve().parent
COCOTB_DIR = UTILS_DIR.parent
PYTHON_DIR = COCOTB_DIR.parent
TESTS_DIR = PYTHON_DIR.parent
ROOT = TESTS_DIR.parent
MAKEFILE = ROOT / "tests" / "python" / "cocotb" / "instructions" / "Makefile"
RUNNER = ROOT / "tests" / "python" / "utils" / "runner.py"
TESTLIST = TESTS_DIR / "testlists" / "rv32i.txt"

def sh(cmd, cwd=None, env=None):
    print(f"$ {cmd}")
    p = subprocess.run(shlex.split(cmd), cwd=cwd, env=env)
    if p.returncode != 0:
        raise SystemExit(p.returncode)

def nm_bounds(elf):
    out = subprocess.check_output(["riscv32-unknown-elf-nm", "-n", str(elf)], text=True)
    b = e = None
    for line in out.splitlines():
        if "begin_signature" in line:
            b = int(line.split()[0], 16)
        if "end_signature" in line:
            e = int(line.split()[0], 16)
    return b, e

def build_hex(srel: str):
    s_abs = (TESTS_DIR / srel).resolve()
    elf = s_abs.with_suffix(".elf")
    hexp = s_abs.with_suffix(".hex")
    elf_rel = elf.relative_to(ROOT)
    hex_rel = hexp.relative_to(ROOT)
    sh(f"make -f {MAKEFILE} {elf_rel}", cwd=ROOT)
    sh(f"make -f {MAKEFILE} {hex_rel}", cwd=ROOT)
    return elf, hexp

def load_testlist():
    for line in TESTLIST.read_text().splitlines():
        p = line.strip()
        if p and not p.startswith("#"):
            yield p

def main():
    for srel in load_testlist():
        elf, hexp = build_hex(srel)
        b, e = nm_bounds(elf)

        env = dict(os.environ)
        env["ROM_FILE"] = str(hexp.resolve())
        env["BEGIN_SIG"] = hex(b or 0)
        env["END_SIG"] = hex(e or 0)
        env["ELF_PATH"] = str(elf.resolve())

        sh(f"python {RUNNER} compliance_rv32i", cwd=ROOT, env=env)

if __name__ == "__main__":
    main()