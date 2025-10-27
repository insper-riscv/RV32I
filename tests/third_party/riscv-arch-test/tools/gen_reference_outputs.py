#!/usr/bin/env python3
import os
import argparse
import subprocess
import shlex
import json
from pathlib import Path

def sh(cmd: str, cwd: Path | None = None) -> str:
    r = subprocess.run(shlex.split(cmd), cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"cmd failed: {cmd}\nstdout:\n{r.stdout}\nstderr:\n{r.stderr}")
    return r.stdout

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--isa", default=os.getenv("ARCHTEST_ISA", "rv32i"))
    ap.add_argument("--build-dir", default=os.getenv("ARCHTEST_ELF_DIR", "build/archtest"))
    ap.add_argument("--ref-dir", default=os.getenv("ARCHTEST_REF_DIR", "tests/third_party/riscv-arch-test/tools/reference_outputs"))
    ap.add_argument("--spike-mem-rom", default=os.getenv("ARCHTEST_SPIKE_MEM_ROM", "-m0:0x20000"))
    ap.add_argument("--spike-mem-ram", default=os.getenv("ARCHTEST_SPIKE_MEM_RAM", "-m0x20000000:0x10000"))
    args = ap.parse_args()

    build = Path(args.build_dir)
    ref = Path(args.ref_dir).resolve()
    logs = ref / "spike-logs"
    ref.mkdir(parents=True, exist_ok=True)
    logs.mkdir(parents=True, exist_ok=True)

    metas = sorted(build.glob("*.meta.json"))
    if not metas:
        raise SystemExit("Nada em build/archtest. Rode 'make arch-elves' antes.")

    for meta_path in metas:
        meta = json.loads(meta_path.read_text())
        test = meta["test"]
        elf = Path(meta["elf"]).resolve()
        sig_file = ref / f"{test}.sig"

        cmd = f"spike --isa={args.isa} {args.spike_mem_rom if hasattr(args,'spike_mem_rom') else args.spike_mem_rom} {args.spike_mem_ram} +signature={sig_file} +signature-granularity=4 {elf}"
        try:
            out = sh(cmd)
        except RuntimeError as ex:
            (logs / f"{test}.log").write_text(str(ex))
            raise
        (logs / f"{test}.log").write_text(out)
        print(f"[ok] {test} → {sig_file}")

if __name__ == "__main__":
    main()