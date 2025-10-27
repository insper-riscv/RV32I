from cocotb.triggers import RisingEdge, ReadOnly

_mem = {}  # espelho: addr->byte (0..255)

async def init_sniffer(dut):
    clk = dut.CLK
    we  = dut.weRAM
    adr = dut.ALU_out
    din = dut.out_StoreManager
    msk = dut.mask  # 4 bits, little-endian

    async def _loop():
        while True:
            await RisingEdge(clk)
            await ReadOnly()
            if int(we.value) != 0:
                A = int(adr.value) & ~0x3
                W = int(din.value) & 0xFFFFFFFF
                M = int(msk.value) & 0xF
                if M == 0: M = 0xF
                for i in range(4):
                    if M & (1 << i):
                        _mem[A + i] = (W >> (8 * i)) & 0xFF

    dut._ram_sniffer_task = dut._cocotb_start_soon(_loop())

def ram_read32(dut, addr: int) -> int:
    a = addr & ~0x3
    b0 = _mem.get(a + 0, 0)
    b1 = _mem.get(a + 1, 0)
    b2 = _mem.get(a + 2, 0)
    b3 = _mem.get(a + 3, 0)
    return (b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))