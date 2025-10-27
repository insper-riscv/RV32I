import os, json, importlib, inspect, pathlib
import cocotb
from cocotb.triggers import RisingEdge, Timer

def _load_meta():
    m = os.environ["ARCHTEST_META"]
    if m.strip().startswith("{"): return json.loads(m)
    return json.loads(pathlib.Path(m).read_text())

def _load_ext_reader_and_init(dut):
    """Lê ARCHTEST_READER_INIT e ARCHTEST_READ32 e retorna (init_fn|None, async read32|None)."""
    init_spec = os.getenv("ARCHTEST_READER_INIT", "").strip()
    read_spec = os.getenv("ARCHTEST_READ32", "").strip()

    init_fn = None
    if init_spec:
        mod, func = init_spec.split(":")
        init_fn = getattr(importlib.import_module(mod), func)

    reader = None
    if read_spec:
        mod, func = read_spec.split(":")
        f = getattr(importlib.import_module(mod), func)
        if inspect.iscoroutinefunction(f):
            async def r(addr): return await f(dut, addr)
        else:
            async def r(addr): return f(dut, addr)
        reader = r

    return init_fn, reader

def _hasattr(d, name):
    try:
        getattr(d, name)
        return True
    except Exception:
        return False

def _mk_dbg_reader(dut):
    """Fallback: precisa dos pinos dbg_addr/dbg_read/dbg_rdata/dbg_ready expondo leitura de 32b."""
    req = ["dbg_addr", "dbg_read", "dbg_rdata", "dbg_ready"]
    if not all(_hasattr(dut, n) for n in req): return None

    async def r(addr):
        dut.dbg_addr.value = addr
        dut.dbg_read.value = 1
        if _hasattr(dut, "CLK"): await RisingEdge(dut.CLK)
        else: await Timer(1, "ns")
        while int(dut.dbg_ready.value) == 0:
            if _hasattr(dut, "CLK"): await RisingEdge(dut.CLK)
            else: await Timer(1, "ns")
        val = int(dut.dbg_rdata.value) & 0xFFFFFFFF
        dut.dbg_read.value = 0
        return val
    return r

async def _await_pass_via_tohost(read32, tohost, cycles, clk):
    if not tohost:
        # se não houver tohost, apenas avance alguns ciclos para o programa terminar a assinatura
        fallback = int(os.getenv("ARCHTEST_FALLBACK_CYCLES", "50000"))
        if clk:
            for _ in range(fallback): await RisingEdge(clk)
        else:
            await Timer(1, "ms")
        return 0
    c = 0
    while c < cycles:
        v = await read32(tohost)
        if v != 0: return v
        if clk: await RisingEdge(clk)
        else: await Timer(10, "ns")
        c += 1
    raise TimeoutError("tohost não sinalizou dentro do limite")

async def _read_signature(read32, beg, end):
    n = end - beg
    out = bytearray(n)
    for off in range(0, n, 4):
        w = await read32(beg + off)
        out[off:off+4] = int(w).to_bytes(4, "little", signed=False)
    return bytes(out)

def _as_int(x):
    return int(x, 0) if isinstance(x, str) else int(x)

@cocotb.test()
async def archtest(dut):
    META = _load_meta()

    # símbolos (aceita str ou int)
    begin_sig = _as_int(META["symbols"]["begin_signature"])
    end_sig   = _as_int(META["symbols"]["end_signature"])
    tohost    = META["symbols"].get("tohost")
    tohost    = _as_int(tohost) if tohost is not None else 0
    test_name = META["test"]

    # reader externo + init opcional (sniffer)
    init_fn, read32 = _load_ext_reader_and_init(dut)
    if init_fn:
        if inspect.iscoroutinefunction(init_fn): await init_fn(dut)
        else: init_fn(dut)

    # fallback: porta de debug, se existir
    if read32 is None:
        read32 = _mk_dbg_reader(dut)
    if read32 is None:
        raise RuntimeError("defina ARCHTEST_READ32 e ARCHTEST_READER_INIT, ou exponha dbg_addr/dbg_read/dbg_rdata/dbg_ready no DUT")

    # clock (se houver)
    clk = getattr(dut, "CLK", None) if _hasattr(dut, "CLK") else None

    # espera PASS via tohost (ou fallback de ciclos)
    max_cycles = int(os.getenv("ARCHTEST_MAX_CYCLES", "200000"))
    await _await_pass_via_tohost(read32, tohost, max_cycles, clk)

    # assinatura do DUT
    sig_dut = await _read_signature(read32, begin_sig, end_sig)

    # assinatura de referência
    ref_dir = pathlib.Path(os.getenv("ARCHTEST_REF_DIR", "tests/third_party/riscv-arch-test/tools/reference_outputs"))
    sig_ref = (ref_dir / f"{test_name}.sig").read_bytes()

    assert sig_dut == sig_ref, f"assinatura diferente em {test_name}: DUT {len(sig_dut)}B vs REF {len(sig_ref)}B"