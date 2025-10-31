#!/usr/bin/env python3
import argparse,os,sys,subprocess,json
from pathlib import Path
def run(cmd):
    return subprocess.run(cmd,text=True,capture_output=True)
def elf_has_sig_symbols(elf):
    r=run(["riscv32-unknown-elf-objdump","-t",elf])
    if r.returncode!=0:
        return (False,0,0,r.stderr or r.stdout)
    begin=end=None
    for line in r.stdout.splitlines():
        if " begin_signature" in line:
            try: begin=int(line.strip().split()[0],16)
            except: pass
        if " end_signature" in line:
            try: end=int(line.strip().split()[0],16)
            except: pass
    ok=(begin is not None) and (end is not None) and (end>begin)
    return (ok,begin or 0,end or 0,r.stdout)
def elf_suspects_dut_deadbeef(elf):
    r=run(["riscv32-unknown-elf-objdump","-d",elf])
    if r.returncode!=0:
        return False
    s=r.stdout.lower()
    return ("deadbeef" in s) or ("0xdeadbeef" in s)
def merge_mem_tokens(mem,rom,ram):
    if mem:
        mem=mem.strip()
        if not mem.startswith("-m"):
            mem="-m"+mem
        return mem
    rom=(rom or os.getenv("ARCHTEST_SPIKE_MEM_ROM") or "-m0x80000000:0x20000").strip()
    ram=(ram or os.getenv("ARCHTEST_SPIKE_MEM_RAM") or "-m0x20000000:0x10000").strip()
    rom_body=rom[2:] if rom.startswith("-m") else rom
    ram_body=ram[2:] if ram.startswith("-m") else ram
    return f"-m{rom_body},{ram_body}"
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--isa",default=os.getenv("ARCHTEST_ISA","rv32i"))
    ap.add_argument("--build-dir",default="build/archtest")
    ap.add_argument("--ref-dir",default="tests/third_party/riscv-arch-test/tools/reference_outputs")
    ap.add_argument("--spike-mem",default=os.getenv("ARCHTEST_SPIKE_MEM"))
    ap.add_argument("--spike-mem-rom",default=os.getenv("ARCHTEST_SPIKE_MEM_ROM"))
    ap.add_argument("--spike-mem-ram",default=os.getenv("ARCHTEST_SPIKE_MEM_RAM"))
    args=ap.parse_args()
    build_dir=Path(args.build_dir)
    ref_dir=Path(args.ref_dir)
    logs_dir=ref_dir/"spike-logs"
    ref_dir.mkdir(parents=True,exist_ok=True)
    logs_dir.mkdir(parents=True,exist_ok=True)
    mem_token=merge_mem_tokens(args.spike_mem,args.spike_mem_rom,args.spike_mem_ram)
    metas=sorted(build_dir.glob("*.meta.json"))
    if not metas:
        print(f"[ERRO] Não achei metas em {build_dir}. Rode `make arch-elves` antes.",file=sys.stderr)
        sys.exit(1)
    print(f"[gen-refs] ISA={args.isa}")
    print(f"[gen-refs] MEM={mem_token}")
    print(f"[gen-refs] ELFs/metas em {build_dir}: {len(metas)} itens")
    print(f"[gen-refs] Saídas: {ref_dir}")
    for meta_path in metas:
        meta=json.loads(meta_path.read_text())
        testname=meta["test"]
        elf_spike=meta["elf_spike"]
        sig_path=ref_dir/f"{testname}.sig"
        log_path=logs_dir/f"{testname}.log"
        print(f"[gen-refs] {testname}")
        ok,sig_beg,sig_end,symtxt=elf_has_sig_symbols(elf_spike)
        if not ok:
            print(f"  -> FAIL: ELF sem begin_signature/end_signature: {elf_spike}")
            print(f"[ERRO] Símbolos de assinatura ausentes em {testname}",file=sys.stderr)
            (logs_dir/f"{testname}.symtab.txt").write_text(symtxt)
            sys.exit(4)
        if elf_suspects_dut_deadbeef(elf_spike):
            print(f"  -> AVISO: ELF parece conter padrão DEADBEEF (possível boot_dut.S).",file=sys.stderr)
        print(f"    signature: [{hex(sig_beg)}..{hex(sig_end)}) len={sig_end-sig_beg}")
        cmd=["spike",f"--isa={args.isa}",mem_token,f"+signature={sig_path}","+signature-granularity=4",elf_spike]
        r=run(cmd)
        log_path.write_text("CMD: "+" ".join(cmd)+"\n\nreturncode="+str(r.returncode)+"\n\nSTDOUT:\n"+r.stdout+"\nSTDERR:\n"+r.stderr+"\n")
        if r.returncode!=0:
            print(f"  -> FAIL (veja {log_path})")
            print(f"[ERRO] Spike falhou para {testname}",file=sys.stderr)
            sys.exit(2)
        if not sig_path.exists():
            print(f"  -> FAIL: assinatura não gerada ({sig_path})")
            print(f"[ERRO] Sem assinatura para {testname}",file=sys.stderr)
            sys.exit(3)
        print("  -> OK")
    print("[gen-refs] Concluído com sucesso.")
if __name__=="__main__":
    main()