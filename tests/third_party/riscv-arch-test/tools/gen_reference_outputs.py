#!/usr/bin/env python3
import os, argparse, json, subprocess, shlex
from pathlib import Path

def sh(cmd, cwd=None):
    r = subprocess.run(shlex.split(cmd), cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"cmd failed: {cmd}\nstdout:\n{r.stdout}\nstderr:\n{r.stderr}")
    return r.stdout

def find_sym_addr_with_nm(elf_path: Path, name: str) -> int:
    out = sh(f"riscv-none-elf-nm {elf_path}")
    for line in out.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[-1] == name:
            return int(parts[0], 16)
    raise KeyError(f"símbolo não encontrado via nm: {name}")

def get_sig_bounds(meta: dict) -> tuple[int,int]:
    syms = meta.get("symbols", {}) or {}
    b = syms.get("begin_signature")
    e = syms.get("end_signature")
    if b is not None and e is not None:
        b = int(b) if isinstance(b, int) else int(str(b), 0)
        e = int(e) if isinstance(e, int) else int(str(e), 0)
        return b, e
    # fallback: extrai do ELF com nm
    elf = Path(meta["elf"])
    b = find_sym_addr_with_nm(elf, "begin_signature")
    e = find_sym_addr_with_nm(elf, "end_signature")
    return b, e

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--isa", default=os.getenv("ARCHTEST_ISA","rv32i"))
    ap.add_argument("--build-dir", default=os.getenv("ARCHTEST_ELF_DIR","build/archtest"))
    ap.add_argument("--ref-dir", default=os.getenv("ARCHTEST_REF_DIR","tests/third_party/riscv-arch-test/tools/reference_outputs"))
    ap.add_argument("--spike-mem-rom", default=os.getenv("ARCHTEST_SPIKE_MEM_ROM","-m0:131072"))
    ap.add_argument("--spike-mem-ram", default=os.getenv("ARCHTEST_SPIKE_MEM_RAM","-m0x20000000:65536"))
    args = ap.parse_args()

    build = Path(args.build_dir)
    ref   = Path(args.ref_dir).resolve()
    logs  = ref / "spike-logs"
    ref.mkdir(parents=True, exist_ok=True)
    logs.mkdir(parents=True, exist_ok=True)

    metas = sorted(build.glob("*.meta.json"))
    if not metas:
        raise SystemExit(f"Nada em {build}. Rode 'make compliance' (ou compliance-one) antes.")

    for meta_path in metas:
        meta = json.loads(meta_path.read_text())
        elf = Path(meta["elf"])
        test = meta["test"]

        try:
            b,e = get_sig_bounds(meta)
        except Exception as ex:
            raise SystemExit(f"{test}: não consegui obter begin/end_signature ({ex}) do meta {meta_path.name} ou do ELF {elf}")

        sig_file = ref / f"{test}.sig"
        cmd = (
            f"spike --isa={args.isa} "
            f"{args.spike_mem_rom} {args.spike_mem_ram} "
            f"+signature={sig_file} +signature-granularity=4 "
            f"{elf}"
        )
        out = sh(cmd)
        (logs / f"{test}.log").write_text(out)
        print(f"[ok] {test} → {sig_file}")

if __name__ == "__main__":
    main()