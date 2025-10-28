#!/usr/bin/env python3
import sys
import os

def usage():
    print("Uso: hex2mif.py <input.hex> <output.mif> [DEPTH]")
    sys.exit(1)

if len(sys.argv) < 3:
    usage()

hexfile = sys.argv[1]
miffile = sys.argv[2]
DEPTH = int(sys.argv[3]) if len(sys.argv) > 3 else 512

if not os.path.isfile(hexfile):
    print(f"Erro: arquivo hex '{hexfile}' não encontrado", file=sys.stderr)
    sys.exit(2)

with open(hexfile, "r") as f:
    lines = [l.strip() for l in f if l.strip()]

with open(miffile, "w") as out:
    out.write("WIDTH=32;\n")
    out.write(f"DEPTH={DEPTH};\n\n")
    out.write("ADDRESS_RADIX=HEX;\n")
    out.write("DATA_RADIX=HEX;\n\n")
    out.write("CONTENT BEGIN\n")
    for i, l in enumerate(lines):
        out.write(f"    {i:02X} : {l};\n")
    max_addr = DEPTH - 1
    start = len(lines)
    out.write(f"    [{start:02X}..{max_addr:03X}] : 00000000; -- restante zerado até {DEPTH} palavras\n")
    out.write("END;\n")

print(f"Gerado: {miffile} (loaded {len(lines)} words, depth={DEPTH})")
