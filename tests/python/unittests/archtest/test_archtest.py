import os
import json
import pathlib
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# Forçar falha sintética para checar contador/infra
# para testar, rode com "ARCHTEST_FORCE_FAIL=1 make compliance-one TEST=..." (ou so make compliance com essa var)
_FORCE_FAIL = os.getenv("ARCHTEST_FORCE_FAIL", "0") == "1"

# ===================== Parâmetros via ambiente =====================
CLK_PERIOD_NS     = float(os.getenv("ARCHTEST_CLK_NS", "10"))         # 100 MHz
WATCHDOG_MAX      = int(os.getenv("ARCHTEST_MAX_CYCLES", "200000"))   # timeout de polling
POST_HIT_WAIT     = int(os.getenv("ARCHTEST_POST_HIT_WAIT", "2"))
PASS_CODE         = int(os.getenv("ARCHTEST_PASS_CODE", "1"))
ARCHTEST_WAIT_PC  = os.getenv("ARCHTEST_WAIT_PC", "0") == "1"         # off por padrão

# ===================== Helpers opcionais (RAM/ROM) =====================
def _try_import_helpers():
    helpers = {}
    for modpath in [
        "tests.python.unittests.entities.utils",
        "tests.python.unittests.entities.RAM",
        "tests.python.unittests.entities.ROM",
    ]:
        try:
            mod = __import__(modpath, fromlist=["*"])
            if hasattr(mod, "load_hex_into_imem"):
                helpers["load_hex"] = getattr(mod, "load_hex_into_imem")
            if hasattr(mod, "read_mem_range"):
                helpers["read_mem_range"] = getattr(mod, "read_mem_range")
            if hasattr(mod, "read32"):
                helpers["read_word32"] = getattr(mod, "read32")
        except Exception:
            pass
    return helpers

def _detect_clk(dut):
    return getattr(dut, "clk", None) or getattr(dut, "CLK", None)

def _detect_pc_signal(dut):
    for name in ["PC_out", "pc", "PC", "pc_q", "pc_reg", "if_pc", "pc_current"]:
        if hasattr(dut, name):
            return getattr(dut, name)
    return None

async def _apply_reset(dut):
    clk = _detect_clk(dut)
    rst_n = getattr(dut, "reset_n", None)
    rst   = getattr(dut, "reset", None)

    if rst_n is not None:
        rst_n.value = 0
        for _ in range(5 if clk is not None else 0):
            await RisingEdge(clk)
        rst_n.value = 1
        for _ in range(2 if clk is not None else 0):
            await RisingEdge(clk)
        if clk is None:
            await Timer(20, units="ns")
        return

    if rst is not None:
        rst.value = 1
        for _ in range(5 if clk is not None else 0):
            await RisingEdge(clk)
        rst.value = 0
        for _ in range(2 if clk is not None else 0):
            await RisingEdge(clk)
        if clk is None:
            await Timer(20, units="ns")
        return

    # Sem reset explícito
    if clk is not None:
        for _ in range(5):
            await RisingEdge(clk)
    else:
        await Timer(100, units="ns")

def _save_signature(out_path: pathlib.Path, data: bytes):
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(data)

async def _read_signature_bytes(dut, begin, end, helpers) -> bytes:
    length = end - begin
    if length <= 0:
        raise RuntimeError(f"Intervalo inválido: begin=0x{begin:08x}, end=0x{end:08x}")
    if "read_mem_range" in helpers:
        return await helpers["read_mem_range"](dut, begin, length)
    if "read_word32" in helpers:
        out = bytearray()
        addr = begin
        while addr < end:
            w = await helpers["read_word32"](dut, addr)
            out += int(w).to_bytes(4, "little")
            addr += 4
        return bytes(out[:length])
    raise RuntimeError("Sem adaptador para ler RAM: implemente read_mem_range/read32.")

# ===================== Teste principal =====================
@cocotb.test()
async def archtest_compliance(dut):
    # Clock
    clk = _detect_clk(dut)
    assert clk is not None, "Não achei sinal de clock (clk/CLK) no DUT."
    cocotb.start_soon(Clock(clk, CLK_PERIOD_NS, units="ns").start())

    # Metadados do runner
    try:
        META = json.loads(os.environ["ARCHTEST_META"])
    except KeyError:
        raise RuntimeError("ARCHTEST_META ausente. Rode via runner em modo compliance.")

    hex_path = META["hex"]
    begin_sig = int(META["symbols"]["begin_signature"])
    end_sig   = int(META["symbols"]["end_signature"])
    rv_end    = META["symbols"]["rvtest_code_end"]
    tohost    = META["symbols"].get("tohost")
    test_name = META["test"]

    if tohost is None:
        raise AssertionError(
            "Ambiente sem 'tohost'. Sem reference_output, validar exige 'tohost' definido e escrito pelo firmware."
        )

    build_root = pathlib.Path(hex_path).resolve().parent
    out_sig = build_root / f"{test_name}.dut.signature.bin"

    helpers = _try_import_helpers()

    # Reset
    await _apply_reset(dut)

    # (Opcional) Espera por PC==RVTEST_CODE_END
    pc_sig = _detect_pc_signal(dut)
    if ARCHTEST_WAIT_PC and (rv_end is not None) and (pc_sig is not None):
        dut._log.info("Aguardando PC == RVTEST_CODE_END (WAIT_PC=1).")
        pc_hit = False
        for cycle in range(WATCHDOG_MAX):
            await RisingEdge(clk)
            try:
                pc_val = int(pc_sig.value)
            except Exception:
                pc_val = None
            if pc_val == rv_end:
                dut._log.info(
                    f"PC == RVTEST_CODE_END em {cycle} ciclos; aguardando {POST_HIT_WAIT} ciclo(s) e parando."
                )
                for _ in range(POST_HIT_WAIT):
                    await RisingEdge(clk)
                pc_hit = True
                break
        if not pc_hit:
            dut._log.warning(f"Watchdog PC ({WATCHDOG_MAX} ciclos) sem bater no RVTEST_CODE_END.")
    else:
        dut._log.info("Não aguardando PC==RVTEST_CODE_END (validação por polling em 'tohost').")

    # ===== Polling de 'tohost' até PASS ou timeout =====
    got_code = 0
    for cycle in range(WATCHDOG_MAX):
        # lê 32 bits em 'tohost'
        word = await _read_signature_bytes(dut, tohost, tohost + 4, helpers)
        got_code = int.from_bytes(word, "little")
        if got_code != 0:
            break
        await RisingEdge(clk)  # avança um ciclo antes de checar de novo

    if got_code == 0:
        raise AssertionError(f"Timeout aguardando 'tohost' != 0 (WATCHDOG_MAX={WATCHDOG_MAX}).")
    if got_code != PASS_CODE:
        raise AssertionError(f"FAIL via .tohost: got=0x{got_code:08x}, expected=0x{PASS_CODE:08x}")

    if _FORCE_FAIL:
        raise AssertionError("FAIL forçado para validar pipeline de testes/contadores.")

    dut._log.info(f"✅ PASS via .tohost (0x{got_code:08x})")

    # Salva assinatura do DUT para debug (opcional, mas útil)
    sig_bytes = await _read_signature_bytes(dut, begin_sig, end_sig, helpers)
    _save_signature(out_sig, sig_bytes)
    dut._log.info(f"Signature salva: {out_sig}")