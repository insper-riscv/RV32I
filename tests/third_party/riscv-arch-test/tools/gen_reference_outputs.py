#!/usr/bin/env python3
import argparse, os, sys, subprocess, json
from pathlib import Path

def merge_mem_tokens(mem, rom, ram):
    if mem:
        mem = mem.strip()
        if not mem.startswith("-m"):
            mem = "-m" + mem
        return mem

    rom = (rom or os.getenv("ARCHTEST_SPIKE_MEM_ROM") or "-m0x80000000:0x20000").strip()
    ram = (ram or os.getenv("ARCHTEST_SPIKE_MEM_RAM") or "-m0x20000000:0x10000").strip()

    rom_body = rom[2:] if rom.startswith("-m") else rom
    ram_body = ram[2:] if ram.startswith("-m") else ram
    return f"-m{rom_body},{ram_body}"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--isa", default=os.getenv("ARCHTEST_ISA","rv32i"))
    ap.add_argument("--build-dir", default="build/archtest")
    ap.add_argument("--ref-dir", default="tests/third_party/riscv-arch-test/tools/reference_outputs")
    ap.add_argument("--spike-mem", default=os.getenv("ARCHTEST_SPIKE_MEM"))
    ap.add_argument("--spike-mem-rom", default=os.getenv("ARCHTEST_SPIKE_MEM_ROM"))
    ap.add_argument("--spike-mem-ram", default=os.getenv("ARCHTEST_SPIKE_MEM_RAM"))
    args = ap.parse_args()

    build_dir = Path(args.build_dir)
    ref_dir   = Path(args.ref_dir)
    logs_dir  = ref_dir / "spike-logs"

    ref_dir.mkdir(parents=True, exist_ok=True)
    logs_dir.mkdir(parents=True, exist_ok=True)

    mem_token = merge_mem_tokens(args.spike_mem, args.spike_mem_rom, args.spike_mem_ram)

    metas = sorted(build_dir.glob("*.meta.json"))
    if not metas:
        print(f"[ERRO] Não achei metas em {build_dir}. Rode `make arch-elves` antes.", file=sys.stderr)
        sys.exit(1)

    print(f"[gen-refs] ISA={args.isa}")
    print(f"[gen-refs] MEM={mem_token}")
    print(f"[gen-refs] ELFs/metas em {build_dir}: {len(metas)} itens")
    print(f"[gen-refs] Saídas: {ref_dir}")

    for meta_path in metas:
        meta = json.loads(meta_path.read_text())

        testname   = meta["test"]
        elf_spike  = meta["elf_spike"]  # agora é garantido que é o ELF Spike certo
        sig_path   = ref_dir / f"{testname}.sig"
        log_path   = logs_dir / f"{testname}.log"

        print(f"[gen-refs] {testname}")

        cmd = [
            "spike",
            f"--isa={args.isa}",
            mem_token,
            f"+signature={sig_path}",
            "+signature-granularity=4",
            elf_spike
        ]

        r = subprocess.run(cmd, text=True, capture_output=True)

        log_path.write_text(
            "CMD: " + " ".join(cmd) + "\n\n"
            "returncode=" + str(r.returncode) + "\n\n"
            "STDOUT:\n" + r.stdout + "\n"
            "STDERR:\n" + r.stderr + "\n"
        )

        if r.returncode != 0:
            print(f"  -> FAIL (veja {log_path})")
            print(f"[ERRO] Spike falhou para {testname}", file=sys.stderr)
            sys.exit(2)

        if not sig_path.exists():
            print(f"  -> FAIL: assinatura não gerada ({sig_path})")
            print(f"[ERRO] Sem assinatura para {testname}", file=sys.stderr)
            sys.exit(3)

        print("  -> OK")

    print("[gen-refs] Concluído com sucesso.")

if __name__ == "__main__":
    main()