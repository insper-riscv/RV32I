/* Exemplo típico; ajuste nomes da região se necessário */
MEMORY {
  ROM (rx)  : ORIGIN = 0x80000000, LENGTH = 0x20000
  RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 0x10000
}

SECTIONS {
  . = ORIGIN(ROM);
  .text : { *(.text.init) *(.text*) } > ROM
  .rodata : { *(.rodata*) *(.srodata*) } > ROM

  .data : { *(.data*) *(.sdata*) } > RAM AT>ROM
  .bss  : { *(.bss*)  *(.sbss*)  *(COMMON) } > RAM
  .tdata : { *(.tdata*) } > RAM
  .tbss  : { *(.tbss*) } > RAM

  /* Secões usadas por riscv-arch-test p/ assinatura e host */
  .tohost     : { *(.tohost) } > RAM
  .fromhost   : { *(.fromhost) } > RAM
  .signature  : { *(.signature) } > RAM
}

/* Garante símbolos que Spike/env esperam */
PROVIDE(_stack_top = ORIGIN(RAM) + LENGTH(RAM));
PROVIDE(__stack    = _stack_top);

/* Garante ponto de entrada para o linker */
PROVIDE(rvtest_entry_point = ORIGIN(ROM));
PROVIDE(_start             = rvtest_entry_point);