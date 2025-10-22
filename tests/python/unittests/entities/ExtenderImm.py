import cocotb
from cocotb.triggers import Timer
import random

# Constantes (iguais às do pacote VHDL)
OPEXIMM_U       = 0b000
OPEXIMM_I       = 0b001
OPEXIMM_I_SHAMT = 0b010
OPEXIMM_J       = 0b011
OPEXIMM_S       = 0b100
OPEXIMM_B       = 0b101

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
    dut.Inst31downto7.value = inp & ((1 << len(dut.Inst31downto7)) - 1)
    dut.opExImm.value = op
    await Timer(1, "ns")

    got = int(dut.signalOut.value)
    assert got == expected, (
        f"{name} falhou: input={inp:#09x}, esperado={expected:#010x}, obtido={got:#010x}"
    )
    dut._log.info(f"{name} OK: in={inp:#09x} out={got:#010x}")

@cocotb.test()
async def u(dut):
    """Testa extensão U-type (instr[31:12] << 12)."""
    inp = random.getrandbits(25)
    upper = (inp >> 5) & ((1 << 20) - 1)
    expected = (upper << 12) & 0xFFFFFFFF
    await apply_and_check(dut, OPEXIMM_U, inp, expected, "U-type")


@cocotb.test()
async def i(dut):
    """Testa extensão I-type (sext(instr[31:20]))."""
    inp = random.getrandbits(25)
    imm12 = (inp >> 13) & 0xFFF
    expected = sext(imm12, 12)
    await apply_and_check(dut, OPEXIMM_I, inp, expected, "I-type")


@cocotb.test()
async def i_shamt(dut):
    """Testa extensão I-shamt (zext(instr[24:20]))."""
    inp = random.getrandbits(25)
    shamt = (inp >> 13) & 0x1F
    expected = zext(shamt, 5)
    await apply_and_check(dut, OPEXIMM_I_SHAMT, inp, expected, "I-shamt")


@cocotb.test()
async def jal(dut):
    """Testa extensão JAL-type (sext(offset))."""
    inp = random.getrandbits(25)
    imm20 = (inp >> 24) & 0x1
    imm10_1 = (inp >> 14) & 0x3FF
    imm11 = (inp >> 13) & 0x1
    imm19_12 = (inp >> 5) & 0xFF
    offset = (imm20 << 20) | (imm19_12 << 12) | (imm11 << 11) | (imm10_1 << 1)
    expected = sext(offset, 21)
    await apply_and_check(dut, OPEXIMM_J, inp, expected, "JAL")


@cocotb.test()
async def jalr(dut):
    """Testa extensão JALR-type (sext(instr[31:20]))."""
    inp = random.getrandbits(25)
    imm12 = (inp >> 13) & 0xFFF
    expected = sext(imm12, 12)
    await apply_and_check(dut, OPEXIMM_I, inp, expected, "JALR")


@cocotb.test()
async def s(dut):
    """Testa extensão S-type (sext(instr[31:25] & instr[11:7]))."""
    inp = random.getrandbits(25)
    imm_high = (inp >> 18) & 0x7F
    imm_low = inp & 0x1F
    imm12 = (imm_high << 5) | imm_low
    expected = sext(imm12, 12)
    await apply_and_check(dut, OPEXIMM_S, inp, expected, "S-type")
