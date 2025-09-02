# tests/somadorGenerico.py
import cocotb
from cocotb.triggers import Timer
import random

# ---------- Helpers ----------
def _has_xz(sig) -> bool:
    try:
        s = sig.value.binstr
    except Exception:
        return False
    return ('x' in s.lower()) or ('z' in s.lower())

def _mask(width: int) -> int:
    return (1 << width) - 1 if width > 0 else 0

def _to_bin(v: int, w: int) -> str:
    return format(v & _mask(w), f"0{w}b")

def _fmt_header():
    return f"{'Step':<5} | {'A':>10} | {'B':>10} | {'Y':>10} | {'EXP':>10}"

def _fmt_row(i, a, b, y, exp):
    return f"{i:<5} | {a:>10} | {b:>10} | {y:>10} | {exp:>10}"

# ============================================================
# 1) TESTE DETERMINÍSTICO
# ============================================================
@cocotb.test()
async def deterministico(dut):
    """Casos determinísticos + overflow (wrap)."""
    w = len(dut.entradaA)
    m = _mask(w)

    dut._log.info(f"Iniciando determinístico para somador UNSIGNED de {w} bits")
    dut._log.info(_fmt_header())

    maxv = m
    p55 = int(('01' * ((w + 1)//2))[:w], 2)        # 0101...
    pAA = p55 ^ m                                   # 1010...

    casos = [
        (0, 0),
        (0, maxv),
        (maxv, 0),
        (maxv, 1),          # overflow -> 0
        (p55, pAA),         # soma deve dar 0xFF.. (tudo 1)
        (1, 2),
        (123 & m, 45 & m),
    ]

    for i, (a, b) in enumerate(casos):
        dut.entradaA.value = a
        dut.entradaB.value = b
        await Timer(1, units="ns")

        assert not _has_xz(dut.saida), "Saída contém X/Z"

        y   = int(dut.saida.value)
        exp = (a + b) & m

        dut._log.info(_fmt_row(i, a, b, y, exp))
        assert y == exp, (
            f"(det) w={w} A=0b{_to_bin(a,w)} B=0b{_to_bin(b,w)} "
            f"-> Y=0b{_to_bin(y,w)}, esperado 0b{_to_bin(exp,w)}"
        )

# ============================================================
# 2) PROPRIEDADE: COMUTATIVIDADE
# ============================================================
@cocotb.test()
async def comutatividade(dut):
    """Verifica A+B == B+A (mod 2^w) para vários valores."""
    w = len(dut.entradaA)
    m = _mask(w)

    random.seed(2025)
    N = 64

    for i in range(N):
        a = random.getrandbits(w)
        b = random.getrandbits(w)

        # A+B
        dut.entradaA.value = a
        dut.entradaB.value = b
        await Timer(1, units="ns")
        y1 = int(dut.saida.value) & m

        # B+A
        dut.entradaA.value = b
        dut.entradaB.value = a
        await Timer(1, units="ns")
        y2 = int(dut.saida.value) & m

        assert y1 == y2 == ((a + b) & m), (
            f"(comutatividade) w={w} a={a} b={b} -> "
            f"A+B={y1}, B+A={y2}, exp={((a+b)&m)}"
        )

# ============================================================
# 3) FUZZ / OVERFLOW
# ============================================================
@cocotb.test()
async def fuzz_overflow(dut):
    """Fuzz aleatório: checa wrap-around unsigned."""
    w = len(dut.entradaA)
    m = _mask(w)

    random.seed(4242)
    N = 200

    for _ in range(N):
        a = random.getrandbits(w)
        b = random.getrandbits(w)

        dut.entradaA.value = a
        dut.entradaB.value = b
        await Timer(1, units="ns")

        y = int(dut.saida.value)
        exp = (a + b) & m
        assert y == exp, (
            f"(fuzz) w={w} A=0b{_to_bin(a,w)} B=0b{_to_bin(b,w)} "
            f"-> Y=0b{_to_bin(y,w)}, exp=0b{_to_bin(exp,w)}"
        )

@cocotb.test()
async def overflow_unsigned(dut):
    """Valida overflow (carry) de soma UNSIGNED via propriedades matemáticas."""

    w = len(dut.entradaA)
    mask = (1 << w) - 1

    random.seed(1337)
    N = 200

    for _ in range(N):
        a = random.getrandbits(w)
        b = random.getrandbits(w)

        dut.entradaA.value = a
        dut.entradaB.value = b
        await Timer(1, units="ns")

        y = int(dut.saida.value) & mask
        sum_big = a + b
        exp = sum_big & mask
        carry = 1 if (sum_big >> w) else 0

        # 1) Saída deve bater com o wrap
        assert y == exp, f"(wrap) w={w} a={a} b={b} -> y={y}, exp={exp}"

        # 2) Propriedades de overflow (unsigned)
        # carry <=> houve wrap; wrap <=> resultado final é menor que A e também menor que B quando ambos contribuem
        assert (carry == (exp < a)) or (a == 0), \
            f"(carry vs exp<a) w={w} a={a} b={b} y={y} carry={carry}"

        assert (carry == (exp < b)) or (b == 0), \
            f"(carry vs exp<b) w={w} a={a} b={b} y={y} carry={carry}"

        # 3) Limite superior
        assert carry == int(sum_big >= (1 << w)), \
            f"(carry limiar) w={w} a={a} b={b} sum={sum_big} carry={carry}"
