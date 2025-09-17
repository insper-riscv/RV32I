    .section .text
    .globl _start

_start:
    # Escrever em x0 não deve alterar o valor
    lui x0,  0x00FFF     # resultado = 0x00000000

    # Casos normais
    lui x1,  0x00001     # resultado = 0x00001000
    lui x2,  0x12345     # resultado = 0x12345000
    lui x3,  0x54321     # resultado = 0x54321000

    # Casos de limite
    lui x4,  0x00000     # resultado = 0x00000000
    lui x5,  0x7FFFF     # resultado = 0x7FFFF000
    lui x6,  0x80000     # resultado = 0x80000000 (sign-extended)
    lui x7,  0xFFFFF     # resultado = 0xFFFFF000 (sign-extended, -1 << 12)

    # Copia todos para ALU_out
    add t3, x0,  x0
    add t3, x1,  x0
    add t3, x2,  x0
    add t3, x3,  x0
    add t3, x4,  x0
    add t3, x5,  x0
    add t3, x6,  x0
    add t3, x7,  x0

1:  j 1b
