ENTRY(rvtest_entry_point)
PROVIDE(_start = rvtest_entry_point);

MEMORY {
  ROM (rx) : ORIGIN = 0x80000000, LENGTH = 0x20000   /* 128 KiB */
  RAM (rw) : ORIGIN = 0x20000000, LENGTH = 0x10000   /* 64 KiB  */
}

SECTIONS
{
  /* Código/rodata em DRAM alta (0x8000_0000) */
  .text 0x80000000 :
  {
    KEEP(*(.text.init))
    *(.text .text.*)
    *(.rodata .rodata.*)
  } > ROM

  /* Dados em RAM (VADDR = PADDR) */
  .data :
  {
    *(.sdata .sdata.*)
    *(.data .data.*)
  } > RAM

  .bss (NOLOAD) :
  {
    *(.sbss .sbss.*)
    *(.bss .bss.*)
    *(COMMON)
  } > RAM

  /* HTIF */
  .tohost :
  {
    PROVIDE(tohost = .);
    LONG(0);
  } > RAM

  .fromhost :
  {
    PROVIDE(fromhost = .);
    LONG(0);
  } > RAM

  /* Assinatura (NOLOAD) em RAM */
  .signature (NOLOAD) :
  {
    . = ALIGN(16);
    PROVIDE(begin_signature = .);
    . = . + 0x1000;      /* janela de 4 KiB */
    PROVIDE(end_signature = .);
  } > RAM

  PROVIDE(__stack_top = ORIGIN(RAM) + LENGTH(RAM));
}