    .section .text
    .globl _start

_start:
    # Base address em x1 = 0
    addi x1, x0, 0

    # Valor a ser armazenado: 0xAABBCCDD
    lui  x2, 0xAABBD
    addi x2, x2, -803       # x2 = 0xAABBCCDD

    # ==== STORES ====
    sw x2, 0(x1)            # M[0x0..0x3] = 0xAABBCCDD
    sh x2, 4(x1)            # M[0x4..0x5] = 0xCCDD
    sb x2, 6(x1)            # M[0x6]      = 0xDD

    # ==== LOADS ====
    lw  x3, 0(x1)           # x3 = 0xAABBCCDD
    add t3, x3, x0          # expõe x3

    lh  x4, 4(x1)           # x4 = 0xFFFFCCDD (sign-extend)
    add t3, x4, x0          # expõe x4

    lhu x5, 4(x1)           # x5 = 0x0000CCDD (zero-extend)
    add t3, x5, x0          # expõe x5

    lb  x6, 6(x1)           # x6 = 0xFFFFFFDD (sign-extend)
    add t3, x6, x0          # expõe x6

    lbu x7, 6(x1)           # x7 = 0x000000DD (zero-extend)
    add t3, x7, x0          # expõe x7

1:  j 1b
