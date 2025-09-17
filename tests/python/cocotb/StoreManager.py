import cocotb
from cocotb.triggers import Timer

# Constantes
OPCODE_STORE = 0b0100011
FUNCT3_SW = 0b010
FUNCT3_SH = 0b001
FUNCT3_SB = 0b000


async def apply_and_check(dut, funct3, ea, rs2, exp_data, exp_mask):
    dut.opcode.value = OPCODE_STORE
    dut.funct3.value = funct3
    dut.EA.value     = ea
    dut.rs2Val.value = rs2

    await Timer(1, units="ns")

    got_data = int(dut.data_out.value)
    got_mask = int(dut.mask.value)

    assert got_data == exp_data, f"funct3={funct3:03b}, EA={ea:02b}: esperado data=0x{exp_data:08X}, obtido 0x{got_data:08X}"
    assert got_mask == exp_mask, f"funct3={funct3:03b}, EA={ea:02b}: esperado mask={exp_mask:04b}, obtido {got_mask:04b}"


@cocotb.test()
async def sw(dut):
    """Testa Store Word (SW)."""
    rs2 = 0xAABBCCDD
    await apply_and_check(dut, FUNCT3_SW, 0b00, rs2, rs2, 0b1111)


@cocotb.test()
async def sh(dut):
    """Testa Store Halfword (SH)."""
    rs2 = 0x0000BEEF

    # EA[1]=0 → bytes 0 e 1
    await apply_and_check(dut, FUNCT3_SH, 0b00, rs2, 0x0000BEEF, 0b0011)

    # EA[1]=1 → bytes 2 e 3
    await apply_and_check(dut, FUNCT3_SH, 0b10, rs2, 0xBEEF0000, 0b1100)


@cocotb.test()
async def sb(dut):
    """Testa Store Byte (SB)."""
    rs2 = 0x000000AA

    # EA=00 → byte0
    await apply_and_check(dut, FUNCT3_SB, 0b00, rs2, 0x000000AA, 0b0001)

    # EA=01 → byte1
    await apply_and_check(dut, FUNCT3_SB, 0b01, rs2, 0x0000AA00, 0b0010)

    # EA=10 → byte2
    await apply_and_check(dut, FUNCT3_SB, 0b10, rs2, 0x00AA0000, 0b0100)

    # EA=11 → byte3
    await apply_and_check(dut, FUNCT3_SB, 0b11, rs2, 0xAA000000, 0b1000)


@cocotb.test()
async def invalid_opcode(dut):
    """Testa opcode inválido."""
    dut.opcode.value = 0b0000000
    dut.funct3.value = 0b111
    dut.EA.value     = 0b00
    dut.rs2Val.value = 0x12345678

    await Timer(1, units="ns")

    assert int(dut.data_out.value) == 0
    assert int(dut.mask.value) == 0
