OUTPUT_ARCH( "riscv" )
ENTRY(rvtest_entry_point)

MEMORY{
  ROM(rx) : ORIGIN=0x00000000, LENGTH=64K
  RAM(rw) : ORIGIN=0x20000000, LENGTH=64K
}

SECTIONS
{
  .text.init : { KEEP(*(.text.init)) *(.init)} > ROM
  .tohost : { . = ALIGN(8); *(.tohost) } > RAM
  .text      : { *(.text .text.*) *(.rodata .rodata.*) } > ROM
  .data : { *(.sdata .sdata.*) *(.data .data.*) } > RAM AT> ROM
  .data.string : { *(.data.string)}
  .bss  (NOLOAD) : { *(.sbss .sbss.*) *(.bss .bss.* COMMON) } > RAM
  . = ALIGN(16);
  .signature :
  {
    KEEP(*(.signature))
    KEEP(*(.signature.*))
  } > RAM

  PROVIDE(begin_signature = ADDR(.signature));
  PROVIDE(end_signature   = ADDR(.signature) + SIZEOF(.signature));
  
  _end = .;
}