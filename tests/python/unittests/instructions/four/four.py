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
async def test_jal(dut):
    """Testa apenas JAL verificando PC_out e registrador de retorno."""

    # ====== Executa JAL ======
    dut.CLK.value = 1; await Timer(10, units="ns")  # executa JAL
    pc_before = int(dut.PC_out.value)  # PC onde JAL está
    dut.CLK.value = 0; await Timer(10, units="ns")

    dut.CLK.value = 1; await Timer(10, units="ns")
    pc_after = int(dut.PC_out.value)   # PC após salto

    # Cálculo esperado
    offset = sext(8, 21)  # imediato do JAL
    expected_pc = (pc_before + offset) & 0xFFFFFFFF
    expected_link = (pc_before + 4) & 0xFFFFFFFF

    # Verifica PC
    assert pc_after == expected_pc, f"JAL falhou: esperado PC={expected_pc:#010x}, obtido {pc_after:#010x}"
    dut._log.info(f"JAL OK: antes={pc_before:#010x}, depois={pc_after:#010x}")

    # ====== Executa ADD que expõe registrador de retorno (x6 = x5) ======
    # executa ADD saída da ALU com x6 = x5
    reg_val = int(dut.ALU_out.value)    
    dut.CLK.value = 0; await Timer(10, units="ns")     

    # EXECUTA JALR
    dut.CLK.value = 1; await Timer(10, units="ns")    
    dut.CLK.value = 0; await Timer(10, units="ns")   

    # ====== NOVA IMPLEMENTAÇÃO DO JALR ======
    dut.CLK.value = 1; await Timer(10, units="ns") 
    pc = int(dut.PC_out.value)

    # esperado: voltar para endereço salvo em x5 (reg_val), alinhado
    expected_jalr_pc = reg_val & ~1

    assert pc == expected_jalr_pc, f"JALR falhou: esperado PC={expected_jalr_pc:#010x}, obtido {pc:#010x}"
    dut._log.info(f"JALR OK: PC={pc:#010x}")

    # Verifica link register do JAL
    assert reg_val == expected_link, f"JAL link falhou: esperado {expected_link:#010x}, obtido {reg_val:#010x}"
    dut._log.info(f"JAL link OK: {reg_val:#010x}")
