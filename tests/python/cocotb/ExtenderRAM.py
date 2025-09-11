import cocotb
from cocotb.triggers import Timer

# Constantes (iguais às do pacote VHDL)
OPEXRAM_LW  = 0b000
OPEXRAM_LH  = 0b001
OPEXRAM_LHU = 0b010
OPEXRAM_LB  = 0b011
OPEXRAM_LBU = 0b100


def sext(val, bits, width=32):
    """Sign-extend de 'bits' para 'width' bits."""
    mask = (1 << bits) - 1
    val &= mask
    if val & (1 << (bits - 1)):  # bit de sinal
        val -= 1 << bits
    return val & ((1 << width) - 1)


def zext(val, bits, width=32):
    """Zero-extend de 'bits' para 'width' bits."""
    mask = (1 << bits) - 1
    return val & mask


async def apply_and_check(dut, op, inp, expected, name):
    # garante que o valor caiba no tamanho do signalIn do DUT
    width = len(dut.signalIn)
    dut.signalIn.value = inp & ((1 << width) - 1)
    dut.opExRAM.value = op
    await Timer(1, "ns")

    got = int(dut.signalOut.value)
    assert got == expected & ((1 << len(dut.signalOut)) - 1), (
        f"{name} falhou: input={inp:#x}, esperado={expected:#x}, obtido={got:#x}"
    )
    dut._log.info(f"{name} OK: in={inp:#x} out={got:#x}")



@cocotb.test()
async def test_extender_ram(dut):
    """Testa todas as variantes de extensão do ExtenderImm."""

    # LW → deve passar direto
    await apply_and_check(dut, OPEXRAM_LW, 0xCAFEBABE, 0xCAFEBABE, "LW")

    # LH → sign-extend de 16 bits
    await apply_and_check(dut, OPEXRAM_LH, 0x00008001, sext(0x8001, 16), "LH negativo")
    await apply_and_check(dut, OPEXRAM_LH, 0x00007FFF, sext(0x7FFF, 16), "LH positivo")

    # LHU → zero-extend de 16 bits
    await apply_and_check(dut, OPEXRAM_LHU, 0x0000ABCD, zext(0xABCD, 16), "LHU")

    # LB → sign-extend de 8 bits
    await apply_and_check(dut, OPEXRAM_LB, 0x000000F6, sext(0xF6, 8), "LB negativo")
    await apply_and_check(dut, OPEXRAM_LB, 0x0000007F, sext(0x7F, 8), "LB positivo")

    # LBU → zero-extend de 8 bits
    await apply_and_check(dut, OPEXRAM_LBU, 0x000000AB, zext(0xAB, 8), "LBU")
