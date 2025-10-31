import os, json, struct, pathlib
import cocotb
from cocotb.triggers import RisingEdge, ReadOnly
from cocotb.clock import Clock
from .readers import init_sniffer, ram_read32  # note: no dump_range import

import subprocess, re, tempfile

RE_HEX_SYM = re.compile(r"^([0-9a-fA-F]+)\s+\w\s+(\S+)$")
RE_AT_LINE = re.compile(r"^@([0-9a-fA-F]+)$")

async def watch_sig_writes(dut, beg, end, cycles=200000):
    import cocotb
    from cocotb.triggers import RisingEdge
    def u32(sig): return int(sig.value)
    writes=0
    for _ in range(cycles):
        await RisingEdge(dut.CLK)
        we   = int(getattr(dut,"weRAM").value)
        ena  = int(getattr(dut,"eRAM").value)
        addr = u32(getattr(dut,"addr"))*4   # se sua RAM usa A[31:2]
        wdat = u32(getattr(dut,"data_in"))
        if we and ena and beg <= addr < end:
            writes+=1
            dut._log.info(f"[SIG-WRITE] addr=0x{addr:08x} data=0x{wdat:08x}")
    dut._log.info(f"[SIG-WRITE] total writes: {writes}")


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
    # Parece binário (ou outro formato); devolve bytes
    with open(path,"rb") as f:
        return f.read()

def _parse_text_signature(path:str)->tuple[int, bytearray]:
    """
    Parseia o formato textual do Spike:
      @<addr>\n
      <word0> <word1> ... (hex de 32 bits, sem 0x, separados por espaço/linha)
    Pode ter vários blocos começando com @addr.
    Retorna (start_addr, bytes_contiguos) cobrindo do menor @addr até o maior endereço escrito.
    """
    blocks = []  # lista de (base_addr:int, [words:int])
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
                # fecha bloco anterior
                if cur_addr is not None and cur_words:
                    blocks.append((cur_addr, cur_words))
                cur_addr = int(m.group(1), 16)
                cur_words = []
                if min_addr is None or cur_addr < min_addr:
                    min_addr = cur_addr
                continue
            # tokens hex
            tokens = line.split()
            for tok in tokens:
                w = int(tok, 16)
                cur_words.append(w)
        # fecha o último
        if cur_addr is not None and cur_words:
            blocks.append((cur_addr, cur_words))

    if not blocks:
        raise AssertionError(f"Assinatura textual vazia em {path}")

    # Calcula faixa total e materializa um bytearray contínuo
    # Cada word ocupa 4 bytes; endereçamento é byte-addressed.
    # Também infere max_addr.
    for base, words in blocks:
        end = base + 4*len(words)
        if max_addr is None or end > max_addr:
            max_addr = end

    span = max_addr - min_addr
    buf = bytearray(span)
    for base, words in blocks:
        off = base - min_addr
        for w in words:
            struct.pack_into("<I", buf, off, w & 0xFFFFFFFF)
            off += 4

    return min_addr, buf

def _load_spike_signature_bytes(sig_path:str)->tuple[int, bytes]:
    b = _try_read_binary_sig(sig_path)
    if b is not None:
        # Não temos o endereço base no binário cru; vamos derivar do ELF depois.
        return None, b
    start_addr, bb = _parse_text_signature(sig_path)
    return start_addr, bytes(bb)

