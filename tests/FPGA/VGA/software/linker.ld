/* 32 KB ROM @0x00000000, 64 KB RAM @0x00010000 */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 32K
  RAM (rwx) : ORIGIN = 0x00010000, LENGTH = 64K
}

SECTIONS {
  .text : {
    KEEP(*(.init))
    *(.text .text.*)
    *(.rodata .rodata.* .srodata .srodata.*)
    . = ALIGN(4);
    _etext = .;
  } > ROM

  .data : AT ( _etext ) {
    . = ALIGN(4);
    _sdata = .;
    *(.data .data.*)
    *(.sdata .sdata.*)
    . = ALIGN(4);
    _edata = .;
  } > RAM
  _sidata = LOADADDR(.data);

  .bss (NOLOAD) : {
    . = ALIGN(4);
    _sbss = .;
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
  } > RAM

  . = ORIGIN(RAM) + LENGTH(RAM);
  _stack_top = .;
}
