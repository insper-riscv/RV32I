#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H
#if XLEN == 64
  #define ALIGNMENT 3
#else
  #define ALIGNMENT 2
#endif

#define RVMODEL_DATA_SECTION \
        .pushsection .tohost,"aw",@progbits;                            \
        .align 8; .global tohost; tohost: .dword 0;                     \
        .align 8; .global fromhost; fromhost: .dword 0;                 \
        .popsection;                                                    \
        .align 8; .global begin_regstate; begin_regstate:               \
        .word 128;                                                      \
        .align 8; .global end_regstate; end_regstate:                   \
        .word 4;

//RV_COMPLIANCE_HALT
#define RVMODEL_HALT                                              \
  li x1, 1;                                                                   \
  write_tohost:                                                               \
    sw x1, tohost, t5;                                                        \
    j write_tohost;

#define RVMODEL_BOOT

// RV_COMPLIANCE_DATA_BEGIN
#undef RVMODEL_DATA_BEGIN
#define RVMODEL_DATA_BEGIN                                  \
  RVMODEL_DATA_SECTION                                      \
  .pushsection .signature,"aw",@progbits;                   \
  .align ALIGNMENT;                                         \
  .global begin_signature; begin_signature:

//RV_COMPLIANCE_DATA_END
#undef RVMODEL_DATA_END
#define RVMODEL_DATA_END                                    \
  .global end_signature; end_signature:                     \
  .popsection 

//RVTEST_IO_INIT
#define RVMODEL_IO_INIT
//RVTEST_IO_WRITE_STR
#define RVMODEL_IO_WRITE_STR(_R, _STR)
//RVTEST_IO_CHECK
#define RVMODEL_IO_CHECK()

/* RV32 only */
#define BYTES_PER_WORD 4
#define STORE_GPR      sw
#define STORE_SFPR     fsw
#define STORE_DFPR     fsd

/* Write a GPR value into the signature at slot _I */
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I) \
  la   _S, begin_signature;                  \
  addi _S, _S, ((_I) * BYTES_PER_WORD);      \
  STORE_GPR _R, 0(_S);

/* Float versions (harmless even if you don't run FP tests) */
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I) \
  la   _F, begin_signature;                   \
  addi _F, _F, ((_I) * BYTES_PER_WORD);       \
  STORE_SFPR _R, 0(_F);

#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I) \
  la   _D, begin_signature;                   \
  addi _D, _D, ((_I) * BYTES_PER_WORD);       \
  STORE_DFPR _R, 0(_D);

#define RVMODEL_SET_MSW_INT

#define RVMODEL_CLEAR_MSW_INT

#define RVMODEL_CLEAR_MTIMER_INT

#define RVMODEL_CLEAR_MEXT_INT


#endif // _COMPLIANCE_MODEL_H