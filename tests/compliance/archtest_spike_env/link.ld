ENTRY(_start)

/* Mesma configuração que passamos pro spike com -m:
   ROM: 0x80000000, 1 MiB
   RAM: 0x20000000, 64 KiB */
MEMORY {
    ROM (rx) : ORIGIN = 0x80000000, LENGTH = 0x00100000
    RAM (rw) : ORIGIN = 0x20000000, LENGTH = 0x00010000
}

/* topo da pilha = fim da RAM */
_stack_top = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
    /* Código em ROM */
    . = ORIGIN(ROM);

    .text : {
        *(.text.init)
        *(.text*)
        *(.rodata*)
        *(.srodata*)
    } > ROM

    /* Dados inicializados em RAM, mas com carga em ROM.
       Vamos expor símbolos pra copiar no boot. */
    .data : {
        __data_start = .;
        *(.data*)
        *(.sdata*)
        __data_end = .;
    } > RAM AT>ROM
    __data_load_start = LOADADDR(.data);

    /* BSS em RAM, precisa zerar no boot */
    .bss (NOLOAD) : {
        __bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(COMMON)
        __bss_end = .;
    } > RAM

    /* Assinatura. Alguns testes colocam labels begin_signature/end_signature
       em blocos de dados; outros usam seções .signature*. Vamos aceitar ambos. */
    .signature ALIGN(16) : {
        /* se o teste já definiu begin_signature/end_signature, beleza.
           se não definiu, PROVIDE cria por fallback */
        PROVIDE(begin_signature = .);
        *(.signature*)
        PROVIDE(end_signature = .);
    } > RAM

    /* Host interface */
    .tohost ALIGN(16) : {
        *(.tohost)
        *(.fromhost)
    } > RAM
}

/* símbolos de compat */
PROVIDE(__stack = _stack_top);
/* fallback caso algum teste não defina explicitamente rvtest_entry_point */
PROVIDE(rvtest_entry_point = ORIGIN(ROM));
/* _start já vem do boot_spike.S, ENTRY(_start) garante e_entry */