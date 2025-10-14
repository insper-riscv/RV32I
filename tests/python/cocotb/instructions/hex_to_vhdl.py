#!/usr/bin/env python3
# Converte um arquivo com linhas de 8 dígitos hex (32 bits)
# em um bloco VHDL "constant ROMDATA : blocoMemoria := (...)"
# Preenche até 256 posições com zeros.

import sys

# uso: python3 hex_to_vhdl_rom.py input.txt > romdata.vhd
if len(sys.argv) < 2:
    print("Uso: python3 hex_to_vhdl_rom.py <arquivo_entrada.txt>")
    sys.exit(1)

input_file = sys.argv[1]
ROM_SIZE = 256  # número total de palavras (2^8)

# lê linhas e limpa
with open(input_file) as f:
    lines = [l.strip() for l in f if l.strip()]

# converte e trunca para 8 hex dígitos
words = []
for l in lines:
    val = l.strip().replace("0x", "").upper()
    val = val.zfill(8)
    if len(val) > 8:
        val = val[-8:]  # garante 32 bits
    words.append(val)

# imprime VHDL
print("constant ROMDATA : blocoMemoria := (")

for i, val in enumerate(words):
    sep = "" if i < ROM_SIZE - 1 else ""
    print(f"  {i:<3d} => x\"{val}\",{sep}")

# completa até 255
if len(words) < ROM_SIZE:
    last = len(words)
    print(f"  {last} to {ROM_SIZE-1} => x\"00000000\"  -- restante zerado")

print(");")
