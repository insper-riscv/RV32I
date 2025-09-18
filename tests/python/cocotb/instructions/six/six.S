    .section .text
    .globl _start

_start:
    # Base address em x1 = 0
    addi x1, x0, 0

    # Valor a ser armazenado: 0xAABBCCDD
    # decomposição: upper = (0xAABBCCDD + 0x800) >> 12 = 0xAABBD
    #               lower = 0xCDD (mas como signed é -803)
    lui  x2, 0xAABBD
    addi x2, x2, -803       # x2 = 0xAABBCCDD

    # ==== STORES ====
    sw x2, 0(x1)            # M[0x0..0x3] = 0xAABBCCDD
    sh x2, 4(x1)            # M[0x4..0x5] = 0xCCDD
    sb x2, 6(x1)            # M[0x6]      = 0xDD

    # ==== LOADS ====
    lw  x3, 0(x1)           # x3 = 0xAABBCCDD
    lh  x4, 4(x1)           # x4 = 0xFFFFCCDD (sign-extend)
    lhu x5, 4(x1)           # x5 = 0x0000CCDD (zero-extend)
    lb  x6, 6(x1)           # x6 = 0xFFFFFFDD (sign-extend)
    lbu x7, 6(x1)           # x7 = 0x000000DD (zero-extend)

1:  j 1b
