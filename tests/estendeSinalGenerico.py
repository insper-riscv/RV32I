import cocotb
from cocotb.triggers import Timer
import random

# ---------- Helpers ----------
def _to_bin(value: int, width: int) -> str:
    return format(value & ((1 << width) - 1), f"0{width}b")

def _has_xz(val) -> bool:
    try:
        s = val.binstr
    except Exception:
        return False
    return ('x' in s.lower()) or ('z' in s.lower())

def _expected_sign_extend(val_in: int, win: int, wout: int) -> int:
    """Calcula a saída esperada: extensão de sinal de win -> wout (bit MSB replicado)."""
    sign = (val_in >> (win - 1)) & 1
    upper = 0 if sign == 0 else ((1 << (wout - win)) - 1)
    return (upper << win) | (val_in & ((1 << win) - 1))

def _check_bits(dut, val_in: int, val_out: int, win: int, wout: int):
    """Checa: parte baixa igual à entrada; parte alta toda = bit de sinal."""
    sign = (val_in >> (win - 1)) & 1
    lower = val_out & ((1 << win) - 1)
    upper = val_out >> win
    assert lower == (val_in & ((1 << win) - 1)), (
        f"Lower difere: in={_to_bin(val_in, win)} out.lower={_to_bin(lower, win)}"
    )
    if wout > win:
        if sign == 0:
            assert upper == 0, f"Upper deveria ser 0...0, mas foi {upper:#x}"
        else:
            assert upper == ((1 << (wout - win)) - 1), f"Upper deveria ser 1...1, mas foi {upper:#x}"

def _fmt_header(win: int, wout: int):
    return f"{'Step':<5} | {'IN(bin)':<{win+2}} | {'OUT(bin)':<{wout+2}} | {'EXP(bin)':<{wout+2}}"

def _fmt_row(step: int, vin_b: str, vout_b: str, exp_b: str, win: int, wout: int):
    return f"{step:<5} | {vin_b:<{win+2}} | {vout_b:<{wout+2}} | {exp_b:<{wout+2}}"


