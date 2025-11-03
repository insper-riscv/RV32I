import os, json, struct, pathlib
import cocotb
from cocotb.triggers import RisingEdge, ReadOnly
from cocotb.clock import Clock
from .readers import init_sniffer, ram_read32  # note: no dump_range import

import subprocess, re, tempfile

RE_HEX_SYM = re.compile(r"^([0-9a-fA-F]+)\s+\w\s+(\S+)$")
RE_AT_LINE = re.compile(r"^@([0-9a-fA-F]+)$")

# -------- helpers to robustly map DUT signal names --------

# -------- reset helper (active-high or active-low) --------
async def pulse_reset(dut, cycles=8):
    """
    Try to find a reset signal on the top-level and pulse it.
    Active-low if the name suggests '*_N' or '*n'; otherwise active-high.
    """
    candidates = (
        "RST_N", "RESET_N", "resetn", "rst_n", "rst_n_i",
        "RST", "RESET", "reset", "rst", "rst_i"
    )
    rst = None
    name = None
    for n in candidates:
        if hasattr(dut, n):
            rst, name = getattr(dut, n), n
            break
    if rst is None:
        dut._log.warning("[reset] no reset port found; skipping explicit reset")
        return

    # Guess polarity from name
    name_l = name.lower()
    active_low = name_l.endswith("_n") or name_l.endswith("n")
    act = 0 if active_low else 1
    deact = 1 - act

    dut._log.info(f"[reset] pulsing reset '{name}' (active_{'low' if active_low else 'high'}) for {cycles} cycles")
    # Assert
    rst.value = act
    for _ in range(cycles):
        await RisingEdge(dut.CLK)
    # Deassert
    rst.value = deact
    # Let things settle a few cycles
    for _ in range(3):
        await RisingEdge(dut.CLK)


_SENTINEL = object()

def _pick(dut, *candidates, **kw):
    """
    Return (signal, picked_name). If none is found:
      - if 'default' is provided, return (default, None)
      - else raise AttributeError
    """
    default = kw.get("default", _SENTINEL)
    for name in candidates:
        if hasattr(dut, name):
            return getattr(dut, name), name
    if default is _SENTINEL:
        raise AttributeError(f"{dut._name} has none of: {candidates}")
    return default, None

def _u32(sig):
    return int(sig.value)

# -------- signature write watcher (sniffer) --------

async def watch_sig_writes(dut, beg, end, cycles=200000):
    """
    Watches RAM writes and logs any that land in [beg, end).

    Adapts to different top-level signal names:
      - address  : tries ('addr','address','ram_addr','ALU_out')
      - wdata    : tries ('wdata','dataW','data_in','out_StoreManager','write_data')
      - write-en : tries ('we','weRAM','ram_we','write')
      - enable   : tries ('eRAM','ram_en','ena')          [optional]
      - byte mask: tries ('mask','byte_en','wmask','be')  [optional]

    Address scale:
      * If name suggests WORD index ('addr','address','ram_addr'), scale=4
      * Otherwise (e.g., 'ALU_out'), scale=1 (byte address)
    """
    addr_sig, addr_name   = _pick(dut, "addr", "address", "ram_addr", "ALU_out")
    wdata_sig, _          = _pick(dut, "wdata", "dataW", "data_in", "out_StoreManager", "write_data")
    we_sig, _             = _pick(dut, "we", "weRAM", "ram_we", "write")
    ena_sig, ena_name     = _pick(dut, "eRAM", "ram_en", "ena", default=None)
    mask_sig, mask_name   = _pick(dut, "mask", "byte_en", "wmask", "be", default=None)

    word_index_names = {"addr", "address", "ram_addr"}
    ADDR_SCALE = 4 if (addr_name in word_index_names) else 1

    writes = 0
    dut._log.info(
        "[SIG-WATCH] addr='%s' scale=%d, we='%s', ena='%s', wdata='%s', mask='%s'"
        % (
            addr_name, ADDR_SCALE,
            getattr(we_sig, "_name", "<we?>"),
            ena_name if ena_name is not None else "<assume 1>",
            getattr(wdata_sig, "_name", "<wdata?>"),
            mask_name if mask_name is not None else "<none=0xF>",
        )
    )

    for _ in range(cycles):
        await RisingEdge(dut.CLK)

        if int(we_sig.value) == 0:
            continue

        ena_ok = 1 if (ena_sig is None) else int(ena_sig.value)
        if not ena_ok:
            continue

        addr = _u32(addr_sig) * ADDR_SCALE
        if not (beg <= addr < end):
            continue

        data = _u32(wdata_sig) & 0xFFFFFFFF
        mask = (_u32(mask_sig) & 0xF) if (mask_sig is not None) else 0xF

        writes += 1
        dut._log.info(f"[SIG-WRITE] addr=0x{addr:08x} data=0x{data:08x} mask=0b{mask:04b}")

    dut._log.info(f"[SIG-WRITE] total writes observed in [0x{beg:08x},0x{end:08x}): {writes}")

# -------- nm / spike helpers --------

