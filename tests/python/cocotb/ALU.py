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
        f"{op_name}: "
        f"dA={a} dB={b} dataOut esperado={expected_data} obtido={to_signed(got_data)} "
        f"--> (dA={a:#010x} dB={b:#010x} dataOut={got_data:#010x}), branch={got_branch}"
    )
    assert got_branch == expected_branch, (
        f"{op_name}: esperado branch={expected_branch}, obtido {got_branch}"
    )

    dut._log.info(
        f"{op_name} OK: "
        f"dA={a} dB={b} dataOut={to_signed(got_data)} "
        f"--> (dA={a:#010x} dB={b:#010x} dataOut={got_data:#010x}), "
        f"branch={got_branch}"
    )


@cocotb.test()
async def test_fuzz_ops(dut):
    """Fuzz test da ALU: sorteia operandos e confere com operações Python."""
    random.seed(2025)

    for _ in range(1):  # número de testes aleatórios
        a = random.getrandbits(5)
        b = random.getrandbits(5)

        sa, sb = to_signed(a), to_signed(b)

        # PASS_B
        await apply_and_check(dut, "PASS_B", a, b, b, 0)

        # ADD
        await apply_and_check(dut, "ADD", a, b, sa + sb, 0)

        # SUB
        await apply_and_check(dut, "SUB", a, b, sa - sb, 0)

        # XOR
        await apply_and_check(dut, "XOR", a, b, a ^ b, 0)

        # OR
        await apply_and_check(dut, "OR", a, b, a | b, 0)

        # AND
        await apply_and_check(dut, "AND", a, b, a & b, 0)

        # SLL
        shamt = b & 0x1F
        await apply_and_check(dut, "SLL", a, b, to_bits(a << shamt), 0)

        # SRL
        await apply_and_check(dut, "SRL", a, b, a >> shamt, 0)

        # SRA (usar signed)
        await apply_and_check(dut, "SRA", a, b, sa >> shamt, 0)

        # SLT (signed)
        await apply_and_check(dut, "SLT", a, b, 1 if sa < sb else 0, 0)

        # SLTU (unsigned)
        await apply_and_check(dut, "SLTU", a, b, 1 if a < b else 0, 0)

        # BEQ
        await apply_and_check(dut, "BEQ", a, b, 0, 1 if a == b else 0)

        # BNE
        await apply_and_check(dut, "BNE", a, b, 0, 1 if a != b else 0)

        # BLT signed
        await apply_and_check(dut, "BLT", a, b, 0, 1 if sa < sb else 0)

        # BGE signed
        await apply_and_check(dut, "BGE", a, b, 0, 1 if sa >= sb else 0)

        # BLTU unsigned
        await apply_and_check(dut, "BLTU", a, b, 0, 1 if a < b else 0)

        # BGEU unsigned
        await apply_and_check(dut, "BGEU", a, b, 0, 1 if a >= b else 0)
