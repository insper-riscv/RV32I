OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  ROM (rx) : ORIGIN = 0x00000000, LENGTH = 128K
  RAM (rw) : ORIGIN = 0x20000000, LENGTH = 64K
}

SECTIONS {
  .text : { *(.text.init) *(.text .text.*) } > ROM
  .rodata : { *(.rodata .rodata.*) } > ROM
  .data : { *(.data .data.* .sdata .sdata.*) } > RAM AT> ROM
  .bss (NOLOAD) : { *(.bss .bss.* .sbss .sbss.*) *(COMMON) } > RAM

  .signature ALIGN(16) : {
    PROVIDE(begin_signature = .);
    *(.test_signature)
    . = ALIGN(16);
    PROVIDE(end_signature = .);
  } > RAM

  PROVIDE(__stack_top = ORIGIN(RAM) + LENGTH(RAM));
}