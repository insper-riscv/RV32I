import cocotb
from cocotb.triggers import Timer
import random

# --------- Helpers de formatação/log ----------
def _fmt_header():
    return f"{'Step':<5} | {'Sel':<3} | {'A':<12} | {'B':<12} | {'Saída':<12} | {'Esperado':<12}"

def _fmt_row(step, sel, a, b, y, exp):
    return f"{step:<5} | {sel:<3} | {a:<12} | {b:<12} | {y:<12} | {exp:<12}"

def _has_xz(val):
    try:
        s = val.binstr
    except Exception:
        return False
    return ('x' in s.lower()) or ('z' in s.lower())

def _sel_to_exp(sel, a, b):
    return b if sel else a

def _patterns(width):
    maxv = (1 << width) - 1
    bits = ''.join(('01' for _ in range((width + 1)//2)))[:width]
    p55 = int(bits[::-1], 2)
    pAA = p55 ^ maxv
    return maxv, p55 & maxv, pAA & maxv

# ============================================================
# 1) TESTE DETERMINÍSTICO
# ============================================================
@cocotb.test()
async def deterministico(dut):
    """Casos determinísticos para MUX 2x1: 0x00.., 0xFF.., padrões alternados, combinações extremas."""
    largura = len(dut.entradaA_MUX)
    maxv, p55, pAA = _patterns(largura)

    dut._log.info(f"Iniciando testes determinísticos para MUX 2x1 de {largura} bits.")
    dut._log.info(_fmt_header())

    casos = [
        (0,     0),
        (maxv,  maxv),
        (0,     maxv),
        (maxv,  0),
        (p55,   pAA),
        (pAA,   p55),
    ]

    step = 0
    for a, b in casos:
        for sel in (0, 1):
            dut.entradaA_MUX.value = a
            dut.entradaB_MUX.value = b
            dut.seletor_MUX.value  = sel
            await Timer(1, units="ns")

            if _has_xz(dut.saida_MUX.value):
                raise AssertionError(f"Saída com X/Z para sel={sel} A={a} B={b}")

            y   = int(dut.saida_MUX.value)
            exp = _sel_to_exp(sel, a, b)
            dut._log.info(_fmt_row(step, sel, a, b, y, exp))
            assert y == exp, f"(determinístico) sel={sel} A={a} B={b} -> esperado {exp}, obtido {y}"
            step += 1

# ============================================================
# 2) TESTE: COMUTAÇÃO APENAS DO SELETOR
# ============================================================
@cocotb.test()
async def toggle_seletor(dut):
    """Comuta somente o seletor com A/B fixos: saída deve alternar exatamente conforme o sel."""
    largura = len(dut.entradaA_MUX)
    maxv = (1 << largura) - 1
    random.seed(42)

    a = random.randint(0, maxv)
    b = random.randint(0, maxv)

    dut.entradaA_MUX.value = a
    dut.entradaB_MUX.value = b

    dut._log.info(f"Iniciando teste de comutação do seletor (entradas fixas) para MUX 2x1 de {largura} bits.")
    dut._log.info(_fmt_header())

    sequencia_sel = [0, 1, 1, 0, 0, 1, 0]

    step = 0
    for sel in sequencia_sel:
        dut.seletor_MUX.value = sel
        await Timer(1, units="ns")

        if _has_xz(dut.saida_MUX.value):
            raise AssertionError(f"Saída com X/Z para sel={sel} (A={a} B={b})")

        y   = int(dut.saida_MUX.value)
        exp = _sel_to_exp(sel, a, b)
        dut._log.info(_fmt_row(step, sel, a, b, y, exp))
        assert y == exp, f"(toggle seletor) sel={sel} A={a} B={b} -> esperado {exp}, obtido {y}"
        step += 1

# ============================================================
# 3) TESTE: TROCA SIMULTÂNEA
# ============================================================
@cocotb.test()
async def troca_simultanea(dut):
    """Troca simultânea de A/B e seletor (foco em stress de combinacional)."""
    largura = len(dut.entradaA_MUX)
    maxv = (1 << largura) - 1
    random.seed(123)

    dut._log.info(f"Iniciando teste de troca simultânea para MUX 2x1 de {largura} bits.")
    dut._log.info(_fmt_header())

    step = 0
    for _ in range(50):
        a   = random.randint(0, maxv)
        b   = random.randint(0, maxv)
        sel = random.randint(0, 1)

        dut.entradaA_MUX.value = a
        dut.entradaB_MUX.value = b
        dut.seletor_MUX.value  = sel

        await Timer(1, units="ns")

        if _has_xz(dut.saida_MUX.value):
            raise AssertionError(f"Saída com X/Z para sel={sel} A={a} B={b}")

        y   = int(dut.saida_MUX.value)
        exp = _sel_to_exp(sel, a, b)

        if step % 10 == 0:
            dut._log.info(_fmt_row(step, sel, a, b, y, exp))

        assert y == exp, f"(simultâneo) sel={sel} A={a} B={b} -> esperado {exp}, obtido {y}"
        step += 1
