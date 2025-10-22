import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# Máscaras de exemplo
MASKS = [
    0b0001, 0b0010, 0b0100, 0b1000,   # 1 byte
    0b0011, 0b1100, 0b0110,           # 2 bytes
    0b1110, 0b0111,                   # 3 bytes
    0b1111                            # 4 bytes
]

async def init_dut(dut):
    dut.addr.value = 0
    dut.data_in.value = 0
    dut.mask.value = 0
    dut.weRAM.value = 0
    dut.reRAM.value = 0
    dut.eRAM.value = 0
    await Timer(1, units="ns")

async def write_word(dut, addr, data, mask):
    dut.addr.value = addr
    dut.data_in.value = data
    dut.mask.value = mask
    dut.eRAM.value = 1
    dut.weRAM.value = 1
    await RisingEdge(dut.clk)
    dut.weRAM.value = 0
    dut.eRAM.value = 0

async def read_word(dut, addr, expect_z=False):
    dut.addr.value = addr
    dut.eRAM.value = 1
    dut.reRAM.value = 1
    await Timer(1, units="ns")
    val = dut.data_out.value
    dut.reRAM.value = 0
    dut.eRAM.value = 0
    if expect_z:
        # saída em alta impedância
        assert str(val) == "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz", f"Esperado Z, obtido {val}"
        return None
    return int(val)

@cocotb.test()
async def sw_fullword(dut):
    """Testa escrita/leitura com mask=1111 (SW)."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    data = 0xDEADBEEF
    await write_word(dut, 0, data, 0b1111)
    got = await read_word(dut, 0)
    assert got == data, f"SW falhou: esperado {data:#010x}, obtido {got:#010x}"

@cocotb.test()
async def all_masks(dut):
    """Testa todas as máscaras possíveis de escrita parcial."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    base = 0x11223344
    addr = 0

    for mask in MASKS:
        # escreve valor base completo
        await write_word(dut, addr, base, 0b1111)
        # escreve valor novo parcial
        newval = 0xAABBCCDD
        await write_word(dut, addr, newval, mask)
        got = await read_word(dut, addr)

        # calcula esperado: mistura de base + newval conforme mask
        expected = 0
        for i in range(4):
            if (mask >> i) & 1:
                expected |= ((newval >> (8*i)) & 0xFF) << (8*i)
            else:
                expected |= ((base >> (8*i)) & 0xFF) << (8*i)

        assert got == expected, f"Mask {mask:04b} falhou: esperado {expected:#010x}, obtido {got:#010x}"

@cocotb.test()
async def disable_read(dut):
    """Verifica que data_out vai para 0 se reRAM=0 ou eRAM=0."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    data = 0xCAFEBABE
    await write_word(dut, 0, data, 0b1111)

    # leitura com reRAM=0
    dut.addr.value = 0
    dut.eRAM.value = 1
    dut.reRAM.value = 0
    await Timer(1, "ns")
    assert str(dut.data_out.value).lower().startswith("00"), "Esperado alta impedância quando reRAM=0"

    # leitura com eRAM=0
    dut.reRAM.value = 1
    dut.eRAM.value = 0
    await Timer(1, "ns")
    assert str(dut.data_out.value).lower().startswith("00"), "Esperado alta impedância quando eRAM=0"

@cocotb.test()
async def multi_positions(dut):
    """Escreve em posições diferentes e confere leituras independentes."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    data0, data1, data2 = 0x11111111, 0x22222222, 0x33333333

    await write_word(dut, 0, data0, 0b1111)
    await write_word(dut, 4, data1, 0b1111)
    await write_word(dut, 8, data2, 0b1111)

    got0 = await read_word(dut, 0)
    got1 = await read_word(dut, 4)
    got2 = await read_word(dut, 8)

    assert got0 == data0
    assert got1 == data1
    assert got2 == data2

@cocotb.test()
async def overwrite(dut):
    """Escreve, sobrescreve, e confere atualização."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    first, second = 0xAAAAAAAA, 0x55555555

    await write_word(dut, 0, first, 0b1111)
    got1 = await read_word(dut, 0)
    assert got1 == first

    await write_word(dut, 0, second, 0b1111)
    got2 = await read_word(dut, 0)
    assert got2 == second

# ==== Helpers para o archtest (backdoor read) ==========================
# O test_archtest.py procura por read32 / read_mem_range aqui.

def _get_mem_signal(dut):
    """
    Retorna o array da RAM (std_logic_vector array) em ambos os cenários:
    - Teste de entidade:    dut é a RAM  -> usar dut.mem
    - Teste do topo (CPU):  dut é rv32i  -> usar dut.RAM.mem
    """
    # 1) Caso o próprio dut seja a RAM
    if hasattr(dut, "mem"):
        return dut.mem
    # 2) Caso a RAM esteja instanciada no topo como 'RAM'
    if hasattr(dut, "RAM") and hasattr(dut.RAM, "mem"):
        return dut.RAM.mem
    raise RuntimeError(
        "Não achei o array de memória. "
        "Confirme o nome da instância (RAM) e do sinal interno (mem)."
    )

async def read32(dut, addr: int) -> int:
    """
    Lê 32 bits (little-endian) do endereço 'addr' (em bytes).
    Sua RAM é indexada por palavra, então usamos addr >> 2.
    """
    mem = _get_mem_signal(dut)
    widx = addr >> 2
    depth = len(mem)
    if widx < 0 or widx >= depth:
        raise RuntimeError(
            f"Endereço fora da RAM: addr=0x{addr:08x} (index={widx}, depth={depth})"
        )
    return int(mem[widx].value)

async def read_mem_range(dut, start: int, length: int) -> bytes:
    """
    Lê 'length' bytes a partir de 'start' via backdoor,
    montando a sequência em little-endian a partir de words de 32 bits.
    """
    if length <= 0:
        return b""

    first = start & ~0x3
    last  = (start + length + 3) & ~0x3
    out   = bytearray()

    for addr in range(first, last, 4):
        w = await read32(dut, addr)
        out += int(w).to_bytes(4, "little")

    off = start & 0x3
    return bytes(out[off: off + length])
# ======================================================================