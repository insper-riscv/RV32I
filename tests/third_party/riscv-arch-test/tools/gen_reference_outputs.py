#!/usr/bin/env python3
import argparse, os, sys, subprocess, json
from pathlib import Path

def sh(cmd, cwd=None):
    r = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True)
    if r.returncode != 0:
        raise RuntimeError(f"cmd failed: {' '.join(cmd)}\nstdout:\n{r.stdout}\nstderr:\n{r.stderr}")
    return r.stdout

def merge_mem_tokens(mem, rom, ram):
    """
    Retorna UM único token -m<...> para o Spike.
    Prioridade:
      1) --spike-mem (já combinado)
      2) combinar --spike-mem-rom e --spike-mem-ram
      3) defaults seguros
    """
    if mem:
        mem = mem.strip()
        if not mem.startswith("-m"):
            mem = "-m" + mem
        return mem

    # defaults (ROM 0x8000_0000:0x20000; RAM 0x2000_0000:0x10000)
    rom = (rom or os.getenv("ARCHTEST_SPIKE_MEM_ROM") or "-m0x80000000:0x20000").strip()
    ram = (ram or os.getenv("ARCHTEST_SPIKE_MEM_RAM") or "-m0x20000000:0x10000").strip()

    # tira prefixo -m para poder concatenar
    rom_body = rom[2:] if rom.startswith("-m") else rom
    ram_body = ram[2:] if ram.startswith("-m") else ram
    return f"-m{rom_body},{ram_body}"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--isa", default=os.getenv("ARCHTEST_ISA","rv32i"))
    ap.add_argument("--build-dir", default="build/archtest")
    ap.add_argument("--ref-dir", default="tests/third_party/riscv-arch-test/tools/reference_outputs")
    # Opções de memória (use só UMA ou deixe que a gente combine):
    ap.add_argument("--spike-mem", default=os.getenv("ARCHTEST_SPIKE_MEM"))  # exemplo: -m2147483648:1048576,536870912:65536
    ap.add_argument("--spike-mem-rom", default=os.getenv("ARCHTEST_SPIKE_MEM_ROM"))  # exemplo: -m0x80000000:0x20000
    ap.add_argument("--spike-mem-ram", default=os.getenv("ARCHTEST_SPIKE_MEM_RAM"))  # exemplo: -m0x20000000:0x10000
    args = ap.parse_args()

    build = Path(args.build_dir)
    ref   = Path(args.ref_dir)
    logs  = ref / "spike-logs"
    ref.mkdir(parents=True, exist_ok=True)
    logs.mkdir(parents=True, exist_ok=True)

    mem_token = merge_mem_tokens(args.spike_mem, args.spike_mem_rom, args.spike_mem_ram)

    elfs = sorted(build.glob("*.elf"))
    if not elfs:
        print(f"[ERRO] Não achei ELFs em {build}. Rode `make arch-elves` antes.", file=sys.stderr)
        sys.exit(1)

    print(f"[gen-refs] ISA={args.isa}")
    print(f"[gen-refs] MEM={mem_token}")
    print(f"[gen-refs] ELFs em {build}: {len(elfs)} itens")
    print(f"[gen-refs] Saídas: {ref}")

    for elf in elfs:
        testname = elf.stem  # ex: add-01
        sig_path = ref / f"{testname}.sig"
        log_path = logs / f"{testname}.log"

        cmd = ["spike", f"--isa={args.isa}", mem_token,
               f"+signature={sig_path}", "+signature-granularity=4", str(elf)]
        print(f"[gen-refs] {testname}")
        try:
            r = subprocess.run(cmd, text=True, capture_output=True)
            with open(log_path, "w") as f:
                f.write("CMD: " + " ".join(cmd) + "\n\n")
                f.write("STDOUT:\n" + r.stdout + "\n")
                f.write("STDERR:\n" + r.stderr + "\n")
            if r.returncode != 0:
                print(f"  -> FAIL (veja {log_path})")
                raise RuntimeError(f"Spike falhou para {testname}")
            if not sig_path.exists():
                print(f"  -> FAIL: assinatura não gerada ({sig_path})")
                raise RuntimeError(f"Sem assinatura para {testname}")
            print("  -> OK")
        except Exception as e:
            print(f"[ERRO] {e}", file=sys.stderr)
            sys.exit(2)

    print("[gen-refs] Concluído com sucesso.")

if __name__ == "__main__":
    main()