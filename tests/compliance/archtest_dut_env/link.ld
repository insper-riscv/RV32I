OUTPUT_ARCH(riscv)
ENTRY(_start)

/*
  Mapa de memória para o DUT em simulação:
  - ROM começa em 0x00000000
  - RAM começa em 0x20000000
  - RAM tem 64 KiB (RAM_big: memoryAddrWidth=14 => 2^14 palavras * 4 bytes = 65536 bytes)
*/

MEMORY {
  ROM (rx) : ORIGIN = 0x00000000, LENGTH = 128K
  RAM (rw) : ORIGIN = 0x20000000, LENGTH = 64K
}

SECTIONS
{
  /* Código e constantes -> ROM */
  .text : {
    KEEP(*(.text.init))
    *(.text .text.*)
    *(.rodata .rodata.*)
    *(.srodata .srodata.*)
  } > ROM

  /*
    Dados inicializados:
    - Vão morar em RAM em runtime,
    - Mas a imagem inicial fica em ROM (AT>ROM)
    - boot_dut.S copia __data_load_start -> [__data_start .. __data_end)
  */
  .data : {
    __data_start = .;
    *(.data .data.*)
    *(.sdata .sdata.*)
    __data_end = .;
  } > RAM AT>ROM
  __data_load_start = LOADADDR(.data);

  /*
    BSS não inicializada:
    - boot_dut.S zera [__bss_start .. __bss_end)
  */
  .bss (NOLOAD) : {
    __bss_start = .;
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
    __bss_end = .;
  } > RAM

  /*
    Buffer de assinatura para o arch test.
    IMPORTANTE:
    - Aqui a gente RESERVA 0x938 bytes manualmente.
    - Isso garante que end_signature - begin_signature = 0x938 (2360 bytes),
      que foi exatamente o tamanho visto no Spike para add-01.
    - O teste vai usar begin_signature como base para gravar resultados,
      e o testbench vai ler [begin_signature, end_signature).
  */
  .signature (NOLOAD) : {
    . = ALIGN(16);
    begin_signature = .;
    . = . + 0x938;   /* reserva ~2360 bytes exatamente */
    end_signature = .;
  } > RAM

  /*
    tohost:
    - O teste escreve 1 aqui pra sinalizar "fim".
    - Cocotb fica olhando esse endereço.
    - Mantemos alinhamento grande pra ficar depois da assinatura.
  */
  .tohost (NOLOAD) : {
    . = ALIGN(256);
    tohost = .;
    . = . + 4;
  } > RAM


  /*
    Topo da pilha (stack cresce pra baixo).
    boot_dut.S faz "la sp, __stack_top"
  */
  __stack_top = ORIGIN(RAM) + LENGTH(RAM);

  /*
    fallback caso rvtest_entry_point não esteja no teste
  */
  PROVIDE(rvtest_entry_point = _start);
}