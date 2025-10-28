    .section .text.init
    .globl _start
_start:
    la   sp, __stack_top

    .globl RVTEST_CODE_BEGIN
RVTEST_CODE_BEGIN:

    .globl RVTEST_CODE_END
RVTEST_CODE_END:
    .option push
    .option norvc
    lui  t0, %hi(tohost)
    addi t0, t0, %lo(tohost)
    li   t1, 1
    sw   t1, 0(t0)
1:  j    1b
    .option pop

    .section .signature,"aw",@progbits
    .globl begin_signature
    .globl end_signature
