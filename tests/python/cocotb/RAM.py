import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


# Máscaras para store
MASK_SB = 0b0001
MASK_SH = 0b0011
MASK_SW = 0b1111

async def init_dut(dut):
    """Coloca todos os pinos em zero antes do teste começar."""
    dut.addr.value = 0
    dut.data_in.value = 0
    dut.mask.value = 0
    dut.we.value = 0
    # se a RAM tiver saídas ou resets extras, coloque aqui também
    await Timer(1, "ns")  # tempo para propagar

async def write_word(dut, addr, data, mask):
    """Escreve um valor na RAM com máscara."""
    dut.addr.value = addr
    dut.data_in.value = data
    dut.mask.value = mask
    dut.we.value = 1
    await RisingEdge(dut.clk)
    dut.we.value = 0


async def read_word(dut, addr):
    """Lê uma palavra inteira da RAM."""
    dut.addr.value = addr
    await Timer(1, "ns")
    return int(dut.data_out.value)



@cocotb.test()
async def test_sw(dut):
    """Testa store word (SW)."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    addr = 0
    data = 0xAABBCCDD

    await write_word(dut, addr, data, MASK_SW)
    got = await read_word(dut, addr)

    assert got == data, f"SW falhou: esperado {data:#010x}, obtido {got:#010x}"


@cocotb.test()
async def test_sh(dut):
    """Testa store halfword (SH)."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    addr = 0
    base = 0x11223344
    await write_word(dut, addr, base, MASK_SW)

    # sobrescreve metade baixa
    half = 0x0000BEEF
    await write_word(dut, addr, half, MASK_SH)
    got = await read_word(dut, addr)

    expected = 0x1122BEEF
    assert got == expected, f"SH falhou: esperado {expected:#010x}, obtido {got:#010x}"


@cocotb.test()
async def test_sb(dut):
    """Testa store byte (SB)."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    addr = 0
    base = 0x55667788
    await write_word(dut, addr, base, MASK_SW)

    # sobrescreve byte mais baixo
    byte = 0x000000AA
    await write_word(dut, addr, byte, MASK_SB)
    got = await read_word(dut, addr)

    expected = 0x556677AA
    assert got == expected, f"SB falhou: esperado {expected:#010x}, obtido {got:#010x}"


@cocotb.test()
async def test_lw(dut):
    """Testa load word (LW)."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    addr = 0
    data = 0xCAFEBABE
    await write_word(dut, addr, data, MASK_SW)

    got = await read_word(dut, addr)
    assert got == data, f"LW falhou: esperado {data:#010x}, obtido {got:#010x}"


@cocotb.test()
async def test_lh_lhu(dut):
    """Testa load halfword (LH e LHU)."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    addr = 0
    data = 0x0000F00D
    await write_word(dut, addr, data, MASK_SW)

    got = await read_word(dut, addr)

    # LH = extensão de sinal de 16 bits
    lh = (got & 0xFFFF)
    if lh & 0x8000:  # bit de sinal
        lh -= 1 << 16
    assert lh == -0x0FF3, f"LH falhou: obtido {lh}"

    # LHU = extensão zero
    lhu = got & 0xFFFF
    assert lhu == 0xF00D, f"LHU falhou: obtido {lhu:#06x}"


@cocotb.test()
async def test_lb_lbu(dut):
    """Testa load byte (LB e LBU)."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    addr = 0
    data = 0x000000F6  # byte mais baixo = 0xF6 = -10 signed
    await write_word(dut, addr, data, MASK_SW)

    got = await read_word(dut, addr)

    # LB = extensão de sinal de 8 bits
    lb = got & 0xFF
    if lb & 0x80:
        lb -= 1 << 8
    assert lb == -10, f"LB falhou: obtido {lb}"

    # LBU = extensão zero
    lbu = got & 0xFF
    assert lbu == 0xF6, f"LBU falhou: obtido {lbu:#04x}"


@cocotb.test()
async def test_multi_positions(dut):
    """Escreve em múltiplas posições diferentes e confere leituras."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    # endereço 0
    addr0 = 0
    data0 = 0x11111111
    await write_word(dut, addr0, data0, MASK_SW)

    # endereço 4 (próxima palavra)
    addr1 = 4
    data1 = 0x22222222
    await write_word(dut, addr1, data1, MASK_SW)

    # endereço 8 (mais uma palavra)
    addr2 = 8
    data2 = 0x33333333
    await write_word(dut, addr2, data2, MASK_SW)

    # verifica leituras independentes
    got0 = await read_word(dut, addr0)
    got1 = await read_word(dut, addr1)
    got2 = await read_word(dut, addr2)

    assert got0 == data0, f"Falhou em addr0: esperado {data0:#010x}, obtido {got0:#010x}"
    assert got1 == data1, f"Falhou em addr1: esperado {data1:#010x}, obtido {got1:#010x}"
    assert got2 == data2, f"Falhou em addr2: esperado {data2:#010x}, obtido {got2:#010x}"


@cocotb.test()
async def test_overwrite_position(dut):
    """Escreve em uma posição, sobrescreve depois, e verifica se valor foi atualizado."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    addr = 0
    first = 0xAAAAAAAA
    second = 0x55555555

    # primeira escrita
    await write_word(dut, addr, first, MASK_SW)
    got1 = await read_word(dut, addr)
    assert got1 == first, f"Overwrite falhou passo 1: esperado {first:#010x}, obtido {got1:#010x}"

    # sobrescreve
    await write_word(dut, addr, second, MASK_SW)
    got2 = await read_word(dut, addr)
    assert got2 == second, f"Overwrite falhou passo 2: esperado {second:#010x}, obtido {got2:#010x}"


@cocotb.test()
async def test_crosscheck_positions(dut):
    """Escreve em várias posições e verifica que não houve contaminação cruzada."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    addr_a = 0
    addr_b = 4
    data_a = 0xDEADBEEF
    data_b = 0xCAFEBABE

    # escreve no endereço A
    await write_word(dut, addr_a, data_a, MASK_SW)

    # escreve no endereço B
    await write_word(dut, addr_b, data_b, MASK_SW)

    # lê de volta
    got_a = await read_word(dut, addr_a)
    got_b = await read_word(dut, addr_b)

    assert got_a == data_a, f"Crosscheck falhou: addrA esperado {data_a:#010x}, obtido {got_a:#010x}"
    assert got_b == data_b, f"Crosscheck falhou: addrB esperado {data_b:#010x}, obtido {got_b:#010x}"