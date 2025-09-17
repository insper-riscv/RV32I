import cocotb
from cocotb.triggers import Timer

def auipc_value(pc, imm):
    imm20 = imm & 0xFFFFF
    # extensão de sinal para 32 bits
    if imm20 & (1 << 19):
        imm32 = imm20 | ~0xFFFFF
    else:
        imm32 = imm20
    return (pc + (imm32 << 12)) & 0xFFFFFFFF

@cocotb.test()
async def test_auipc_limits(dut):
    """Testa AUIPC em casos normais e de limite do imediato."""

    # roda ciclos iniciais para execução das instruções
    for _ in range(8):
        dut.CLK.value = 1
        await Timer(10, units="ns")
        dut.CLK.value = 0
        await Timer(10, units="ns")

    immediates = [
        0x00000,  # escrita em x0 deve dar zero
        0x00001,  # normal
        0x12345,  # normal
        0x54321,  # normal
        0x00000,  # limite inferior
        0x7FFFF,  # limite superior positivo
        0x80000,  # menor negativo
        0xFFFFF,  # -1
    ]

    # PC inicial = 0x0, instruções de 4 bytes
    base_pc = 0
    pcs = [base_pc + i*4 for i in range(len(immediates))]

    expected_values = [auipc_value(pc, imm) for pc, imm in zip(pcs, immediates)]

    for expected in expected_values:
        dut.CLK.value = 1
        await Timer(10, units="ns")
        got = int(dut.ALU_out.value)
        dut.CLK.value = 0
        await Timer(10, units="ns")

        assert got == expected, (
            f"Falhou: esperado {expected:#010x}, obtido {got:#010x}"
        )
        dut._log.info(f"OK: {got:#010x}")