def _sym_addr(elf_path:str, sym_name:str)->int:
    out = subprocess.check_output(["riscv32-unknown-elf-nm","-n",elf_path], text=True)
    for line in out.splitlines():
        m = RE_HEX_SYM.match(line.strip())
        if not m:
            continue
        addr_hex, name = m.groups()
        if name == sym_name:
            return int(addr_hex,16)
    raise RuntimeError(f"Símbolo {sym_name} não encontrado em {elf_path}")

def _run_spike(spike_elf:str, rom_map:str="0x80000000:0x100000", ram_map:str="0x20000000:0x10000")->str:
    tmpdir = tempfile.mkdtemp(prefix="archtest_")
    sig_path = os.path.join(tmpdir, "tmp.sig")
    cmd = [
        "spike","--isa=RV32I",
        f"-m{rom_map},{ram_map}",
        f"+signature={sig_path}",
        "+signature-granularity=4",
        spike_elf
    ]
    subprocess.check_call(cmd)
    return sig_path

def _try_read_binary_sig(path:str)->bytes:
    # Heurística simples: se a primeira linha começa com '@', é texto; senão, tentamos binário
    with open(path,"rb") as f:
        head = f.read(2)
    if head.startswith(b"@"):
        return None
    with open(path,"rb") as f:
        return f.read()

def _parse_text_signature(path:str)->tuple[int, bytearray]:
    """
    Parseia o formato textual do Spike:
      @<addr>  (linha)
      <word0> <word1> ... (hex 32b)
    Pode haver vários blocos @addr.
    Retorna (start_addr, bytes_contiguos).
    """
    blocks = []
    cur_addr = None
    cur_words = []
    min_addr = None
    max_addr = None

    with open(path, "r") as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            m = RE_AT_LINE.match(line)
            if m:
                if cur_addr is not None and cur_words:
                    blocks.append((cur_addr, cur_words))
                cur_addr = int(m.group(1), 16)
                cur_words = []
                if min_addr is None or cur_addr < min_addr:
                    min_addr = cur_addr
                continue
            for tok in line.split():
                cur_words.append(int(tok, 16) & 0xFFFFFFFF)
        if cur_addr is not None and cur_words:
            blocks.append((cur_addr, cur_words))

    if not blocks:
        raise AssertionError(f"Assinatura textual vazia em {path}")

    for base, words in blocks:
        end = base + 4*len(words)
        if max_addr is None or end > max_addr:
            max_addr = end

    span = max_addr - min_addr
    buf = bytearray(span)
    for base, words in blocks:
        off = base - min_addr
        for w in words:
            struct.pack_into("<I", buf, off, w)
            off += 4

    return min_addr, buf

def _load_spike_signature_bytes(sig_path:str)->tuple[int, bytes]:
    b = _try_read_binary_sig(sig_path)
    if b is not None:
        return None, b
    start_addr, bb = _parse_text_signature(sig_path)
    return start_addr, bytes(bb)

def compare_signature_textsig(dump_range, dut_elf:str, spike_elf:str)->None:
    sig_path = _run_spike(spike_elf)
    spike_start_addr, sig_ref = _load_spike_signature_bytes(sig_path)

    b_dut = _sym_addr(dut_elf, "begin_signature")
    e_dut = _sym_addr(dut_elf, "end_signature")
    dut_span = e_dut - b_dut

    if spike_start_addr is None:
        spike_start_addr = _sym_addr(spike_elf, "begin_signature")

    need = len(sig_ref)
    if need > dut_span:
        raise AssertionError(
            f"assinatura do Spike ({need} B) > janela do DUT ({dut_span} B). "
            f"Ajuste end_signature no linker do DUT."
        )

    sig_dut = dump_range(b_dut, b_dut + need)

    if sig_dut != sig_ref:
        diffs = []
        for i in range(0, need, 4):
            wr = struct.unpack_from("<I", sig_ref, i)[0]
            wd = struct.unpack_from("<I", sig_dut, i)[0]
            if wr != wd:
                diffs.append((i, wr, wd))
            if len(diffs) >= 16:
                break
        preview = "\n".join(f"@+0x{i:04x}: REF=0x{wr:08x} DUT=0x{wd:08x}" for i,wr,wd in diffs) or "(sem diffs?!?)"
        raise AssertionError("assinaturas diferentes; primeiras diferenças:\n"+preview)

def _load_ref_sig(path: pathlib.Path) -> bytes:
    raw = path.read_text().splitlines()
    if any(line.strip().startswith("@") for line in raw):
        spans = []
        cur_base = None
        cur = []
        for line in raw:
            s = line.strip()
            if not s:
                continue
            m = re.match(r"^@([0-9a-fA-F]+)$", s)
            if m:
                if cur_base is not None and cur:
                    spans.append((cur_base, cur)); cur = []
                cur_base = int(m.group(1), 16)
                continue
            for tok in s.split():
                cur.append(int(tok, 16) & 0xFFFFFFFF)
        if cur_base is not None and cur:
            spans.append((cur_base, cur))
        if not spans:
            raise AssertionError("assinatura Spike vazia")
        lo = min(b for b,_ in spans)
        hi = max(b + 4*len(ws) for b,ws in spans)
        buf = bytearray(hi - lo)
        for b, ws in spans:
            off = b - lo
            for w in ws:
                struct.pack_into("<I", buf, off, w); off += 4
        return bytes(buf)
    else:
        out = bytearray()
        for line in raw:
            s = line.strip()
            if not s:
                continue
            out += struct.pack("<I", int(s, 16) & 0xFFFFFFFF)
        return bytes(out)

