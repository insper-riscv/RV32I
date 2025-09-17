import cocotb
from cocotb.triggers import Timer

# Constantes iguais às do seu pacote VHDL rv32i_ctrl_consts
OPEXRAM_LW  = 0b000
OPEXRAM_LH  = 0b001
OPEXRAM_LHU = 0b010
OPEXRAM_LB  = 0b011
OPEXRAM_LBU = 0b100


async def apply_and_check(dut, opExRAM, EA, sig_in, expected, desc=""):
    dut.signalIn.value = sig_in
    dut.opExRAM.value = opExRAM
    dut.EA.value = EA

    await Timer(1, units="ns")

    got = int(dut.signalOut.value.signed_integer) if opExRAM in (OPEXRAM_LH, OPEXRAM_LB) else int(dut.signalOut.value)

    assert got == expected, f"{desc} falhou: esperado {expected:#010x}, obtido {got:#010x}"


@cocotb.test()
async def lw(dut):
    """Testa LW: deve retornar a word inteira."""
    sig_in = 0xAABBCCDD
    await apply_and_check(dut, OPEXRAM_LW, 0b00, sig_in, 0xAABBCCDD, "LW")


@cocotb.test()
async def lh_lhu(dut):
    """Testa LH e LHU com EA=0 e EA=2."""
    sig_in = 0xAABBCCDD  # b0=DD, b1=CC, b2=BB, b3=AA

    # LH EA=0 -> 0xCCDD sign-extend
    half0 = 0xCCDD
    signed_half0 = half0 if half0 < 0x8000 else half0 - 0x10000
    await apply_and_check(dut, OPEXRAM_LH, 0b00, sig_in, signed_half0, "LH EA=0")

    # LH EA=2 -> 0xAABB sign-extend
    half2 = 0xAABB
    signed_half2 = half2 if half2 < 0x8000 else half2 - 0x10000
    await apply_and_check(dut, OPEXRAM_LH, 0b10, sig_in, signed_half2, "LH EA=2")

    # LHU EA=0 -> 0x0000CCDD
    await apply_and_check(dut, OPEXRAM_LHU, 0b00, sig_in, 0x0000CCDD, "LHU EA=0")

    # LHU EA=2 -> 0x0000AABB
    await apply_and_check(dut, OPEXRAM_LHU, 0b10, sig_in, 0x0000AABB, "LHU EA=2")


@cocotb.test()
async def lb_lbu(dut):
    """Testa LB e LBU com todos os valores de EA."""
    sig_in = 0xAABBCCDD  # b0=DD, b1=CC, b2=BB, b3=AA

    # LB com sign-extend
    for ea, exp_byte in [(0b00, 0xDD), (0b01, 0xCC), (0b10, 0xBB), (0b11, 0xAA)]:
        signed_val = exp_byte if exp_byte < 0x80 else exp_byte - 0x100
        await apply_and_check(dut, OPEXRAM_LB, ea, sig_in, signed_val, f"LB EA={ea}")

    # LBU com zero-extend
    for ea, exp_byte in [(0b00, 0xDD), (0b01, 0xCC), (0b10, 0xBB), (0b11, 0xAA)]:
        await apply_and_check(dut, OPEXRAM_LBU, ea, sig_in, exp_byte, f"LBU EA={ea}")
