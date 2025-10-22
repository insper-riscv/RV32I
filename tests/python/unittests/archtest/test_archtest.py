import os
import json
import pathlib
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# ------------ parâmetros via ambiente ------------
CLK_PERIOD_NS   = float(os.getenv("ARCHTEST_CLK_NS", "10"))       # 100 MHz
WATCHDOG_MAX    = int(os.getenv("ARCHTEST_MAX_CYCLES", "200000")) # limite pra não travar
POST_HIT_WAIT   = int(os.getenv("ARCHTEST_POST_HIT_WAIT", "2"))   # ciclos extras após bater no fim

# ------------ helpers opcionais (RAM/ROM) ------------
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
    # aceita clk/CLK
    clk = getattr(dut, "clk", None) or getattr(dut, "CLK", None)
    return clk

def _detect_pc_signal(dut):
    # prioriza teu nome de sinal
    for name in ["PC_out", "pc", "PC", "pc_q", "pc_reg", "if_pc", "pc_current"]:
        if hasattr(dut, name):
            return getattr(dut, name)
    return None

async def _apply_reset(dut):
    """Se houver reset, aplica; senão, só gera alguns ciclos/tempo pra assentar."""
    clk = _detect_clk(dut)
    rst_n = getattr(dut, "reset_n", None)
    rst   = getattr(dut, "reset", None)

    if rst_n is not None:
        rst_n.value = 0
        for _ in range(5 if clk is not None else 0):
            await RisingEdge(clk)
        rst_n.value = 1
        if clk is not None:
            for _ in range(2):
                await RisingEdge(clk)
        else:
            await Timer(20, units="ns")
        return

    if rst is not None:
        rst.value = 1
        for _ in range(5 if clk is not None else 0):
            await RisingEdge(clk)
        rst.value = 0
        if clk is not None:
            for _ in range(2):
                await RisingEdge(clk)
        else:
            await Timer(20, units="ns")
        return

    # sem reset no DUT: só dá um tempo/ciclos
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

# ------------ teste principal ------------
@cocotb.test()
async def archtest_compliance(dut):
    # clock
    clk = _detect_clk(dut)
    assert clk is not None, "Não achei sinal de clock (clk/CLK) no DUT."
    cocotb.start_soon(Clock(clk, CLK_PERIOD_NS, units="ns").start())

    # meta vinda do runner
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

    build_root = pathlib.Path(hex_path).resolve().parent
    out_sig = build_root / f"{test_name}.dut.signature.bin"

    helpers = _try_import_helpers()

    # reset (tolerante)
    await _apply_reset(dut)

    # estratégia de parada
    pc_sig = _detect_pc_signal(dut)
    if rv_end is not None and pc_sig is not None:
        dut._log.info("Parando na primeira vez em que PC == RVTEST_CODE_END.")
    else:
        dut._log.info("Sem PC/RVTEST_CODE_END; usando watchdog.")

    pc_hit = False
    for cycle in range(WATCHDOG_MAX):
        await RisingEdge(clk)
        if rv_end is not None and pc_sig is not None:
            try:
                pc_val = int(pc_sig.value)
            except Exception:
                pc_val = None
            if pc_val == rv_end:
                dut._log.info(f"PC == RVTEST_CODE_END em {cycle} ciclos; aguardando {POST_HIT_WAIT} ciclo(s) e parando.")
                for _ in range(POST_HIT_WAIT):
                    await RisingEdge(clk)
                pc_hit = True
                break
    else:
        dut._log.warning(f"Watchdog atingido ({WATCHDOG_MAX} ciclos).")

    if rv_end is not None and pc_sig is not None and not pc_hit:
        dut._log.warning("Nunca atingiu RVTEST_CODE_END; prosseguindo assim mesmo.")

    # coleta assinatura do DUT
    sig_bytes = await _read_signature_bytes(dut, begin_sig, end_sig, helpers)
    _save_signature(out_sig, sig_bytes)
    dut._log.info(f"Signature salva: {out_sig}")

    if len(sig_bytes) == 0:
        raise AssertionError("Assinatura vazia.")

    # ---- comparação com referência ----
    repo_root = pathlib.Path(hex_path).resolve().parents[2]  # .../build/archtest/ -> repo
    ref_dir   = repo_root / "tests/third_party/riscv-arch-test/riscv-test-suite/rv32i_m/I/reference"
    ref_file  = ref_dir / f"{test_name}.reference_output"

    if ref_file.exists():
        ref_bytes = ref_file.read_bytes()
        if sig_bytes != ref_bytes:
            diff_path = build_root / f"{test_name}.diff.txt"
            with open(diff_path, "w") as f:
                f.write(f"Signature mismatch for {test_name}\n")
                for i, (a, b) in enumerate(zip(sig_bytes, ref_bytes)):
                    if a != b:
                        f.write(f"byte {i:04d}: got {a:02x}, expected {b:02x}\n")
            raise AssertionError(f"Signature diferente! Veja {diff_path}")
        else:
            dut._log.info("✅ PASS (assinatura idêntica)")
    else:
        # Fallback via .tohost
        if tohost is None:
            raise AssertionError("Sem reference_output e sem símbolo 'tohost' para fallback.")
        word = await _read_signature_bytes(dut, tohost, tohost + 4, helpers)
        code = int.from_bytes(word, "little")
        PASS_CODE = int(os.getenv("ARCHTEST_PASS_CODE", "1"))
        if code != PASS_CODE:
            raise AssertionError(f"FAIL via .tohost: got=0x{code:08x}, expected=0x{PASS_CODE:08x}")
        dut._log.info(f"✅ PASS via .tohost (0x{code:08x})")