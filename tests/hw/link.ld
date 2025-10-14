OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY { RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 512K }

SECTIONS {
  .text : { *(.init) *(.text*) *(.rodata*) } > RAM

  .data : { *(.data*) *(.sdata*) *(.bss*) *(.sbss*) *(COMMON) } > RAM

  .signature ALIGN(16) : {
    PROVIDE(begin_signature = .);
    KEEP(*(.signature))
    PROVIDE(end_signature = .);
  } > RAM

  /DISCARD/ : { *(.comment*) *(.note*) }
}