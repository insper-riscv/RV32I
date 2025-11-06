import cocotb
from cocotb.triggers import Timer

def sext(val, bits):
    """Extensão de sinal."""
    mask = (1 << bits) - 1
    val &= mask
    if val & (1 << (bits - 1)):
        val -= (1 << bits)
    return val

@cocotb.test()
async def test_i_type(dut):

    dut.CLK.value = 0
    await Timer(10, units="ns")

    async def step():
        for i in range (3):
            dut.CLK.value = 1
            await Timer(10, units="ns")
            dut.CLK.value = 0
            await Timer(10, units="ns")

    """Testa ADDI, XORI, ORI, ANDI, SLLI, SRLI, SRAI."""


    # Roda ciclos iniciais até os ADD que expõem resultados
    for _ in range(9):
        await step()

    # Valor base em x1 = 0x0000F0F0
    x1 = 0x0000F0F0

    expected = []
    expected.append((x1 + sext(0x10, 12)) & 0xFFFFFFFF)   # ADDI
    expected.append((x1 ^ sext(0xFF, 12)) & 0xFFFFFFFF)   # XORI
    expected.append((x1 | sext(0x0F0, 12)) & 0xFFFFFFFF)  # ORI
    expected.append((x1 & sext(0x0F0, 12)) & 0xFFFFFFFF)  # ANDI
    expected.append((x1 << 4) & 0xFFFFFFFF)               # SLLI
    expected.append((x1 >> 4) & 0xFFFFFFFF)               # SRLI (unsigned)
    expected.append((sext(x1, 32) >> 4) & 0xFFFFFFFF)     # SRAI (signed)

    # Verifica resultados um a um
    for instr, exp in zip(["ADDI","XORI","ORI","ANDI","SLLI","SRLI","SRAI"], expected):
        await step()
        got = int(dut.ALU_out_IDEXMEM.value)
        assert got == exp, f"{instr} falhou: esperado {exp:#010x}, obtido {got:#010x}"
        dut._log.info(f"{instr} OK: {got:#010x}")
