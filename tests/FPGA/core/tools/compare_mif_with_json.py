#!/usr/bin/env python3
"""
compare_mif_with_json.py

Uso:
  python3 compare_mif_with_json.py <mif_file> <golden_json>

Agora também salva:
  <mif_file>.dump.json
para comparação visual da memória interpretada do MIF.
"""
import sys
import re
import json
from pathlib import Path

def error(msg):
    print("ERROR:", msg, file=sys.stderr)
    sys.exit(1)

def parse_mif(path):
    """
    Retorna dict word_addr -> integer_value
    """
    text = Path(path).read_text()

    # find DATA_RADIX
    m = re.search(r"DATA_RADIX\s*=\s*([A-Za-z]+)\s*;", text, re.IGNORECASE)
    if not m:
        error("DATA_RADIX não encontrado no MIF.")
    data_radix = m.group(1).upper()

    # confirm WIDTH
    m2 = re.search(r"WIDTH\s*=\s*(\d+)\s*;", text, re.IGNORECASE)
    if not m2:
        error("WIDTH não encontrado no MIF.")
    width = int(m2.group(1))
    if width != 32:
        print(f"Aviso: WIDTH={width}, esperado 32.")

    # extract CONTENT block
    m3 = re.search(r"CONTENT\s+BEGIN(.*)END\s*;", text, re.IGNORECASE | re.DOTALL)
    if not m3:
        error("Bloco CONTENT ... END; não encontrado no MIF.")
    body = m3.group(1)

    word_map = {}

    for raw_line in body.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("--"):
            continue

        mline = re.match(r"^\s*(\[[^\]]+\]|[0-9A-Fa-fx]+)\s*:\s*([0-9A-Fa-f_]+)\s*;.*$", line)
        if not mline:
            continue

        addr_token = mline.group(1).strip()
        data_token = mline.group(2).strip().replace("_","")

        # parse data
        if data_radix == "BIN":
            value = int(data_token, 2)
        elif data_radix == "HEX":
            value = int(data_token, 16)
        elif data_radix in ("DEC", "UNS"):
            value = int(data_token, 10)
        else:
            error(f"DATA_RADIX '{data_radix}' não suportado.")

        # parse address or range
        if addr_token.startswith("["):
            inner = addr_token[1:-1]
            a_str, b_str = inner.split("..", 1)
            a = int(a_str, 16)
            b = int(b_str, 16)
            for w in range(a, b+1):
                word_map[w] = value
        else:
            a = int(addr_token, 16)
            word_map[a] = value

    return word_map

def build_byte_map_from_words(word_map):
    byte_map = {}
    for waddr, wval in word_map.items():
        base = waddr * 4
        for i in range(4):
            byte_map[base + i] = (wval >> (8*i)) & 0xFF
    return byte_map

def load_golden_json(path):
    j = json.loads(Path(path).read_text())
    out = {}
    for k,v in j.items():
        addr = int(k,16) if isinstance(k,str) and k.lower().startswith("0x") else int(k)
        out[addr] = int(v)
    return out

def save_dump_json(byte_map, path_out):
    out = { f"0x{addr:08X}": val for addr,val in sorted(byte_map.items()) }
    Path(path_out).write_text(json.dumps(out, indent=2))
    print(f"Dump salvo em {path_out}")

def main():
    if len(sys.argv) != 3:
        print("Uso: compare_mif_with_json.py <mif_file> <golden_json>")
        sys.exit(1)

    mif = sys.argv[1]
    golden = sys.argv[2]

    if not Path(mif).is_file():
        error("MIF não encontrado: " + mif)
    if not Path(golden).is_file():
        error("Arquivo JSON gabarito não encontrado: " + golden)

    word_map = parse_mif(mif)
    byte_map = build_byte_map_from_words(word_map)
    gold_map = load_golden_json(golden)

    # ---- salvar dump json ----
    dump_path = mif + ".dump.json"
    save_dump_json(byte_map, dump_path)

    # ---- comparação ----
    diffs = []
    missing = []

    for addr, expected in sorted(gold_map.items()):
        if addr not in byte_map:
            missing.append(addr)
            continue
        actual = byte_map[addr]
        if actual != expected:
            diffs.append((addr, expected, actual))

    if missing:
        print("\nERRO: Endereços do gabarito fora do alcance do MIF:")
        for a in missing[:10]:
            print(f"  0x{a:08X}")
        print("Total missing:", len(missing))

    if diffs:
        print("\nForam encontradas diferenças (mostrando até 50):")
        for a,exp,act in diffs[:50]:
            print(f"  0x{a:08X} : expected={exp} (0x{exp:02X}) actual={act} (0x{act:02X})")
        print(f"\nTotal diffs: {len(diffs)}")
        sys.exit(2)

    if not diffs and not missing:
        print("OK: MIF coincide com o gabarito JSON.")
        sys.exit(0)

    print("Falha devido a endereços faltantes.")
    sys.exit(2)

if __name__ == "__main__":
    main()
