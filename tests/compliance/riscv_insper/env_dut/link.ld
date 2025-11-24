OUTPUT_ARCH(riscv)
ENTRY(rvtest_entry_point)

MEMORY {
  ROM (rx) : ORIGIN = 0x00000000, LENGTH = 2048K
  RAM (rw) : ORIGIN = 0x20000000, LENGTH = 64K
}

SECTIONS
{
  .text.init : { KEEP(*(.text.init)) *(.init) } > ROM
  .text      : { *(.text .text.*) *(.rodata .rodata.*) } > ROM
  .tohost    : { *(.tohost) } > RAM
  .data : {
    *(.sdata .sdata.*) *(.data .data.*)
  } > RAM AT> ROM
  .bss (NOLOAD) : {
    *(.sbss .sbss.*) *(.bss .bss.* COMMON)
  } > RAM
  .signature : { KEEP(*(.signature)) KEEP(*(.signature.*)) } > RAM
  . = ALIGN(16);
  PROVIDE(begin_signature = ADDR(.signature));
  PROVIDE(end_signature   = ADDR(.signature) + SIZEOF(.signature));
  _end = .;
}