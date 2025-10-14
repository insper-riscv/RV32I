    .text
    .global _start
_start:
    /* set stack pointer to end of IRAM (stack top) */
    li sp, 0x80000800        /* _estack (end of IRAM) */

    /* base address for HEX MMIO */
    li t0, 0x80000800        /* t0 = HEX_BASE */

    /* Delay count (approx for ~200 ms at 50 MHz)
       Adjust DELAY_COUNT down/up to speed up/slow down. */
    li t2, 3333333           /* DELAY_COUNT approx (tuned for ~200ms) */

    /* -- Main loop: 8 window positions (message length 13, window 6) -- */
    /* We'll unroll every position to avoid data-indexing and linker needs. */

loop_pos0:
    /* position 0: chars [0..5] = " HELLO" */
    li t1, 0x20              /* ' ' */
    sw  t1, 0(t0)            /* HEX0 = ' ' */
    li t1, 0x48              /* 'H' */
    sw  t1, 4(t0)            /* HEX1 = 'H' */
    li t1, 0x45              /* 'E' */
    sw  t1, 8(t0)            /* HEX2 = 'E' */
    li t1, 0x4C              /* 'L' */
    sw  t1, 12(t0)           /* HEX3 = 'L' */
    li t1, 0x4C              /* 'L' */
    sw  t1, 16(t0)           /* HEX4 = 'L' */
    li t1, 0x4F              /* 'O' */
    sw  t1, 20(t0)           /* HEX5 = 'O' */

    /* delay */
    jal ra, delay_loop

loop_pos1:
    /* position 1: chars [1..6] = "HELLO " */
    li t1, 0x48
    sw  t1, 0(t0)
    li t1, 0x45
    sw  t1, 4(t0)
    li t1, 0x4C
    sw  t1, 8(t0)
    li t1, 0x4C
    sw  t1, 12(t0)
    li t1, 0x4F
    sw  t1, 16(t0)
    li t1, 0x20
    sw  t1, 20(t0)
    jal ra, delay_loop

loop_pos2:
    /* position 2: chars [2..7] = "ELLO W" */
    li t1, 0x45
    sw  t1, 0(t0)
    li t1, 0x4C
    sw  t1, 4(t0)
    li t1, 0x4C
    sw  t1, 8(t0)
    li t1, 0x4F
    sw  t1, 12(t0)
    li t1, 0x20
    sw  t1, 16(t0)
    li t1, 0x57              /* 'W' */
    sw  t1, 20(t0)
    jal ra, delay_loop

loop_pos3:
    /* position 3: chars [3..8] = "LLO WO" */
    li t1, 0x4C
    sw  t1, 0(t0)
    li t1, 0x4C
    sw  t1, 4(t0)
    li t1, 0x4F
    sw  t1, 8(t0)
    li t1, 0x20
    sw  t1, 12(t0)
    li t1, 0x57
    sw  t1, 16(t0)
    li t1, 0x4F
    sw  t1, 20(t0)
    jal ra, delay_loop

loop_pos4:
    /* position 4: chars [4..9] = "LO WOR" */
    li t1, 0x4C
    sw  t1, 0(t0)
    li t1, 0x4F
    sw  t1, 4(t0)
    li t1, 0x20
    sw  t1, 8(t0)
    li t1, 0x57
    sw  t1, 12(t0)
    li t1, 0x4F
    sw  t1, 16(t0)
    li t1, 0x52              /* 'R' */
    sw  t1, 20(t0)
    jal ra, delay_loop

loop_pos5:
    /* position 5: chars [5..10] = "O WORL" */
    li t1, 0x4F
    sw  t1, 0(t0)
    li t1, 0x20
    sw  t1, 4(t0)
    li t1, 0x57
    sw  t1, 8(t0)
    li t1, 0x4F
    sw  t1, 12(t0)
    li t1, 0x52
    sw  t1, 16(t0)
    li t1, 0x4C
    sw  t1, 20(t0)
    jal ra, delay_loop

loop_pos6:
    /* position 6: chars [6..11] = " WORLD" */
    li t1, 0x20
    sw  t1, 0(t0)
    li t1, 0x57
    sw  t1, 4(t0)
    li t1, 0x4F
    sw  t1, 8(t0)
    li t1, 0x52
    sw  t1, 12(t0)
    li t1, 0x4C
    sw  t1, 16(t0)
    li t1, 0x44              /* 'D' */
    sw  t1, 20(t0)
    jal ra, delay_loop

loop_pos7:
    /* position 7: chars [7..12] = "WORLD " */
    li t1, 0x57
    sw  t1, 0(t0)
    li t1, 0x4F
    sw  t1, 4(t0)
    li t1, 0x52
    sw  t1, 8(t0)
    li t1, 0x4C
    sw  t1, 12(t0)
    li t1, 0x44
    sw  t1, 16(t0)
    li t1, 0x20
    sw  t1, 20(t0)
    jal ra, delay_loop

    /* After last position loop back to pos0 forever */
    j loop_pos0

/* ----------------- delay routine -----------------
   Uses t2 as the outer loop count (preset in _start).
   Returns in ra (we use jal ra, delay_loop to call).
--------------------------------------------------*/
delay_loop:
    /* Save ra? Not necessary because we use jal ra to call and immediate ret via jr ra.
       But to be safe we won't clobber ra except for the return */
    mv t3, t2        /* t3 = loop counter */
1:
    addi t3, t3, -1
    bnez t3, 1b
    jr ra            /* return to caller */
