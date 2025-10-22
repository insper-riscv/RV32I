    .section .text
    .globl _start

_start:

    # ==== TESTES DE AUIPC ====
    auipc x8,  0x00001
    auipc x9,  0x12345
    auipc x10, 0x54321
    auipc x11, 0x00000
    auipc x12, 0x7FFFF
    auipc x13, 0x80000
    auipc x14, 0xFFFFF

    # Expor os resultados do AUIPC na saída da ALU
    add t3, x8,  x0
    add t3, x9,  x0
    add t3, x10, x0
    add t3, x11, x0
    add t3, x12, x0
    add t3, x13, x0
    add t3, x14, x0

    # ==== TESTES DE LUI ====
    lui x1,  0x00001
    lui x2,  0x12345
    lui x3,  0x54321
    lui x4,  0x00000
    lui x5,  0x7FFFF
    lui x6,  0x80000
    lui x7,  0xFFFFF

    # Expor os resultados do LUI na saída da ALU
    add t3, x1, x0
    add t3, x2, x0
    add t3, x3, x0
    add t3, x4, x0
    add t3, x5, x0
    add t3, x6, x0
    add t3, x7, x0

1:  j 1b
