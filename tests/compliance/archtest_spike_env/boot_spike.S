    .section .text.init
    .globl _start
    .globl rvtest_entry_point

    .equ CSR_MTVEC,   0x305
    .equ CSR_MSTATUS, 0x300

_start:
    ################################################
    # 0. copiar .data inicializada da ROM -> RAM
    #    usa símbolos que o link.ld exporta
    ################################################
    la   t0, __data_load_start   # origem em ROM
    la   t1, __data_start        # destino em RAM
    la   t2, __data_end          # fim do destino

1:
    beq  t1, t2, 2f              # acabou a cópia?
    lw   t3, 0(t0)               # carrega palavra da ROM
    sw   t3, 0(t1)               # escreve na RAM
    addi t0, t0, 4
    addi t1, t1, 4
    j    1b

2:
    ################################################
    # 1. zerar .bss
    ################################################
    la   t1, __bss_start
    la   t2, __bss_end
3:
    beq  t1, t2, 4f
    sw   x0, 0(t1)
    addi t1, t1, 4
    j    3b

4:
    ################################################
    # 2. configura stack pointer
    ################################################
    la   sp, _stack_top

    ################################################
    # 3. configura trap handler simples em mtvec
    ################################################
    la   t0, trap_handler
    csrw CSR_MTVEC, t0

    ################################################
    # 4. limpa bits chatos em mstatus (tira MIE/MPP etc)
    ################################################
    csrr t1, CSR_MSTATUS
    li   t2, ~(0x188)       # máscara grossa pra limpar MIE/MPIE/MPP
    and  t1, t1, t2
    csrw CSR_MSTATUS, t1

    ################################################
    # 5. pula pro ponto de entrada definido pelo teste
    ################################################
    j    rvtest_entry_point


################################################
# Trap handler:
# Se der exceção inesperada, escreve um código
# em 'tohost' e trava. Isso faz Spike concluir.
################################################
trap_handler:
    .globl tohost
    la   t5, tohost
    li   t6, 0x1badfeed
5:
    sw   t6, 0(t5)
    j    5b