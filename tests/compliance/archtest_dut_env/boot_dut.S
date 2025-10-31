    .section .text.init
    .globl _start
_start:
    la   t0, __data_load_start   # origem em ROM (LMA)
    la   t1, __data_start        # destino em RAM (VMA 0x2000....)
    la   t2, __data_end          # fim do destino

1:
    beq  t1, t2, 2f
    lw   t3, 0(t0)
    sw   t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    j    1b

2:
    la   t1, __bss_start
    la   t2, __bss_end

3:
    beq  t1, t2, 4f
    sw   x0, 0(t1)
    addi t1, t1, 4
    j    3b

4:
    .ifdef DEBUG_SIGFILL
    la   t1, begin_signature
    la   t2, end_signature
    li   t3, 0xDEADBEEF

5:
    beq  t1, t2, 6f
    sw   t3, 0(t1)
    addi t1, t1, 4
    j    5b
6:
    .endif
    la   sp, __stack_top
    j    rvtest_entry_point

hang:
    j hang