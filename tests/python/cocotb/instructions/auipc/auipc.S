    .section .text
    .globl _start

_start:
    # AUIPC: testa comportamento em x0, normais e limites

    auipc x0,  0x00FFF   # x0 deve continuar 0
    auipc x1,  0x00001
    auipc x2,  0x12345
    auipc x3,  0x54321
    auipc x4,  0x00000
    auipc x5,  0x7FFFF
    auipc x6,  0x80000
    auipc x7,  0xFFFFF

    # Exibe resultados (coloca na saída da ALU)
    add t3, x0,  x0
    add t3, x1,  x0
    add t3, x2,  x0
    add t3, x3,  x0
    add t3, x4,  x0
    add t3, x5,  x0
    add t3, x6,  x0
    add t3, x7,  x0

1:  j 1b
