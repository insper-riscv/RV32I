    .section .text
    .globl _start

_start:
    # x1 = 0x00000001
    lui   x1, 0x0          # carrega parte alta = 0x00000
    addi  x1, x1, 1        # adiciona parte baixa = 0x00000001

    # x2 = 0x7FFFFFFF
    lui   x2, 0x80000      # carrega 0x80000 << 12 = 0x80000000
    addi  x2, x2, -1       # ajusta para 0x7FFFFFFF

    # ==== Instruções R-type ====
    add   x3,  x1, x2
    sub   x4,  x1, x2
    xor   x5,  x1, x2
    or    x6,  x1, x2
    and   x7,  x1, x2
    sll   x8,  x1, x2
    srl   x9,  x1, x2
    sra   x10, x1, x2
    slt   x11, x1, x2
    sltu  x12, x1, x2

1:  j 1b
