import cocotb
from cocotb.triggers import Timer

def sext(val, bits):
    mask = (1 << bits) - 1
    val &= mask
    if val & (1 << (bits - 1)):
        val -= (1 << bits)
    return val

@cocotb.test()
async def test_branches(dut):
    """Testa BEQ, BNE, BLT, BGE, BLTU, BGEU nas duas condições (satisfaz e não satisfaz)."""

    # offset usado nos branches = 8 bytes (2 instruções à frente)
    offset = sext(8, 13)

    dut.CLK.value = 0
    await Timer(10, units="ns")

    # Helper: executa uma instrução e retorna PC
    async def step():
        pc = int(dut.PC_IF_out.value)
        dut.CLK.value = 1; await Timer(5, units="ns")
        dut.CLK.value = 0; await Timer(10, units="ns")
        dut.CLK.value = 1; await Timer(10, units="ns")
        dut.CLK.value = 0; await Timer(10, units="ns")
        dut.CLK.value = 1; await Timer(10, units="ns")
        dut.CLK.value = 0; await Timer(10, units="ns")
        dut.CLK.value = 1; await Timer(5, units="ns")
        return pc

    await step() # x1 = 5
    await step() # x2 = 10

    # ====== BEQ ======
    pc_before = await step()  # beq x1,x2 (não salta)
    pc_after = await step()
    expected = (pc_before + 4) & 0xFFFFFFFF
    assert pc_after == expected, f"BEQ (não salta) falhou"

    pc_before = await step()  # beq  x1, x1, Lbeq2 (salta)
    pc_after = await step()
    expected = (pc_before + 8) & 0xFFFFFFFF
    assert pc_after == expected, f"BEQ (Salta) falhou"

    # ====== BNE ======
    pc_before = await step()  # bne x1,x2 (salta)
    pc_after = await step()
    expected = (pc_before + 8) & 0xFFFFFFFF
    assert pc_after == expected, f"BNE (salta) falhou"

    pc_before = await step()  # bne x1,x1 (não salta)
    pc_after = await step()
    expected = (pc_before + 4) & 0xFFFFFFFF
    assert pc_after == expected, f"BNE (não salta) falhou"

    # ====== BLT ======
    pc_before = await step()  # blt x1,x2 (salta)
    pc_after = await step()
    expected = (pc_before + 8) & 0xFFFFFFFF
    assert pc_after == expected, f"BLT (salta) falhou"

    pc_before = await step()  # blt x2,x1 (não salta)
    pc_after = await step()
    expected = (pc_before + 4) & 0xFFFFFFFF
    assert pc_after == expected, f"BLT (não salta) falhou"

    # ====== BGE ======
    pc_before = await step()  # bge x2,x1 (salta)
    pc_after = await step()
    expected = (pc_before + 8) & 0xFFFFFFFF
    assert pc_after == expected, f"BGE (salta) falhou"

    pc_before = await step()  # bge x1,x2 (não salta)
    pc_after = await step()
    expected = (pc_before + 4) & 0xFFFFFFFF
    assert pc_after == expected, f"BGE (não salta) falhou"

    # ====== BLTU ======
    pc_before = await step()  # bltu x1,x2 (salta)
    pc_after = await step()
    expected = (pc_before + 8) & 0xFFFFFFFF
    assert pc_after == expected, f"BLTU (salta) falhou"

    pc_before = await step()  # bltu x2,x1 (não salta)
    pc_after = await step()
    expected = (pc_before + 4) & 0xFFFFFFFF
    assert pc_after == (pc_before + 4) & 0xFFFFFFFF, f"BLTU (não salta) falhou"

    # ====== BGEU ======
    pc_before = await step()  # bgeu x2,x1 (salta)
    pc_after = await step()
    expected = (pc_before + 8) & 0xFFFFFFFF
    assert pc_after == expected, f"BGEU (salta) falhou"

    pc_before = await step()  # bgeu x1,x2 (não salta)
    pc_after = await step()
    expected = (pc_before + 4) & 0xFFFFFFFF
    assert pc_after == (pc_before + 4) & 0xFFFFFFFF, f"BGEU (não salta) falhou"

    dut._log.info("Todos os testes de branch passaram")