def compare_signature_textsig(dump_range, dut_elf:str, spike_elf:str)->None:
    # 1) Gera assinatura do Spike (texto: @addr + hex)
    sig_path = _run_spike(spike_elf)

    # 2) Converte assinatura do Spike em bytes contínuos e captura o endereço base
    spike_start_addr, sig_ref = _load_spike_signature_bytes(sig_path)

    # 3) Descobre begin/end do DUT
    b_dut = _sym_addr(dut_elf, "begin_signature")
    e_dut = _sym_addr(dut_elf, "end_signature")
    dut_span = e_dut - b_dut

    # 4) Se a assinatura do Spike veio binária sem base, alinhe pelo ELF do Spike:
    if spike_start_addr is None:
        spike_start_addr = _sym_addr(spike_elf, "begin_signature")

    # 5) Ajuste de tamanho: limite pela janela do DUT
    need = len(sig_ref)
    if need > dut_span:
        raise AssertionError(
            f"assinatura do Spike ({need} B) > janela do DUT ({dut_span} B). "
            f"Ajuste end_signature no linker do DUT."
        )

    # 6) Leia do DUT exatamente 'need' bytes
    sig_dut = dump_range(b_dut, b_dut + need)

    # 7) Comparação
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

    # 8) Sanidade opcional
    # print(f"[ok] assinatura igual: {need} bytes (base Spike 0x{spike_start_addr:08x}, base DUT 0x{b_dut:08x})")

def _load_ref_sig(path: pathlib.Path) -> bytes:
    raw = path.read_text().splitlines()
    if any(line.strip().startswith("@") for line in raw):
        # formato com @addr
        buf = bytearray()
        base = None
        spans = []
        cur_base = None
        cur = []
        import re, struct
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
        # um hex de 32b por linha
        import struct
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
    await init_sniffer(dut)

    ref_dir = pathlib.Path(os.environ["ARCHTEST_REF_DIR"])
    sig_ref_bin = _load_ref_sig(ref_dir / f"{test_name}.sig")

    await watch_sig_writes(dut, begin_sig, end_sig)

    region_len = end_sig - begin_sig
    ref_tail_le = struct.unpack_from("<I", sig_ref_bin, len(sig_ref_bin) - 4)[0] if len(sig_ref_bin) >= 4 else None
    cmp_len = len(sig_ref_bin) - 4 if ref_tail_le == 0x6f5ca309 else len(sig_ref_bin)
    cmp_len = min(cmp_len, region_len)

    tail_addr = end_sig - 4

    pass_cycle = None
    for cycle in range(max_cycles):
        await RisingEdge(dut.CLK)
        await ReadOnly()
        th = ram_read32(dut, tohost)
        if th != 0:
            cocotb.log.info(f"[archtest] tohost!=0 ciclo={cycle}")
            pass_cycle = cycle
            break
    if pass_cycle is None:
        raise AssertionError(f"timeout: tohost ficou 0 até {max_cycles} ciclos")

    # Give a bit of runway for final writes; do not require any in-memory sentinel.
    for _ in range(EXTRA_AFTER_TOHOST):
        await RisingEdge(dut.CLK)
        await ReadOnly()
        # optional peek to encourage last writes to settle
        _ = ram_read32(dut, tail_addr)

    sig_dut = await _dump_range_via_ram(dut, begin_sig, end_sig)

    cocotb.log.info(f"[archtest] size DUT={len(sig_dut)} REF={len(sig_ref_bin)} cmp_len={cmp_len}")

    def _u32(buf, off): return struct.unpack_from("<I", buf, off)[0]
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
                f.write(f"{_u32(sig_dut, j):08x}\n")

        if first_mis is None:
            assert False, f"assinatura diferente no prefixo em {test_name}: bytes diferentes (32b-aligned)"

        idx = first_mis // 4
        addr = begin_sig + first_mis
        w_dut = _u32(sig_dut, first_mis)
        w_ref = _u32(sig_ref_bin, first_mis)
        s = max(0, (idx - 2) * 4)
        e = min(cmp_len, (idx + 3) * 4)
        cocotb.log.info("[archtest] primeira divergência:")
        for off in range(s, e, 4):
            tag = "!=" if off == first_mis else "  "
            cocotb.log.info(f"{tag} [{(begin_sig+off):08x}] DUT={_hexw(_u32(sig_dut, off))} REF={_hexw(_u32(sig_ref_bin, off))}")

        assert False, (
            f"prefix mismatch em {test_name}: word#{idx} @0x{addr:08x} "
            f"DUT={_hexw(w_dut)} REF={_hexw(w_ref)} (cmp_len={cmp_len})"
        )