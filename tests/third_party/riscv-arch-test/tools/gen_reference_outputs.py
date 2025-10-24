#!/usr/bin/env python3
import os, argparse, json
from pathlib import Path
import subprocess, shlex

def _sh(cmd, cwd=None):
    r = subprocess.run(shlex.split(cmd), cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"cmd failed: {cmd}\nstdout:\n{r.stdout}\nstderr:\n{r.stderr}")
    return r.stdout

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--isa", default=os.getenv("ARCHTEST_ISA","rv32i"))
    ap.add_argument("--build-dir", default=os.getenv("ARCHTEST_ELF_DIR","build/archtest"))
    ap.add_argument("--ref-dir", default=os.getenv("ARCHTEST_REF_DIR","tests/third_party/riscv-arch-test/tools/reference_outputs"))
    ap.add_argument("--spike-mem", default=os.getenv("ARCHTEST_SPIKE_MEM","-m0:0x800000"))
    args = ap.parse_args()

    build = Path(args.build_dir)
    ref   = Path(args.ref_dir).resolve()
    logs  = ref / "spike-logs"
    ref.mkdir(parents=True, exist_ok=True)
    logs.mkdir(parents=True, exist_ok=True)

    metas = sorted(build.glob("*.meta.json"))
    if not metas:
        raise SystemExit(f"Nada em {build}. Rode 'make compliance' para compilar os .elf antes.")

    for meta_path in metas:
        meta = json.loads(meta_path.read_text())
        elf = meta["elf"]
        test = meta["test"]
        syms = meta.get("symbols", {})

        try:
            b = int(syms["begin_signature"], 0)
            e = int(syms["end_signature"],   0)
        except Exception:
            raise SystemExit(f"{test}: símbolos de assinatura ausentes no meta {meta_path.name}")

        sig_file = ref / f"{test}.sig"
        spike    = f"spike --isa={args.isa} {args.spike-mem} +sigstart=0x{b:x} +sigend=0x{e:x} +signature={sig_file} +signature-granularity=4 {elf}"
        out = _sh(spike)
        (logs / f"{test}.log").write_text(out)
        print(f"[ok] {test} → {sig_file}")

if __name__ == "__main__":
    main()
