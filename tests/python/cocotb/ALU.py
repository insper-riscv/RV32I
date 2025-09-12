import cocotb
from cocotb.triggers import Timer
import random


OPCODES = {
    "PASS_B": "00000",
    "ADD":    "00001",
    "XOR":    "00010",
    "OR":     "00011",
    "AND":    "00100",
    "SLL":    "00101",
    "SRL":    "00110",
    "SRA":    "00111",
    "SUB":    "01000",
    "SLT":    "01001",
    "SLTU":   "01010",
    "BEQ":    "01011",
    "BNE":    "01100",
    "BLT":    "01101",
    "BGE":    "01110",
    "BLTU":   "01111",
    "BGEU":   "10000",
}


def to_bits(val, width=32):
    mask = (1 << width) - 1
    return val & mask


def to_signed(val, width=32):
    mask = (1 << width) - 1
    val &= mask
    if val & (1 << (width - 1)):
        return val - (1 << width)
    return val


async def apply_and_check(dut, op_name, a, b, expected_data, expected_branch):
    dut.op.value = int(OPCODES[op_name], 2)
    dut.dA.value = to_bits(a)
    dut.dB.value = to_bits(b)
    await Timer(1, units="ns")

    got_data = int(dut.dataOut.value)
    got_branch = int(dut.branch.value)

    assert got_data == to_bits(expected_data), (
        f"{op_name}: dA={a}, dB={b}, "
        f"esperado dataOut={expected_data}, obtido {to_signed(got_data)} "
        f"(hex: dA={a:#010x}, dB={b:#010x}, dataOut={got_data:#010x}), "
        f"branch={got_branch}"
    )
    assert got_branch == expected_branch, (
        f"{op_name}: esperado branch={expected_branch}, obtido {got_branch}"
    )

    dut._log.info(
        f"{op_name} OK: "
        f"dA={a}, dB={b}, dataOut={to_signed(got_data)} "
        f"(hex: dA={a:#010x}, dB={b:#010x}, dataOut={got_data:#010x}), "
        f"branch={got_branch}"
    )


# === Testes separados para cada operação ===

@cocotb.test()
async def pass_b(dut):
    a, b = 10, 20
    await apply_and_check(dut, "PASS_B", a, b, b, 0)


@cocotb.test()
async def add(dut):
    a, b = 15, 7
    await apply_and_check(dut, "ADD", a, b, a + b, 0)


@cocotb.test()
async def sub(dut):
    a, b = 50, 20
    await apply_and_check(dut, "SUB", a, b, a - b, 0)


@cocotb.test()
async def xor(dut):
    a, b = 0b1010, 0b1100
    await apply_and_check(dut, "XOR", a, b, a ^ b, 0)


@cocotb.test()
async def or_(dut):
    a, b = 0b1010, 0b1100
    await apply_and_check(dut, "OR", a, b, a | b, 0)


@cocotb.test()
async def and_(dut):
    a, b = 0b1010, 0b1100
    await apply_and_check(dut, "AND", a, b, a & b, 0)


@cocotb.test()
async def sll(dut):
    a, b = 1, 3
    await apply_and_check(dut, "SLL", a, b, to_bits(a << (b & 0x1F)), 0)


@cocotb.test()
async def srl(dut):
    a, b = 16, 2
    await apply_and_check(dut, "SRL", a, b, a >> (b & 0x1F), 0)


@cocotb.test()
async def sra(dut):
    a, b = -16, 2
    await apply_and_check(dut, "SRA", a, b, to_signed(a) >> (b & 0x1F), 0)


@cocotb.test()
async def slt(dut):
    a, b = -5, 7
    await apply_and_check(dut, "SLT", a, b, 1 if to_signed(a) < to_signed(b) else 0, 0)


@cocotb.test()
async def sltu(dut):
    a, b = 5, 7
    await apply_and_check(dut, "SLTU", a, b, 1 if a < b else 0, 0)


@cocotb.test()
async def beq(dut):
    a, b = 10, 10
    await apply_and_check(dut, "BEQ", a, b, 0, 1)


@cocotb.test()
async def bne(dut):
    a, b = 10, 20
    await apply_and_check(dut, "BNE", a, b, 0, 1)


@cocotb.test()
async def blt(dut):
    a, b = -5, 7
    await apply_and_check(dut, "BLT", a, b, 0, 1)


@cocotb.test()
async def bge(dut):
    a, b = 10, 5
    await apply_and_check(dut, "BGE", a, b, 0, 1)


@cocotb.test()
async def bltu(dut):
    a, b = 1, 2
    await apply_and_check(dut, "BLTU", a, b, 0, 1)


@cocotb.test()
async def bgeu(dut):
    a, b = 2, 1
    await apply_and_check(dut, "BGEU", a, b, 0, 1)
