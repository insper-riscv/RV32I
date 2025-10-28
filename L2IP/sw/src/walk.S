    .section .text
    .globl _start

_start:
    # montar endereço 0x800 (2048) em x1
    #lui   x1, 0x1
    #addi  x1, x1, -2048    # x1 = 0x00000800  (endereço dos LEDs, halfword)
    lui   x1, 0x1          # x1 = 0x00001000  (endereço dos LEDs)
    addi  x1, x1, 0        # sem ajuste

    # carregar contador para ~0.5s: N = 12_500_000
    # usado no laço de delay (recarregado a cada cycle)
    # constants: hi=0xBEB, lo=-992
    # inicializa pattern do LED (um único LED na direita)
    addi  x2, x0, 1        # x2 = 0x01 -> LED mais à direita

blink_loop:
    # escreve pattern atual nos LEDs
    sh    x2, 0(x1)        # store halfword em [0x800] -> atualiza LEDs

    # delay (meio segundo aproximadamente) - reusa a técnica anterior
    lui   x4, 0x133
    addi  x4, x4, 0x2E0     # x4 := 12_500_000
delay_on:
    addi  x4, x4, -1
    bne   x4, x0, delay_on

    # desloca o LED para a esquerda
    slli  x2, x2, 1        # shift left (x2 <<= 1)

    # se saiu do range de 8 bits (x2 == 0x100), volta para 0x01
    addi  x5, x0, 256
    beq   x2, x5, wrap_to_one

    j     after_wrap_check
wrap_to_one:
    addi  x2, x0, 1        # reset para 0x01
after_wrap_check:

    # escreve o novo pattern (opcional — você verá no próximo passo do clock)
    sh    x2, 0(x1)

    # delay entre passos (meio segundo)
    lui   x4, 0xBEB
    addi  x4, x4, -992
delay_off:
    addi  x4, x4, -1
    bne   x4, x0, delay_off

    j     blink_loop       # repete infinitamente
