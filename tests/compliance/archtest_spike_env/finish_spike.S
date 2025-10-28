    .section .tohost, "aw", @progbits

    .globl tohost
tohost:
    .word 0

    .globl fromhost
fromhost:
    .word 0

    .section .text.finish
    .globl write_tohost_and_halt
write_tohost_and_halt:
    li    t0, 1          # status "ok"
    la    t1, tohost     # endereço global 'tohost'
    sw    t0, 0(t1)      # escreve em tohost pra avisar Spike
1:
    j     1b             # trava aqui