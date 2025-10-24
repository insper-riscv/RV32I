OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  ram (rwx) : ORIGIN = 0x1000, LENGTH = 8M
}

SECTIONS
{
  .text : {
    *(.text.entry)
    *(.text .text.*)
  } > ram

  .rodata : { *(.rodata .rodata.*) } > ram
  .data   : { *(.data .data.*) } > ram
  .bss    : { *(.bss .bss.* COMMON) } > ram

  /* Os símbolos de assinatura vêm dos próprios testes/env do arch-test */
  PROVIDE(begin_signature = .);
  .signature : { *(.signature) } > ram
  PROVIDE(end_signature = .);
}