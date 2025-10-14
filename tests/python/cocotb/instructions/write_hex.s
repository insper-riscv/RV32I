    .text
    .global _start
_start:
    # endereço base do HEX0
    li   t0, 0x200      # endereço MMIO do HEX0
    add  t3, t0, x0

loop:
    li   t1, 0x09            # valor a escrever (exemplo: '9' = 0x39)
    add  t3, t1, x0
    sw   t1, 0(t0)           # grava no HEX0
    j    loop                # repete para sempre
