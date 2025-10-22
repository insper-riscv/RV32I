    .section .text
    .globl _start

_start:
    # ==== TESTE JAL ====
    jal   x5, 8            # x5 = PC+4, PC = PC+8

    # Instrução pulada (NOP real)
    addi  x6, x7, 0        

    # Instrução destino do JAL
    add   x6, x5, x0       # expõe link em x6

    # ==== TESTE JALR ====
    jalr  x7, x5, 0        # x7 = PC+4, PC = (x5+0)&~1 (volta ao endereço salvo)

    addi  x0, x0, 0        # NOP após o retorno

1:  j 1b