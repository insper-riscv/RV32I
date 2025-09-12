import cocotb
from cocotb.triggers import Timer

# Constantes (iguais às do pacote VHDL)
OPEXRAM_LW  = 0b000
OPEXRAM_LH  = 0b001
OPEXRAM_LHU = 0b010
OPEXRAM_LB  = 0b011
OPEXRAM_LBU = 0b100


# === Helpers ===
def sext(val, bits, width=32):
    """Sign-extend de 'bits' para 'width' bits."""
    mask = (1 << bits) - 1
    val &= mask
    if val & (1 << (bits - 1)):
        val -= 1 << bits
    return val & ((1 << width) - 1)


def zext(val, bits, width=32):
    """Zero-extend de 'bits' para 'width' bits."""
    mask = (1 << bits) - 1
    return val & mask


async def apply_and_check(dut, op, inp, expected, name):
    width_in = len(dut.signalIn)
    width_out = len(dut.signalOut)

    dut.signalIn.value = inp & ((1 << width_in) - 1)
    dut.opExRAM.value = op
    await Timer(1, "ns")

    got = int(dut.signalOut.value) & ((1 << width_out) - 1)
    exp = expected & ((1 << width_out) - 1)

    assert got == exp, (
        f"{name} falhou: input={inp:#010x}, esperado={exp:#010x}, obtido={got:#010x}"
    )
    dut._log.info(f"{name} OK: in={inp:#010x} out={got:#010x}")


# === Testes separados ===

@cocotb.test()
async def lw(dut):
    """Testa extensão LW (passa direto os 32 bits)."""
    inp = 0xCAFEBABE
    expected = inp
    await apply_and_check(dut, OPEXRAM_LW, inp, expected, "LW")


@cocotb.test()
async def lh(dut):
    """Testa extensão LH (sign-extend de 16 bits)."""
    inp_neg = 0x00008001  # bit 15 = 1 (negativo)
    inp_pos = 0x00007FFF  # bit 15 = 0 (positivo)

    await apply_and_check(dut, OPEXRAM_LH, inp_neg, sext(0x8001, 16), "LH negativo")
    await apply_and_check(dut, OPEXRAM_LH, inp_pos, sext(0x7FFF, 16), "LH positivo")


@cocotb.test()
async def lhu(dut):
    """Testa extensão LHU (zero-extend de 16 bits)."""
    inp = 0x0000ABCD
    expected = zext(0xABCD, 16)
    await apply_and_check(dut, OPEXRAM_LHU, inp, expected, "LHU")


@cocotb.test()
async def lb(dut):
    """Testa extensão LB (sign-extend de 8 bits)."""
    inp_neg = 0x000000F6  # 0xF6 = -10
    inp_pos = 0x0000007F  # 0x7F = +127

    await apply_and_check(dut, OPEXRAM_LB, inp_neg, sext(0xF6, 8), "LB negativo")
    await apply_and_check(dut, OPEXRAM_LB, inp_pos, sext(0x7F, 8), "LB positivo")


@cocotb.test()
async def lbu(dut):
    """Testa extensão LBU (zero-extend de 8 bits)."""
    inp = 0x000000AB
    expected = zext(0xAB, 8)
    await apply_and_check(dut, OPEXRAM_LBU, inp, expected, "LBU")
