import os,json,importlib,inspect,asyncio,pathlib
import cocotb
from cocotb.triggers import RisingEdge,Timer

def _load_meta():
    m=os.environ["ARCHTEST_META"]
    if m.strip().startswith("{"): return json.loads(m)
    p=pathlib.Path(m)
    return json.loads(p.read_text())

def _load_ext_reader(dut):
    spec=os.getenv("ARCHTEST_READ32","").strip()
    if not spec: return None
    mod,func=spec.split(":")
    f=getattr(importlib.import_module(mod),func)
    if inspect.iscoroutinefunction(f):
        async def r(addr): return await f(dut,addr)
    else:
        async def r(addr): return f(dut,addr)
    return r

def _hasattr(d,name):
    try: getattr(d,name); return True
    except: return False

def _mk_dbg_reader(dut):
    if not all(_hasattr(dut,n) for n in ["dbg_addr","dbg_read","dbg_rdata","dbg_ready"]): return None
    async def r(addr):
        dut.dbg_addr.value=addr
        dut.dbg_read.value=1
        await RisingEdge(dut.CLK) if _hasattr(dut,"CLK") else Timer(1,"ns")
        while int(dut.dbg_ready.value)==0:
            await RisingEdge(dut.CLK) if _hasattr(dut,"CLK") else Timer(1,"ns")
        val=int(dut.dbg_rdata.value)&0xFFFFFFFF
        dut.dbg_read.value=0
        return val
    return r

async def _await_pass_via_tohost(read32,tohost,cycles,clk):
    c=0
    while c<cycles:
        v=await read32(tohost)
        if v!=0: return v
        if clk: await RisingEdge(clk)
        else: await Timer(10,"ns")
        c+=1
    raise TimeoutError("tohost não sinalizou dentro do limite")

async def _read_signature(read32,beg,end):
    n=end-beg
    out=bytearray(n)
    for off in range(0,n,4):
        w=await read32(beg+off)
        out[off:off+4]=int(w).to_bytes(4,"little",signed=False)
    return bytes(out)

def _as_int(x):
    return int(x, 0) if isinstance(x, str) else int(x)

@cocotb.test()
async def archtest(dut):
    META=_load_meta()
    begin_sig=_as_int(META["symbols"]["begin_signature"])
    end_sig=_as_int(META["symbols"]["end_signature"])
    tohost=_as_int(META["symbols"]["tohost"])
    test_name=META["test"]
    max_cycles=int(os.getenv("ARCHTEST_MAX_CYCLES","200000"))
    clk=getattr(dut,"CLK",None) if _hasattr(dut,"CLK") else None
    ext=_load_ext_reader(dut)
    read32=ext if ext else _mk_dbg_reader(dut)
    if read32 is None: raise RuntimeError("defina ARCHTEST_READ32=mod:func ou exponha dbg_addr/dbg_read/dbg_rdata/dbg_ready no DUT")
    await _await_pass_via_tohost(read32,tohost,max_cycles,clk)
    sig_dut=await _read_signature(read32,begin_sig,end_sig)
    ref_dir=pathlib.Path(os.getenv("ARCHTEST_REF_DIR","tests/third_party/riscv-arch-test/tools/reference_outputs"))
    sig_ref=(ref_dir/f"{test_name}.sig").read_bytes()
    assert sig_dut==sig_ref,f"assinatura diferente em {test_name}: DUT {len(sig_dut)}B vs REF {len(sig_ref)}B"