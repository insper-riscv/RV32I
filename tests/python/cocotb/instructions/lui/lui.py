import cocotb
from cocotb.triggers import Timer

def lui_value(imm):
    imm20 = imm & 0xFFFFF
    # extensão de sinal para 32 bits
    if imm20 & (1 << 19):
        imm32 = imm20 | ~0xFFFFF
    else:
        imm32 = imm20
    return (imm32 << 12) & 0xFFFFFFFF

@cocotb.test()
async def test_lui_limits(dut):
    """Testa LUI em casos normais e de limite do imediato."""

    for _ in range(8):
        dut.CLK.value = 1
        await Timer(10, units="ns")
        dut.CLK.value = 0
        await Timer(10, units="ns")

    immediates = [
        0x00000,  # Escrever em x0 não deve mudar o valor.
        0x00001,  # normal 
        0x12345,  # normal
        0x54321,  # normal
        0x00000,  # limite inferior
        0x7FFFF,  # limite superior positivo
        0x80000,  # menor negativo
        0xFFFFF,  # -1
    ]

    expected_values = [lui_value(imm) for imm in immediates]

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
