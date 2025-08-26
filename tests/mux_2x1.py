import cocotb
from cocotb.triggers import Timer
import random

@cocotb.test()
async def test_mux_2x1(dut):
    """Testa o MUX 2x1 com seletor 0 e 1."""

    # O MUX foi definido com largura de 8 bits por padrão
    largura_dados = len(dut.entradaA_MUX)
    dut._log.info(f"Iniciando teste para MUX de {largura_dados} bits.")

    # Gera valores aleatórios para as entradas A e B
    valor_a = random.randint(0, 2**largura_dados - 1)
    valor_b = random.randint(0, 2**largura_dados - 1)
    
    dut.entradaA_MUX.value = valor_a
    dut.entradaB_MUX.value = valor_b

    # --- Caso de Teste 1: Seletor = 0 ---
    dut.seletor_MUX.value = 0
    await Timer(1, units="ns")  # Espera a propagação do sinal

    dut._log.info(f"Teste com seletor = 0. EntradaA={valor_a}, Saida={int(dut.saida_MUX.value)}")
    assert dut.saida_MUX.value == valor_a, f"Erro: com seletor=0, a saída deveria ser {valor_a}, mas foi {int(dut.saida_MUX.value)}"

    # --- Caso de Teste 2: Seletor = 1 ---
    dut.seletor_MUX.value = 1
    await Timer(1, units="ns")  # Espera a propagação do sinal

    dut._log.info(f"Teste com seletor = 1. EntradaB={valor_b}, Saida={int(dut.saida_MUX.value)}")
    assert dut.saida_MUX.value == valor_b, f"Erro: com seletor=1, a saída deveria ser {valor_b}, mas foi {int(dut.saida_MUX.value)}"

    dut._log.info("Teste do MUX 2x1 finalizado com sucesso!")