async def _dump_range_via_ram(dut, start: int, end: int) -> bytes:
    out = bytearray()
    await RisingEdge(dut.CLK)
    await ReadOnly()
    for addr in range(start, end, 4):
        w = ram_read32(dut, addr)
        if w is None:
            w = 0
        out += struct.pack("<I", w)
    return bytes(out)

@cocotb.test()
async def archtest(dut):
    meta = json.loads(os.environ["ARCHTEST_META"])
    syms = meta["symbols"]
    test_name = meta["test"]

    begin_sig = int(syms["begin_signature"], 16)
    end_sig   = int(syms["end_signature"], 16)
    tohost    = int(syms["tohost"], 16)

    max_cycles = int(os.environ.get("ARCHTEST_MAX_CYCLES", "200000"))
    EXTRA_AFTER_TOHOST = int(os.environ.get("ARCHTEST_EXTRA_AFTER_TOHOST", "50000"))

    cocotb.start_soon(Clock(dut.CLK, 10, units="ns").start())

    await pulse_reset(dut)

    await init_sniffer(dut)

    ref_dir = pathlib.Path(os.environ["ARCHTEST_REF_DIR"])
    sig_ref_bin = _load_ref_sig(ref_dir / f"{test_name}.sig")

    # observe signature writes during run (robust to signal names/scaling)
    await watch_sig_writes(dut, begin_sig, end_sig)

    region_len = end_sig - begin_sig
    ref_tail_le = struct.unpack_from("<I", sig_ref_bin, len(sig_ref_bin) - 4)[0] if len(sig_ref_bin) >= 4 else None
    cmp_len = len(sig_ref_bin) - 4 if ref_tail_le == 0x6f5ca309 else len(sig_ref_bin)
    cmp_len = min(cmp_len, region_len)

    tail_addr = end_sig - 4

    pass_cycle = None
    seen_zero = False
    for cycle in range(max_cycles):
        await RisingEdge(dut.CLK)
        await ReadOnly()
        th = ram_read32(dut, tohost)

        if th == 0:
            seen_zero = True
            continue

        if seen_zero and th != 0:
            cocotb.log.info(f"[archtest] tohost 0->nonzero at cycle={cycle} (th=0x{th:08x})")
            pass_cycle = cycle
            break

    if pass_cycle is None:
        raise AssertionError(f"timeout: tohost never transitioned 0->nonzero within {max_cycles} cycles")

    # Extra runway for final writes
    for _ in range(EXTRA_AFTER_TOHOST):
        await RisingEdge(dut.CLK)
        await ReadOnly()
        _ = ram_read32(dut, tail_addr)

    sig_dut = await _dump_range_via_ram(dut, begin_sig, end_sig)

    cocotb.log.info(f"[archtest] size DUT={len(sig_dut)} REF={len(sig_ref_bin)} cmp_len={cmp_len}")

    def _u32b(buf, off): return struct.unpack_from("<I", buf, off)[0]
    def _hexw(w): return f"0x{w:08x}"

    if sig_dut[:cmp_len] != sig_ref_bin[:cmp_len]:
        first_mis = None
        for i in range(0, cmp_len, 4):
            if sig_dut[i:i+4] != sig_ref_bin[i:i+4]:
                first_mis = i
                break

        out_dir = pathlib.Path(os.environ.get("ARCHTEST_OUT_DIR", "."))
        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / "dut.bin").write_bytes(sig_dut[:cmp_len])
        (out_dir / "ref.bin").write_bytes(sig_ref_bin[:cmp_len])
        with (out_dir / "dut.sig").open("w") as f:
            for j in range(0, cmp_len, 4):
                f.write(f"{_u32b(sig_dut, j):08x}\n")

        if first_mis is None:
            assert False, f"assinatura diferente no prefixo em {test_name}: bytes diferentes (32b-aligned)"

        idx = first_mis // 4
        addr = begin_sig + first_mis
        w_dut = _u32b(sig_dut, first_mis)
        w_ref = _u32b(sig_ref_bin, first_mis)
        s = max(0, (idx - 2) * 4)
        e = min(cmp_len, (idx + 3) * 4)
        cocotb.log.info("[archtest] primeira divergência:")
        for off in range(s, e, 4):
            tag = "!=" if off == first_mis else "  "
            cocotb.log.info(f"{tag} [{(begin_sig+off):08x}] DUT={_hexw(_u32b(sig_dut, off))} REF={_hexw(_u32b(sig_ref_bin, off))}")

        assert False, (
            f"prefix mismatch em {test_name}: word#{idx} @0x{addr:08x} "
            f"DUT={_hexw(w_dut)} REF={_hexw(w_ref)} (cmp_len={cmp_len})"
        )