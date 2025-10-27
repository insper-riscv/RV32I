import cocotb
from cocotb.triggers import RisingEdge, ReadOnly

_mem = {}  # espelho: addr->byte (0..255)

async def init_sniffer(dut):
    we  = dut.weRAM
    adr = dut.ALU_out
    din = dut.out_StoreManager
    msk = dut.mask
    clk = getattr(dut, "CLK", None)

    async def _loop():
        while True:
            if clk is not None:
                await RisingEdge(clk)
            else:
                await Timer(1, "ns")
            await ReadOnly()
            if int(we.value) != 0:
                A = int(adr.value) & ~0x3
                W = int(din.value) & 0xFFFFFFFF
                M = int(msk.value) & 0xF
                if M == 0: M = 0xF
                for i in range(4):
                    if M & (1 << i):
                        _mem[A + i] = (W >> (8 * i)) & 0xFF

    dut._ram_sniffer_task = cocotb.start_soon(_loop())

def dump_range(begin: int, end: int) -> bytes:
    n = end - begin
    out = bytearray(n)
    for i in range(n):
        out[i] = _mem.get(begin + i, 0)
    return bytes(out)


def ram_read32(dut, addr: int) -> int:
    a = addr & ~0x3
    b0 = _mem.get(a + 0, 0)
    b1 = _mem.get(a + 1, 0)
    b2 = _mem.get(a + 2, 0)
    b3 = _mem.get(a + 3, 0)
    return (b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))