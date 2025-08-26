# tests/test_ula.py
import cocotb
from cocotb.triggers import Timer
import random

# Helper para simular o comportamento de 32 bits (two's complement) do Python
def to_32_bit_signed(n):
    """Converte um inteiro Python para seu equivalente em 32-bit com sinal."""
    n = n & 0xFFFFFFFF
    if n & 0x80000000:
        return n - 0x100000000
    return n

async def run_ula_op(dut, op_code, a, b):
    """Função auxiliar para configurar e rodar uma operação da ULA."""
    dut.op_ULA.value = op_code
    dut.entradaA.value = a
    dut.entradaB.value = b
    await Timer(1, units="ns")  # Espera para a lógica combinacional propagar

# --- Testes ---

@cocotb.test()
async def test_ula_soma(dut):
    """Testa a operação de SOMA (op_ULA = 0010)"""
    dut._log.info("Iniciando teste de SOMA")
    op_soma = 0b0010
    
    a = 150
    b = 50
    resultado_esperado = a + b

    await run_ula_op(dut, op_soma, a, b)
    
    resultado_obtido = dut.resultado.value.signed_integer
    dut._log.info(f"SOMA: {a} + {b} = {resultado_obtido} (Esperado: {resultado_esperado})")
    assert resultado_obtido == resultado_esperado

@cocotb.test()
async def test_ula_subtracao(dut):
    """Testa a operação de SUBTRAÇÃO (op_ULA = 0110)"""
    dut._log.info("Iniciando teste de SUBTRAÇÃO")
    op_sub = 0b0110
    
    a = 100
    b = 75
    resultado_esperado = a - b

    await run_ula_op(dut, op_sub, a, b)
    
    resultado_obtido = dut.resultado.value.signed_integer
    dut._log.info(f"SUB: {a} - {b} = {resultado_obtido} (Esperado: {resultado_esperado})")
    assert resultado_obtido == resultado_esperado

@cocotb.test()
async def test_ula_and(dut):
    """Testa a operação AND (op_ULA = 0000)"""
    dut._log.info("Iniciando teste de AND")
    op_and = 0b0000
    
    a = 0b1100
    b = 0b1010
    resultado_esperado = a & b

    await run_ula_op(dut, op_and, a, b)
    
    resultado_obtido = dut.resultado.value.integer
    dut._log.info(f"AND: {bin(a)} & {bin(b)} = {bin(resultado_obtido)} (Esperado: {bin(resultado_esperado)})")
    assert resultado_obtido == resultado_esperado

@cocotb.test()
async def test_ula_or(dut):
    """Testa a operação OR (op_ULA = 0001)"""
    dut._log.info("Iniciando teste de OR")
    op_or = 0b0001
    
    a = 0b1100
    b = 0b1010
    resultado_esperado = a | b

    await run_ula_op(dut, op_or, a, b)
    
    resultado_obtido = dut.resultado.value.integer
    dut._log.info(f"OR: {bin(a)} | {bin(b)} = {bin(resultado_obtido)} (Esperado: {bin(resultado_esperado)})")
    assert resultado_obtido == resultado_esperado

@cocotb.test()
async def test_ula_slt(dut):
    """Testa a operação SLT (Set on Less Than) (op_ULA = 0111)"""
    dut._log.info("Iniciando teste de SLT")
    op_slt = 0b0111
    
    # Caso 1: a < b deve resultar em 1
    a = -10
    b = 20
    await run_ula_op(dut, op_slt, a, b)
    resultado_obtido = dut.resultado.value.integer
    dut._log.info(f"SLT: {a} < {b} -> {resultado_obtido} (Esperado: 1)")
    assert resultado_obtido == 1
    
    # Caso 2: a > b deve resultar em 0
    a = 30
    b = 15
    await run_ula_op(dut, op_slt, a, b)
    resultado_obtido = dut.resultado.value.integer
    dut._log.info(f"SLT: {a} < {b} -> {resultado_obtido} (Esperado: 0)")
    assert resultado_obtido == 0

@cocotb.test()
async def test_ula_flag_zero(dut):
    """Testa a flagZero"""
    dut._log.info("Iniciando teste da flagZero")
    
    # Teste com resultado zero
    a = 50
    b = 50
    await run_ula_op(dut, 0b0110, a, b) # Subtração: 50 - 50 = 0
    dut._log.info(f"FLAG ZERO: {a} - {b} -> flagZero = {int(dut.flagZero.value)}")
    assert dut.flagZero.value == 1
    
    # Teste com resultado diferente de zero
    a = 50
    b = 49
    await run_ula_op(dut, 0b0110, a, b) # Subtração: 50 - 49 = 1
    dut._log.info(f"FLAG ZERO: {a} - {b} -> flagZero = {int(dut.flagZero.value)}")
    assert dut.flagZero.value == 0