import cocotb
from cocotb.triggers import Timer

def sext(val, bits):
    """Extensão de sinal para 'bits' -> 32 bits."""
    mask = (1 << bits) - 1
    val &= mask
    if val & (1 << (bits - 1)):
        val -= (1 << bits)
    return val

@cocotb.test()
async def test_r_type_example(dut):
    """Testa ADD, SUB, XOR, OR, AND, SLL, SRL, SRA, SLT, SLTU com base no .S fornecido."""

    # Deixa rodar até depois do carregamento de x1 e x2
    # (li x1, ... ; li x2, ...) → 2 instruções + saltos iniciais
    for _ in range(4):
        dut.CLK.value = 1; await Timer(10, units="ns")
        dut.CLK.value = 0; await Timer(10, units="ns")

    # Valores carregados no .S
    rs1 = 0x00000001
    rs2 = 0x7FFFFFFF

    # Resultados esperados
    expected = []
    expected.append((rs1 + rs2) & 0xFFFFFFFF)                         # ADD
    expected.append((rs1 - rs2) & 0xFFFFFFFF)                         # SUB
    expected.append((rs1 ^ rs2) & 0xFFFFFFFF)                         # XOR
    expected.append((rs1 | rs2) & 0xFFFFFFFF)                         # OR
    expected.append((rs1 & rs2) & 0xFFFFFFFF)                         # AND
    expected.append((rs1 << (rs2 & 0x1F)) & 0xFFFFFFFF)               # SLL
    expected.append((rs1 >> (rs2 & 0x1F)) & 0xFFFFFFFF)               # SRL
    expected.append((sext(rs1,32) >> (rs2 & 0x1F)) & 0xFFFFFFFF)      # SRA
    expected.append(1 if sext(rs1,32) < sext(rs2,32) else 0)          # SLT
    expected.append(1 if (rs1 & 0xFFFFFFFF) < (rs2 & 0xFFFFFFFF) else 0)  # SLTU

    instrs = ["ADD","SUB","XOR","OR","AND","SLL","SRL","SRA","SLT","SLTU"]

    # Agora cada clock corresponde a uma instrução R-type
    for instr, exp in zip(instrs, expected):
        dut.CLK.value = 1; await Timer(10, units="ns")
        got = int(dut.ALU_out.value)
        dut.CLK.value = 0; await Timer(10, units="ns")

        assert got == exp, f"{instr} falhou: esperado {exp:#010x}, obtido {got:#010x}"
        dut._log.info(f"{instr} OK: {got:#010x}")
