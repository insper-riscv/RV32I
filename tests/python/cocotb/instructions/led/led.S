    .section .text
    .globl _start

_start:
    # montar endereço 0x800 (2048) em x1
    # LUI 0x1 -> 0x1_000 = 0x1000 (4096)
    # addi x1, x1, -2048 -> 0x1000 - 0x800 = 0x800
    lui   x1, 0x1
    addi  x1, x1, -2048    # x1 = 0x00000800  (endereço dos LEDs, halfword)

blink_loop:
    # acende os 8 leds (valor 0x00FF no halfword; assume-se que os leds usam os 8 LSB)
    addi  x2, x0, 255      # x2 = 0x00FF
    sw    x2, 0(x1)        # store halfword em [0x800] -> acende LEDs
    # (aperte o clock aqui para ver a mudança)

    # apaga os leds (escreve 0)
    addi  x2, x0, 0
    sw    x2, 0(x1)        # store halfword 0 -> apaga LEDs
    # (aperte o clock aqui para ver a mudança)

    j     blink_loop       # repete infinitamente
