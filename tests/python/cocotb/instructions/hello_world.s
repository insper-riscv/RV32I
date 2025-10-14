    .section .text
    .globl _start
_start:
    /* set stack pointer (opcional, ajuste se usar RAM) */
    li    sp, 0x200        /* se seu _estack for esse */

loop:

    addi t1, x0, 0x68
    sw t1, 20(sp)

    addi t1, x0, 0x65
    sw t1, 20(sp)

    addi t1, x0, 0x6c
    sw t1, 20(sp)

    addi t1, x0, 0x6c
    sw t1, 20(sp)

    addi t1, x0, 0x6f
    sw t1, 20(sp)

    j loop