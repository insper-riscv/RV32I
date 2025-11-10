    /* startup_L2IP.S - startup minimal para RV32I (L2IP)
       - inicializa SP com __StackTop
       - zera .bss (entre __sbss e __ebss)
       - chama main()
       - loop infinito após retorno de main
    */

    .section .text
    .globl _start
    .type _start, @function

_start:
    /* Inicializa stack pointer (sp) */
    la   sp, __StackTop      /* sp = __StackTop */

    /* Chama rotina de reset / init (opcional) */
    call Reset_Handler

    /* Se Reset_Handler retornar, entra em loop */
hang:
    j hang

    .size _start, .-_start

/* Reset handler: zera .bss e chama main */
    .globl Reset_Handler
    .type Reset_Handler, @function
Reset_Handler:
    /* Zerando .bss: t0 = start, t1 = end */
    la   t0, __sbss
    la   t1, __esbss
    beq  t0, t1, .L_bss_done

.L_bss_loop:
    sw   x0, 0(t0)      /* word zero */
    addi t0, t0, 4
    bne  t0, t1, .L_bss_loop

.L_bss_done:
    /* Chama main() */
    call main

    /* Se main retornar, entra em loop infinito */
.L_after_main:
    j .L_after_main

    .size Reset_Handler, .-Reset_Handler
