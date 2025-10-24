OUTPUT_ARCH(riscv)
ENTRY(_start)

/* RAM: 0x00000000 .. 0x007FFFFF (8 MiB)
   SIG: 0x00800000 .. 0x0080FFFF (64 KiB reservados p/ assinatura) */

MEMORY {
  ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x800000
  sig (rw)  : ORIGIN = 0x00800000, LENGTH = 0x10000
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

  /* A assinatura vai numa região separada de RAM para o Spike mapear como device */
  PROVIDE(begin_signature = .);
  .signature : { *(.signature) } > sig
  PROVIDE(end_signature = .);
}
