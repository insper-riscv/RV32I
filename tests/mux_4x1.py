import cocotb
from cocotb.triggers import Timer
import random

# --------- Helpers de formatação/log ----------
def _fmt_header():
    return f"{'Step':<5} | {'Sel':<3} | {'A':<12} | {'B':<12} | {'C':<12} | {'D':<12} | {'Saída':<12} | {'Esperado':<12}"

def _fmt_row(step, sel, a, b, c, d, y, exp):
    return f"{step:<5} | {sel:<3} | {a:<12} | {b:<12} | {c:<12} | {d:<12} | {y:<12} | {exp:<12}"

def _has_xz(val):
    # Compatível com diferentes drivers do cocotb
    try:
        s = val.binstr
    except Exception:
        return False
    return ('x' in s.lower()) or ('z' in s.lower())

def _sel_to_exp(sel, a, b, c, d):
    return [a, b, c, d][sel & 0b11]

def _patterns(width):
    maxv = (1 << width) - 1
    # Gera 0x55.. e 0xAA.. do tamanho certo
    bits = ''.join(('01' for _ in range((width + 1)//2)))[:width]    # '0101...'
    p55 = int(bits[::-1], 2)  # ajuste para encaixar no width (poderia usar outra convenção)
    pAA = p55 ^ maxv
    return maxv, p55 & maxv, pAA & maxv

# ============================================================
# 1) TESTE DETERMINÍSTICO (bordas e padrões)
# ============================================================
@cocotb.test()
async def deterministico(dut):
    """Casos determinísticos para MUX 4x1: 0x00.., 0xFF.., padrões alternados, combinações extremas."""
    largura = len(dut.entradaA_MUX)
    maxv, p55, pAA = _patterns(largura)
    dut._log.info(f"Iniciando testes determinísticos para MUX 4x1 de {largura} bits.")
    dut._log.info(_fmt_header())

    casos = [
        # (A, B, C, D)
        (0,      0,      0,      0),
        (maxv,   maxv,   maxv,   maxv),
        (0,      maxv,   0,      maxv),
        (maxv,   0,      maxv,   0),
        (p55,    pAA,    p55,    pAA),
        (pAA,    p55,    pAA,    p55),
    ]

    step = 0
    for a, b, c, d in casos:
        # Varre todos os seletores 0..3
        for sel in (0, 1, 2, 3):
            dut.entradaA_MUX.value = a
            dut.entradaB_MUX.value = b
            dut.entradaC_MUX.value = c
            dut.entradaD_MUX.value = d
            dut.seletor_MUX.value  = sel
            await Timer(1, units="ns")

            if _has_xz(dut.saida_MUX.value):
                raise AssertionError(f"Saída com X/Z para sel={sel} A={a} B={b} C={c} D={d}")

            y   = int(dut.saida_MUX.value)
            exp = _sel_to_exp(sel, a, b, c, d)
            dut._log.info(_fmt_row(step, sel, a, b, c, d, y, exp))
            assert y == exp, f"(determinístico) sel={sel} A={a} B={b} C={c} D={d} -> esperado {exp}, obtido {y}"
            step += 1

# ============================================================
# 2) TESTE: COMUTAÇÃO APENAS DO SELETOR (entradas fixas)
# ============================================================
@cocotb.test()
async def toggle_seletor(dut):
    """Comuta somente o seletor com A/B/C/D fixos: saída deve alternar exatamente conforme o sel."""
    largura = len(dut.entradaA_MUX)
    maxv = (1 << largura) - 1
    random.seed(42)

    # Entradas fixas
    a = random.randint(0, maxv)
    b = random.randint(0, maxv)
    c = random.randint(0, maxv)
    d = random.randint(0, maxv)

    dut.entradaA_MUX.value = a
    dut.entradaB_MUX.value = b
    dut.entradaC_MUX.value = c
    dut.entradaD_MUX.value = d

    dut._log.info(f"Iniciando teste de comutação do seletor (entradas fixas) para MUX 4x1 de {largura} bits.")
    dut._log.info(_fmt_header())

    # Sequência que cobre várias alternâncias (pode ajustar como quiser)
    sequencia_sel = [0,1,2,3,  3,2,1,0,  0,2,1,3,  3,1,2,0]

    step = 0
    for sel in sequencia_sel:
        dut.seletor_MUX.value = sel
        await Timer(1, units="ns")

        if _has_xz(dut.saida_MUX.value):
            raise AssertionError(f"Saída com X/Z para sel={sel} (A={a} B={b} C={c} D={d})")

        y   = int(dut.saida_MUX.value)
        exp = _sel_to_exp(sel, a, b, c, d)
        dut._log.info(_fmt_row(step, sel, a, b, c, d, y, exp))
        assert y == exp, f"(toggle seletor) sel={sel} A={a} B={b} C={c} D={d} -> esperado {exp}, obtido {y}"
        step += 1

# ============================================================
# 3) TESTE: TROCA SIMULTÂNEA (entradas e seletor mudam juntos)
# ============================================================
@cocotb.test()
async def troca_simultanea(dut):
    """Troca simultânea de A/B/C/D e seletor (foco em stress de combinacional)."""
    largura = len(dut.entradaA_MUX)
    maxv = (1 << largura) - 1
    random.seed(123)

    dut._log.info(f"Iniciando teste de troca simultânea para MUX 4x1 de {largura} bits.")
    dut._log.info(_fmt_header())

    step = 0
    for _ in range(100):
        a   = random.randint(0, maxv)
        b   = random.randint(0, maxv)
        c   = random.randint(0, maxv)
        d   = random.randint(0, maxv)
        sel = random.randint(0, 3)

        dut.entradaA_MUX.value = a
        dut.entradaB_MUX.value = b
        dut.entradaC_MUX.value = c
        dut.entradaD_MUX.value = d
        dut.seletor_MUX.value  = sel

        await Timer(1, units="ns")

        if _has_xz(dut.saida_MUX.value):
            raise AssertionError(f"Saída com X/Z para sel={sel} A={a} B={b} C={c} D={d}")

        y   = int(dut.saida_MUX.value)
        exp = _sel_to_exp(sel, a, b, c, d)

        # Loga a cada 10 passos para não poluir demais
        if step % 10 == 0:
            dut._log.info(_fmt_row(step, sel, a, b, c, d, y, exp))

        assert y == exp, f"(simultâneo) sel={sel} A={a} B={b} C={c} D={d} -> esperado {exp}, obtido {y}"
        step += 1
