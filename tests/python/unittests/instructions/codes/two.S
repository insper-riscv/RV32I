    .section .text
    .globl _start

_start:
    # valor base em x1 = 0x0000F0F0
    lui   x1, 0x0000F
    addi  x1, x1, 0x0F0

    # ---- I-type testes ----
    addi x2,  x1,  0x10      # x2 = x1 + 0x10
    xori x3,  x1,  0xFF      # x3 = x1 ^ 0xFF
    ori  x4,  x1,  0x0F0     # x4 = x1 | 0x0F0
    andi x5,  x1,  0x0F0     # x5 = x1 & 0x0F0

    slli x6,  x1,  4         # x6 = x1 << 4
    srli x7,  x1,  4         # x7 = x1 >>u 4
    srai x8,  x1,  4         # x8 = x1 >>s 4

    # ---- expor resultados ----
    add t3, x2,  x0
    add t3, x3,  x0
    add t3, x4,  x0
    add t3, x5,  x0
    add t3, x6,  x0
    add t3, x7,  x0
    add t3, x8,  x0

1:  j 1b
