OUTPUT_ARCH(riscv)
ENTRY(rvtest_entry_point)

MEMORY {
  ROM (rx) : ORIGIN = 0x00000000, LENGTH = 64K
  RAM (rw) : ORIGIN = 0x20000000, LENGTH = 64K
}

SECTIONS
{
  .text.init : { KEEP(*(.text.init)) *(.init) } > ROM
  .tohost    : { *(.tohost) } > ROM
  .text      : { *(.text .text.*) *(.rodata .rodata.*) } > ROM

  /* Dados residem em RAM, mas são inicializados a partir da ROM */
  .data : {
    *(.sdata .sdata.*) *(.data .data.*)
  } > RAM AT> ROM

  .bss (NOLOAD) : {
    *(.sbss .sbss.*) *(.bss .bss.* COMMON)
  } > RAM

  . = ALIGN(16);
  .signature (NOLOAD) : {
    begin_signature = .;
    *(.signature*)
    . = ALIGN(16);
    end_signature = .;
  } > RAM

  _end = .;
}