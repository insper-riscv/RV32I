    .section .text
    .globl _start

_start:
    # montar endereço 0x800 (2048) em x1 (base dos LEDs)
    lui   x1, 0x1
    addi  x1, x1, -2048        # x1 = 0x00000800

blink_loop:
    # acende todos os 8 LEDs (0x00FF)
    addi  x2, x0, 255          # x2 = 0x00FF
    sh    x2, 0(x1)            # escreve 0x00FF em 0x800

    # delay aproximado (~0.25 s)
    lui   x4, 0x933
    addi  x4, x4, 0x2E0        # x4 = 1_250_000
delay_on:
    addi  x4, x4, -1
    bne   x4, x0, delay_on

    # apaga os LEDs (0x0000)
    addi  x2, x0, 0
    sh    x2, 0(x1)            # escreve 0x0000 em 0x800

    # delay (~0.25 s)
    lui   x4, 0x933
    addi  x4, x4, 0x2E0
delay_off:
    addi  x4, x4, -1
    bne   x4, x0, delay_off

    j     blink_loop           # repete para sempre
