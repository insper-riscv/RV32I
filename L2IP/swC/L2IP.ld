/* L2IP.ld - Linker script para L2IP (RV32I, Harvard simples)
   ROM: 512 words x 4 = 2048 bytes at address 0x00000000 (instruction memory)
   RAM: 512 words x 4 = 2048 bytes at address 0x00000000 (data memory)
   NOTE: ORIGINs are both 0 because arquitetura Harvard usa espaços separados.
*/

ENTRY(_start)

MEMORY
{
  FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 2048    /* instruções (ROM) */
  RAM   (rwx): ORIGIN = 0x00000000, LENGTH = 2048    /* dados (RAM) */
}

/* Output sections */
SECTIONS
{
    /* código (vai para ROM) */
    .text :
    {
    KEEP(*(.init))            /* caso tenha inicializadores em assembly */
    *(.text*)                 /* todo código */
    . = ALIGN(4);
    } > FLASH

    /* descartamos .rodata — não permitimos constantes em ROM/data reads */
    /DISCARD/ : { *(.rodata*) *(.constdata*) }

    /* .data em RAM, mas sem área de carga em FLASH (sem copy) -> NOBITS (zerada) */
    . = ORIGIN(RAM);

    /* .data and .bss as before */
    .data (NOLOAD) : { __sdata = .; *(.data*) __edata = .; } > RAM
    .bss  (NOLOAD) : { __sbss = .; *(.bss*) *(COMMON) __ebss = .; } > RAM

    . = ALIGN(4);

    /* símbolos úteis para startup / libc */
    PROVIDE(__HeapBase = __ebss);                       /* heap começa logo após .bss */
    PROVIDE(__StackTop = ORIGIN(RAM) + LENGTH(RAM));    /* topo da pilha (SP inicial) */
    PROVIDE(__StackLimit = __StackTop);                 /* sem limite reservado (dinâmico) */

    PROVIDE(end = __ebss);

    /* remover seções de exceções / debug que não queremos */
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
