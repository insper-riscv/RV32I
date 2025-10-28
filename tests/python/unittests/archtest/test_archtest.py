import os, json, struct, pathlib
import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, Timer
from cocotb.clock import Clock

from .readers import init_sniffer, dump_range, ram_read32

def _spike_sig_text_to_bytes(sig_text_bytes: bytes) -> bytes:
    out = bytearray()
    for line in sig_text_bytes.splitlines():
        line = line.strip()
        if not line:
            continue
        w = int(line, 16)
        out += struct.pack("<I", w)  # little-endian
    return bytes(out)

@cocotb.test()
async def archtest(dut):
    # meta passado pelo runner. Obrigatório.
    meta = json.loads(os.environ["ARCHTEST_META"])
    syms = meta["symbols"]
    test_name = meta["test"]

    begin_sig = int(syms["begin_signature"], 16)
    end_sig   = int(syms["end_signature"], 16)
    tohost    = int(syms["tohost"], 16)

    max_cycles = int(os.environ.get("ARCHTEST_MAX_CYCLES", "200000"))

    cocotb.log.info(f"SYMS = {syms}")

    cocotb.start_soon(Clock(dut.CLK, 10, units="ns").start())
    
    # inicializa o sniffer de RAM (não tenta dbg_*, nunca mais quebra por causa disso)
    await init_sniffer(dut)

    # loop principal: roda clock até tohost != 0
    done = False
    for cycle in range(max_cycles):
        if hasattr(dut, "CLK"):
            await RisingEdge(dut.CLK)
        else:
            await Timer(1, "ns")

        await ReadOnly()

        th = ram_read32(dut, tohost)
        if th != 0:
            cocotb.log.info(f"[archtest] tohost=0x{th:08x} ciclo={cycle}")
            done = True
            break

    if not done:
        raise AssertionError(f"timeout: tohost ficou 0 até {max_cycles} ciclos")

    # coleta assinatura do DUT
    sig_dut = dump_range(begin_sig, end_sig)

    # carrega referência do Spike
    ref_dir = pathlib.Path(os.environ["ARCHTEST_REF_DIR"])
    sig_ref_txt = (ref_dir / f"{test_name}.sig").read_bytes()
    sig_ref_bin = _spike_sig_text_to_bytes(sig_ref_txt)

    assert sig_dut == sig_ref_bin, (
        f"assinatura diferente em {test_name}: "
        f"DUT {len(sig_dut)}B vs REF {len(sig_ref_bin)}B"
    )