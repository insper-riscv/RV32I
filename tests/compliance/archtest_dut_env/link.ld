OUTPUT_ARCH(riscv)
ENTRY(_start)

/*
  Mapa de memória para o DUT em simulação:
  - ROM começa em 0x00000000
  - RAM começa em 0x20000000
  - RAM tem 64 KiB (RAM_big: memoryAddrWidth=14 => 2^14 palavras * 4 bytes = 65536 bytes)
*/

MEMORY {
  ROM (rx) : ORIGIN = 0x00000000, LENGTH = 64K
  RAM (rw) : ORIGIN = 0x20000000, LENGTH = 64K
}

SECTIONS
{
  .text : {
    KEEP(*(.text.init))
    *(.text .text.*)
    *(.rodata .rodata.*)
    *(.srodata .srodata.*)
  } > ROM

  .data : {
    __data_start = .;
    *(.data .data.*)
    *(.sdata .sdata.*)
    *(.tohost) *(.fromhost)
    __data_end = .;
  } > RAM AT>ROM
  __data_load_start = LOADADDR(.data);

  .bss (NOLOAD) : {
    __bss_start = .;
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
    __bss_end = .;
  } > RAM

  .signature ALIGN(16) : {
      PROVIDE(begin_signature = .);
      PROVIDE(signature       = begin_signature);
      PROVIDE(rvtest_sig_begin = begin_signature);

      *(.signature*)

      PROVIDE(end_signature = .);
      PROVIDE(endsignature  = end_signature);
      PROVIDE(rvtest_sig_end = end_signature);
  } > RAM

  __stack_top = ORIGIN(RAM) + LENGTH(RAM);

  PROVIDE(rvtest_entry_point = _start);
  PROVIDE(rvtest_sig_begin = begin_signature);
  PROVIDE(rvtest_sig_end   = end_signature);
  PROVIDE(sig_begin = begin_signature);
  PROVIDE(sig_end   = end_signature);
}