# ============================================================
# 1) TESTE DETERMINÍSTICO (bordas e padrões)
# ============================================================
@cocotb.test()
async def deterministico(dut):
    """Casos determinísticos: 0, max, ao redor do bit de sinal, padrões alternados (0x55.. / 0xAA..)."""
    win  = len(dut.estendeSinal_IN)
    wout = len(dut.estendeSinal_OUT)
    assert wout >= win, "larguraDadoSaida deve ser >= larguraDadoEntrada"

    max_in = (1 << win) - 1
    sign_bit = 1 << (win - 1)

    # padrões alternados (com o tamanho exato de win bits)
    p01_str = ('01' * ((win + 1) // 2))[:win]      # 0101...
    p55 = int(p01_str, 2)
    pAA = p55 ^ max_in

    casos = [
        0,
        max_in,
        sign_bit - 1,               # maior valor com bit de sinal = 0
        sign_bit,                   # menor valor com bit de sinal = 1
        p55,
        pAA,
        1,                          # valor pequeno
        max_in - 1,                 # logo abaixo do max
    ]

    dut._log.info(f"Iniciando determinístico: IN={win} bits, OUT={wout} bits")
    dut._log.info(_fmt_header(win, wout))

    step = 0
    for val_in in casos:
        dut.estendeSinal_IN.value = val_in
        await Timer(1, units="ns")

        assert not _has_xz(dut.estendeSinal_OUT.value), "Saída contém X/Z"

        out_int = int(dut.estendeSinal_OUT.value)
        exp_int = _expected_sign_extend(val_in, win, wout)

        vin_b  = "0b" + _to_bin(val_in, win)
        vout_b = "0b" + _to_bin(out_int, wout)
        exp_b  = "0b" + _to_bin(exp_int, wout)

        dut._log.info(_fmt_row(step, vin_b, vout_b, exp_b, win, wout))

        assert out_int == exp_int, (
            f"Extensão incorreta: IN={vin_b} -> OUT={vout_b}, esperado {exp_b}"
        )
        _check_bits(dut, val_in, out_int, win, wout)
        step += 1


# ============================================================
# 2) TESTE: COMUTAÇÃO APENAS DO BIT DE SINAL (variando sinal)
# ============================================================
@cocotb.test()
async def toggle_sign(dut):
    """Mantém parte baixa pseudo-aleatória e alterna o bit de sinal (0↔1) para verificar a replicação no upper."""
    win  = len(dut.estendeSinal_IN)
    wout = len(dut.estendeSinal_OUT)
    assert wout >= win, "larguraDadoSaida deve ser >= larguraDadoEntrada"

    random.seed(42)
    lower_mask = (1 << (win - 1)) - 1 if win > 1 else 0

    dut._log.info(f"Iniciando toggle do bit de sinal: IN={win} bits, OUT={wout} bits")
    dut._log.info(_fmt_header(win, wout))

    step = 0
    for _ in range(16):
        lower = random.randint(0, lower_mask) if lower_mask else 0

        # força sinal=0
        val0 = lower  # MSB=0
        dut.estendeSinal_IN.value = val0
        await Timer(1, units="ns")
        out0 = int(dut.estendeSinal_OUT.value)
        exp0 = _expected_sign_extend(val0, win, wout)
        dut._log.info(_fmt_row(
            step,
            "0b"+_to_bin(val0, win),
            "0b"+_to_bin(out0, wout),
            "0b"+_to_bin(exp0, wout),
            win, wout
        ))
        assert out0 == exp0
        _check_bits(dut, val0, out0, win, wout)
        step += 1

        # força sinal=1 (liga o MSB)
        val1 = (1 << (win - 1)) | lower if win > 1 else 1
        dut.estendeSinal_IN.value = val1
        await Timer(1, units="ns")
        out1 = int(dut.estendeSinal_OUT.value)
        exp1 = _expected_sign_extend(val1, win, wout)
        dut._log.info(_fmt_row(
            step,
            "0b"+_to_bin(val1, win),
            "0b"+_to_bin(out1, wout),
            "0b"+_to_bin(exp1, wout),
            win, wout
        ))
        assert out1 == exp1
        _check_bits(dut, val1, out1, win, wout)
        step += 1


# ============================================================
# 3) TESTE: FUZZ (valores aleatórios)
# ============================================================
@cocotb.test()
async def fuzz(dut):
    """Fuzz aleatório: compara saída com a extensão de sinal calculada em software."""
    win  = len(dut.estendeSinal_IN)
    wout = len(dut.estendeSinal_OUT)
    assert wout >= win, "larguraDadoSaida deve ser >= larguraDadoEntrada"

    random.seed(123)
    max_in = (1 << win) - 1

    dut._log.info(f"Iniciando fuzz: IN={win} bits, OUT={wout} bits")
    dut._log.info(_fmt_header(win, wout))

    step = 0
    for i in range(200):
        val_in = random.randint(0, max_in)

        dut.estendeSinal_IN.value = val_in
        await Timer(1, units="ns")

        assert not _has_xz(dut.estendeSinal_OUT.value), "Saída contém X/Z"

        out_int = int(dut.estendeSinal_OUT.value)
        exp_int = _expected_sign_extend(val_in, win, wout)

        # loga a cada 20 passos para não poluir
        if i % 20 == 0:
            dut._log.info(_fmt_row(
                step,
                "0b"+_to_bin(val_in, win),
                "0b"+_to_bin(out_int, wout),
                "0b"+_to_bin(exp_int, wout),
                win, wout
            ))

        assert out_int == exp_int, (
            f"(fuzz) IN=0b{_to_bin(val_in, win)} -> OUT=0b{_to_bin(out_int, wout)}, esperado 0b{_to_bin(exp_int, wout)}"
        )
        _check_bits(dut, val_in, out_int, win, wout)
        step += 1
