import cocotb
from cocotb.triggers import Timer

def sext_20(imm):
    """Aplica extensão de sinal para 20 bits -> 32 bits."""
    imm20 = imm & 0xFFFFF
    if imm20 & (1 << 19):
        imm32 = imm20 | ~0xFFFFF
    else:
        imm32 = imm20
    return imm32

def lui_value(imm):
    return (sext_20(imm) << 12) & 0xFFFFFFFF

def auipc_value(pc, imm):
    return (pc + (sext_20(imm) << 12)) & 0xFFFFFFFF

@cocotb.test()
async def test_lui_auipc(dut):
    """Testa LUI e AUIPC em casos normais e limites."""
    # deixa a CPU rodar as instruções AUIPC
    for _ in range(7):
        dut.CLK.value = 1
        await Timer(10, units="ns")
        dut.CLK.value = 0
        await Timer(10, units="ns")

    # ==== CASOS DE AUIPC ====
    auipc_immediates = [
        0x00001,  # normal
        0x12345,  # normal
        0x54321,  # normal
        0x00000,  # limite inferior
        0x7FFFF,  # limite superior positivo
        0x80000,  # menor negativo
        0xFFFFF,  # -1
    ]
    # PC de cada AUIPC: começa em 4 * nº da instrução (simples modelo single-cycle)
    pcs = [i * 4 for i in range(len(auipc_immediates))]
    auipc_expected = [auipc_value(pc, imm) for pc, imm in zip(pcs, auipc_immediates)]

    for expected in auipc_expected:
        dut.CLK.value = 1
        await Timer(10, units="ns")
        got = int(dut.ALU_out.value)
        dut.CLK.value = 0
        await Timer(10, units="ns")
        assert got == expected, f"AUIPC falhou: esperado {expected:#010x}, obtido {got:#010x}"
        dut._log.info(f"AUIPC OK: {got:#010x}")

    # deixa a CPU rodar as instruções LUI iniciais
    for _ in range(7):
        dut.CLK.value = 1
        await Timer(10, units="ns")
        dut.CLK.value = 0
        await Timer(10, units="ns")

    # ==== CASOS DE LUI ====
    lui_immediates = [
        0x00001,  # normal
        0x12345,  # normal
        0x54321,  # normal
        0x00000,  # limite inferior
        0x7FFFF,  # limite superior positivo
        0x80000,  # menor negativo
        0xFFFFF,  # -1
    ]
    lui_expected = [lui_value(imm) for imm in lui_immediates]

    for expected in lui_expected:
        dut.CLK.value = 1
        await Timer(10, units="ns")
        got = int(dut.ALU_out.value)
        dut.CLK.value = 0
        await Timer(10, units="ns")
        assert got == expected, f"LUI falhou: esperado {expected:#010x}, obtido {got:#010x}"
        dut._log.info(f"LUI OK: {got:#010x}")


