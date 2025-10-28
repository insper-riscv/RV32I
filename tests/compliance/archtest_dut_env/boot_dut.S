    .section .text.init
    .globl _start
_start:
    la   sp, __stack_top

    j    rvtest_entry_point

hang:
    j    hang