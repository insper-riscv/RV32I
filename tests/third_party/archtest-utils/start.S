    .section .text.init
    .globl _start
_start:
    la   sp, __stack_top

    .globl RVTEST_CODE_BEGIN
RVTEST_CODE_BEGIN:

    .globl RVTEST_CODE_END
RVTEST_CODE_END:
1:  j 1b

    .section .signature,"aw",@progbits
    .globl begin_signature
    .globl end_signature
