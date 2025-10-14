    .text
    .global _start
_start:
    # endereço base do HEX0
    li   t0, 200      # endereço MMIO do HEX0

loop:
    li   t1, 0x09            # valor a escrever (exemplo: '9' = 0x39)
    sw   t1, 0(t0)           # grava no HEX0
    j    loop                # repete para sempre
