/* L2IP_fixed.ld - Linker script para RV32I Harvard (ROM + RAM, LMA != VMA) */


ENTRY(_start)

MEMORY
{
  ROM (rx) : ORIGIN = 0x00000000, LENGTH = 0x8000
  RAM (rwx): ORIGIN = 0x80000000, LENGTH = 0x4000   /* LINK-time RAM address (avoid overlap) */
}

SECTIONS
{
  /* CODE in ROM (VMA = LMA = 0x00000000) */
  . = ORIGIN(ROM);
  .text :
  {
    KEEP(*(.init))
    *(.text*)
    . = ALIGN(4);
  } > ROM

  /* DATA/RODATA/BSS in RAM (VMA = 0x80000000 so linker doesn't collide with ROM) */
  . = ORIGIN(RAM);

   __rodata_load = .;
  .rodata :
  {
    __srodata = .;
    *(.rodata*)
    . = ALIGN(4);
    __erodata = .;
  } > RAM

  __data_load = .;
  .data :
  {
    __sdata = .;
    *(.data*)
    . = ALIGN(4);
    __edata = .;
  } > RAM

  /* small-data (inicializados pequenos) */
  .sdata :
  {
    __ssdata = .;
    *(.sdata*)
    . = ALIGN(4);
    __esdata = .;
  } > RAM

  /* .bss e .sbss (NOLOAD) */
  .bss (NOLOAD) :
  {
    __sbss = .;
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    __ebss = .;
  } > RAM

  .sbss (NOLOAD) :
  {
    __ssbss = .;
    *(.sbss*)
    . = ALIGN(4);
    __esbss = .;
  } > RAM

  /* symbols visible to crt0 */
  PROVIDE(__rodata_vma = __srodata);
  PROVIDE(__rodata_vma_end = __erodata);
  PROVIDE(__data_vma = __sdata);
  PROVIDE(__data_vma_end = __edata);

  PROVIDE(__HeapBase = __ebss);
  PROVIDE(__StackTop = ORIGIN(RAM) + LENGTH(RAM));
  PROVIDE(end = __ebss);

  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}