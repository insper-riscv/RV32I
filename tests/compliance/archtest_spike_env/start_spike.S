    .section .text.init
    .globl _start
    .globl rvtest_entry_point

# Entry point pro Spike.
# Ajusta a stack, entra no corpo do teste,
# e depois pede pra finalizar.

_start:
rvtest_entry_point:
    # stack pointer aponta pro topo da RAM (definido em signature_spike.S)
    la   sp, _stack_top

    # chama o corpo do teste (entre rvtest_code_begin / rvtest_code_end)
    jal  ra, rvtest_code_begin

    # terminou o teste -> escreve em tohost e trava (Spike entende isso como "acabou")
    jal  ra, write_tohost_and_halt

1:
    j 1b   # fallback: loop infinito

    # Labels que o riscv-arch-test espera
    .globl rvtest_code_begin
    .globl rvtest_code_end
rvtest_code_begin:
    # o próprio teste .S vai injetar o código real aqui via macros

rvtest_code_end:
    ret