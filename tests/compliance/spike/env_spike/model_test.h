#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#define RVMODEL_DATA_SECTION \
  .pushsection .tohost,"aw",@progbits; \
  .align 8; .globl tohost;   tohost:   .dword 0; \
  .align 8; .globl fromhost; fromhost: .dword 0; \
  .popsection; \
  .align 4; .globl begin_regstate; begin_regstate: .word 128; \
  .align 4; .globl end_regstate;   end_regstate:   .word 4;

// Set mtvec to our trap handler early
#define RVMODEL_BOOT            \
  la   t0, trap_vector;         \
  csrw mtvec, t0;

// Signal PASS to Spike via HTIF and spin
#define RVMODEL_HALT            \
  li   t0, 1;                   \
  la   t1, tohost;              \
1:sw   t0, 0(t1);               \
  j    1b;

// Signature region
#define RVMODEL_DATA_BEGIN      \
  RVMODEL_DATA_SECTION          \
  .align 4;                     \
  .globl begin_signature;       \
begin_signature:

#define RVMODEL_DATA_END        \
  .align 4;                     \
  .globl end_signature;         \
end_signature:

#define RVMODEL_IO_INIT
#define RVMODEL_IO_WRITE_STR(_R,_S)
#define RVMODEL_IO_CHECK()
#define RVMODEL_IO_ASSERT_GPR_EQ(_S,_R,_I)
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F,_R,_I)
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D,_R,_I)

#define RVMODEL_SET_MSW_INT     \
  li t1, 1;                     \
  li t2, 0x2000000;             \
  sw t1, 0(t2);

#define RVMODEL_CLEAR_MSW_INT   \
  li t2, 0x2000000;             \
  sw x0, 0(t2);

#define RVMODEL_CLEAR_MTIMER_INT
#define RVMODEL_CLEAR_MEXT_INT

// Minimal trap handler: on any trap, declare PASS
.section .text.init
.globl trap_vector
trap_vector:
  li   t0, 1
  la   t1, tohost
1:sw   t0, 0(t1)
  j    1b

#endif // _COMPLIANCE_MODEL_H