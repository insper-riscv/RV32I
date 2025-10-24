import os, json, pathlib, cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

_FORCE_FAIL = os.getenv("ARCHTEST_FORCE_FAIL", "0") == "1"

CLK_PERIOD_NS = float(os.getenv("ARCHTEST_CLK_NS", "10"))
WATCHDOG_MAX  = int(os.getenv("ARCHTEST_MAX_CYCLES", "200000"))
POST_HIT_WAIT = int(os.getenv("ARCHTEST_POST_HIT_WAIT", "2"))
PASS_CODE     = int(os.getenv("ARCHTEST_PASS_CODE", "1"))

def _detect_clk(dut):
    for name in ("clk","CLK","CLOCK_50"):
        if hasattr(dut, name):
            return getattr(dut, name)
    return None

def _read32(dut, addr, helpers):
    if helpers.get("read32"):
        return helpers["read32"](dut, addr)
    raise RuntimeError("Sem read32 implementado em helpers; ajuste seu testbench.")

def _read_signature_bytes(dut, begin, end, helpers):
    out = bytearray()
    addr = begin
    while addr < end:
        w = _read32(dut, addr, helpers)
        out += int(w).to_bytes(4, byteorder="little", signed=False)
        addr += 4
    return bytes(out[: max(0, end - begin)])

def _save_signature(path, data: bytes):
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)

@cocotb.test()
async def archtest_compliance(dut):
    clk = _detect_clk(dut); assert clk is not None, "Clock não encontrado (clk/CLK)."
    cocotb.start_soon(Clock(clk, CLK_PERIOD_NS, units="ns").start())

    try:
        META = json.loads(os.environ["ARCHTEST_META"])
    except KeyError:
        raise RuntimeError("ARCHTEST_META ausente. Rode via runner em modo compliance.")

    begin_sig = int(META["symbols"]["begin_signature"])
    end_sig   = int(META["symbols"]["end_signature"])
    tohost    = META["symbols"].get("tohost")
    test_name = META["test"]

    assert tohost is not None, "Ambiente sem 'tohost' – exigido para validar PASS/FAIL."

    # helpers do teu TB – adapte se necessário
    helpers = {}
    if hasattr(dut, "tohost"):
        helpers["read32"] = lambda _dut, a: int(getattr(_dut, "RAM").mem[a>>2]) if hasattr(_dut,"RAM") else int(getattr(_dut,"tohost").value)

    # aguarda tohost != 0
    got_code = 0
    for _ in range(WATCHDOG_MAX):
        await RisingEdge(clk)
        got_code = int(getattr(dut, "tohost").value)
        if got_code != 0:
            break
    for _ in range(POST_HIT_WAIT):
        await RisingEdge(clk)

    assert got_code != 0, f"Timeout aguardando 'tohost' (WATCHDOG_MAX={WATCHDOG_MAX})."
    assert got_code == PASS_CODE, f"FAIL via .tohost: got=0x{got_code:08x} exp=0x{PASS_CODE:08x}"
    if _FORCE_FAIL:
        raise AssertionError("FAIL forçado para validar pipeline.")

    # dump assinatura do DUT
    out_dir = pathlib.Path(os.getenv("ARCHTEST_OUT_SIG_DIR", "build/archtest/signatures"))
    out_sig = out_dir / f"{test_name}.dut.sig"
    sig_bytes = _read_signature_bytes(dut, begin_sig, end_sig, helpers)
    _save_signature(out_sig, sig_bytes)
    dut._log.info(f"Signature do DUT salva em: {out_sig}")

    # comparação com referência
    ref_dir = pathlib.Path(os.getenv("ARCHTEST_REF_DIR", "tests/third_party/riscv-arch-test/tools/reference_outputs"))
    ref_sig = ref_dir / f"{test_name}.sig"
    policy  = os.getenv("ARCHTEST_REF_POLICY", "auto").lower()

    if policy == "skip":
        dut._log.warning("ARCHTEST_REF_POLICY=skip – pulando comparação de assinatura.")
        return

    if not ref_sig.exists():
        raise AssertionError(
            f"Arquivo de referência ausente: {ref_sig}\n"
            f"Dica: rode 'make refs' ou use ARCHTEST_REF_POLICY=auto no runner para autogerar."
        )

    ref_bytes = ref_sig.read_bytes()
    if sig_bytes != ref_bytes:
        # Salva diff auxiliar
        diff_dir = pathlib.Path("build/archtest/diffs"); diff_dir.mkdir(parents=True, exist_ok=True)
        (diff_dir / f"{test_name}.ref.sig").write_bytes(ref_bytes)
        (diff_dir / f"{test_name}.dut.sig").write_bytes(sig_bytes)
        raise AssertionError(f"Assinatura difere do reference output para '{test_name}'. Veja {diff_dir}.")
    dut._log.info("✅ Assinatura confere com a referência.")