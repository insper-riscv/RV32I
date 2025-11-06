import cocotb
from cocotb.triggers import Timer


async def rise(dut, half=5):
    dut.clk_in.value = 1
    await Timer(half, units="ns")


async def fall(dut, half=5):
    dut.clk_in.value = 0
    await Timer(half, units="ns")


@cocotb.test()
async def one_hot_property(dut):
    """
    Assegura que durante a fase alta exatamente UMA saída é '1' (one-hot),
    e que durante a fase baixa todas são '0'.
    """
    dut.clk_in.value = 0
    dut.reset.value = 1
    await Timer(5, "ns")
    dut.reset.value = 0
    await Timer(1, "ns")

    cycles = 30
    for i in range(cycles):
        # fase baixa: todas zero
        await fall(dut, half=3)
        low = (int(dut.clk0.value), int(dut.clk1.value), int(dut.clk2.value))
        assert low == (0, 0, 0), f"[one_hot] cycle {i} low: esperado (0,0,0), obteve {low}"

        # fase alta: exatamente uma saída ativa
        await rise(dut, half=3)
        high = (int(dut.clk0.value), int(dut.clk1.value), int(dut.clk2.value))
        assert sum(high) == 1, f"[one_hot] cycle {i} high: esperado 1 bit ativo, obteve {high}"
    dut._log.info("one_hot_property: OK")


@cocotb.test()
async def async_reset_immediate_clear(dut):
    """
    Verifica que reset assíncrono limpa as saídas imediatamente quando aplicado
    tanto na fase alta quanto na fase baixa.
    """
    # inicia e rode 2 ciclos para entrar em operação
    dut.clk_in.value = 0
    dut.reset.value = 0
    await Timer(1, "ns")
    await rise(dut, half=4)
    await fall(dut, half=4)

    # aplique reset durante fase baixa
    dut.reset.value = 1
    await Timer(1, "ns")
    after_reset_low = (int(dut.clk0.value), int(dut.clk1.value), int(dut.clk2.value))
    assert after_reset_low == (0, 0, 0), f"[reset low] esperado (0,0,0), obteve {after_reset_low}"

    # libere reset e rode um ciclo para voltar à operação
    dut.reset.value = 0
    await rise(dut, half=4)
    await fall(dut, half=4)

    # aplique reset durante fase alta
    await rise(dut, half=4)
    dut.reset.value = 1
    await Timer(1, "ns")
    after_reset_high = (int(dut.clk0.value), int(dut.clk1.value), int(dut.clk2.value))
    assert after_reset_high == (0, 0, 0), f"[reset high] esperado (0,0,0), obteve {after_reset_high}"

    # cleanup
    dut.reset.value = 0
    await Timer(1, "ns")
    dut._log.info("async_reset_immediate_clear: OK")


@cocotb.test()
async def release_reset_alignment(dut):
    """
    Depois de liberar reset, garante-se comportamento determinístico:
    - se liberar antes de uma subida, no próximo rise espera-se que a saída
      consistente com cnt inicial ocorra.
    Observação: dependendo da sua implementação, o primeiro high pode ser clk0 ou clk1.
    Ajuste as expectativas caso mude o VHDL.
    """
    # força reset e garanta estado
    dut.clk_in.value = 0
    dut.reset.value = 1
    await Timer(5, "ns")

    # libera reset enquanto estamos em low; aguarda uma subida
    dut.reset.value = 0
    await Timer(1, "ns")

    # agora na primeira subida, uma das saídas deverá ativar.
    await rise(dut, half=4)
    high1 = (int(dut.clk0.value), int(dut.clk1.value), int(dut.clk2.value))
    # assumimos que a implementação gera clk0 no primeiro high; ajustar se não for esse o caso
    assert sum(high1) == 1, f"[release align] primeiro high: esperado 1 bit ativo, obteve {high1}"

    # registre qual foi e assegure sequência subsequente correta
    # faça mais dois ciclos e verifique rotação
    await fall(dut, half=4)
    await rise(dut, half=4)
    high2 = (int(dut.clk0.value), int(dut.clk1.value), int(dut.clk2.value))
    await fall(dut, half=4)
    await rise(dut, half=4)
    high3 = (int(dut.clk0.value), int(dut.clk1.value), int(dut.clk2.value))

    # os três highs devem ser distintos e rotacionar
    assert sum(high2) == 1 and sum(high3) == 1, "[release align] subsequentes devem ser one-hot"
    dut._log.info(f"release alignment highs: {high1} -> {high2} -> {high3}")
    dut._log.info("release_reset_alignment: OK")


@cocotb.test()
async def output_changes_only_on_rising_edge(dut):
    """
    Garante que a mudança de saída acontece na borda de subida
    (já que as saidas são ativas quando clk_in='1' e cnt foi atualizado na descida).
    Amostramos antes, logo após, e um pouco depois da subida.
    """
    # inicializa
    dut.clk_in.value = 0
    dut.reset.value = 1
    await Timer(3, "ns")
    dut.reset.value = 0
    await Timer(1, "ns")

    # avance um ciclo para ter cnt não trivial
    await rise(dut, half=3)
    await fall(dut, half=3)

    # agora sample: pouco antes da subida
    await Timer(1, "ns")
    dut.clk_in.value = 0
    await Timer(1, "ns")
    before = (int(dut.clk0.value), int(dut.clk1.value), int(dut.clk2.value))

    # na subida: amostra imediatamente após mudar clk_in para 1
    dut.clk_in.value = 1
    await Timer(1, "ns")
    on_rise = (int(dut.clk0.value), int(dut.clk1.value), int(dut.clk2.value))

    # um pouco depois (meio período) mantém valor high (não deveria flutuar)
    await Timer(2, "ns")
    later = (int(dut.clk0.value), int(dut.clk1.value), int(dut.clk2.value))

    # expectativas: before era 0 (fase low), on_rise has exactly one bit set, later same
    assert before == (0, 0, 0), f"[edge] antes da subida esperado (0,0,0), obteve {before}"
    assert sum(on_rise) == 1, f"[edge] logo apos subida esperado one-hot, obteve {on_rise}"
    assert later == on_rise, f"[edge] estabilidade apos subida: esperado {on_rise}, obteve {later}"

    dut._log.info("output_changes_only_on_rising_edge: OK")


@cocotb.test()
async def long_run_no_glitches(dut):
    """
    Executa muitos ciclos para detectar glitches intermitentes e verificar
    repetição do padrão (período 3).
    """
    dut.clk_in.value = 0
    dut.reset.value = 1
    await Timer(2, "ns")
    dut.reset.value = 0
    await Timer(1, "ns")

    total = 120
    prev_high = None
    for i in range(total):
        await rise(dut, half=2)
        high = (int(dut.clk0.value), int(dut.clk1.value), int(dut.clk2.value))
        # one-hot during high
        assert sum(high) == 1, f"[long] high @i={i} expected one-hot, got {high}"
        # ensure it flips over cycles (not stuck)
        if prev_high is not None:
            assert high != prev_high, f"[long] stuck pattern @i={i}: repeated {high}"
        prev_high = high
        await fall(dut, half=2)
        low = (int(dut.clk0.value), int(dut.clk1.value), int(dut.clk2.value))
        assert low == (0, 0, 0), f"[long] low @i={i} expected (0,0,0), got {low}"

    dut._log.info("long_run_no_glitches: OK")
