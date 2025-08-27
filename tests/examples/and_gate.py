# tests/test_and_gate.py
import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_and_0_0(dut):
    """Testa a porta AND com entradas A=0 e B=0."""
    a = 0
    b = 0
    resultado_esperado = 0
    
    #dut._log.info(f"Testando entrada A={a}, B={b}")
    
    dut.source_a.value = a
    dut.source_b.value = b
    
    await Timer(1, "ns")
    
    assert dut.ouput.value == resultado_esperado, f"Resultado foi {int(dut.ouput.value)} mas o esperado era {resultado_esperado}"

@cocotb.test()
async def test_and_0_1(dut):
    """Testa a porta AND com entradas A=0 e B=1."""
    a = 0
    b = 1
    resultado_esperado = 0
    
    #dut._log.info(f"Testando entrada A={a}, B={b}")
    
    dut.source_a.value = a
    dut.source_b.value = b
    
    await Timer(1, "ns")
    
    assert dut.ouput.value == resultado_esperado, f"Resultado foi {int(dut.ouput.value)} mas o esperado era {resultado_esperado}"

@cocotb.test()
async def test_and_1_0(dut):
    """Testa a porta AND com entradas A=1 e B=0."""
    a = 1
    b = 0
    resultado_esperado = 0
    
    #dut._log.info(f"Testando entrada A={a}, B={b}")
    
    dut.source_a.value = a
    dut.source_b.value = b
    
    await Timer(1, "ns")
    
    assert dut.ouput.value == resultado_esperado, f"Resultado foi {int(dut.ouput.value)} mas o esperado era {resultado_esperado}"

@cocotb.test()
async def test_and_1_1(dut):
    """Testa a porta AND com entradas A=1 e B=1."""
    a = 1
    b = 1
    resultado_esperado = 1
    
    #dut._log.info(f"Testando entrada A={a}, B={b}")
    
    dut.source_a.value = a
    dut.source_b.value = b
    
    await Timer(1, "ns")
    
    assert dut.ouput.value == resultado_esperado, f"Resultado foi {int(dut.ouput.value)} mas o esperado era {resultado_esperado}"