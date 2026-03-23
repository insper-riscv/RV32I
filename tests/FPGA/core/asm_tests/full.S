    .section .text
    .globl main

# ---------------------------------------------------------
# Constantes de endereço na RAM
# ---------------------------------------------------------
    .equ RESULTS_BASE,    0x00000000
    .equ TEST_DATA_BASE,  0x00000100
    .equ TEMP_SLOT_BASE,  0x00000200

# ---------------------------------------------------------
# main
#   x5  (t0) → ponteiro de escrita em RESULTS_BASE
#   x8  (s0) → base de TEST_DATA_BASE
#   x9  (s1) → base de TEMP_SLOT_BASE
# ---------------------------------------------------------

main:
    # Ponteiro de resultados: começa em 0x00000000
    addi x5, x0, 0                # x5 = RESULTS_BASE

    # Ponteiros auxiliares
    addi x8, x0, TEST_DATA_BASE   # x8 = TEST_DATA_BASE
    addi x9, x0, TEMP_SLOT_BASE   # x9 = TEMP_SLOT_BASE

    # ------------------------------------------------------
    # Inicializa região de TEST_DATA_BASE na RAM
    # ------------------------------------------------------

    # bytes: [0]=0x11, [1]=0x22, [2]=0xFF, [3]=0x80
    addi x10, x0, 0x11
    sb   x10, 0(x8)

    addi x10, x0, 0x22
    sb   x10, 1(x8)

    addi x10, x0, -1              # 0xFF
    sb   x10, 2(x8)

    addi x10, x0, -128            # 0x80 (signed)
    sb   x10, 3(x8)

    # half em [4..5]: 0x1234
    addi x10, x0, 0x12
    slli x10, x10, 8              # 0x1200
    ori  x10, x10, 0x34           # 0x1234
    sh   x10, 4(x8)

    # word em [8..11]: 0x12345678
    lui  x10, 0x12345             # 0x12345000
    addi x10, x10, 0x678          # 0x12345678
    sw   x10, 8(x8)

###########################################################
# 1. Aritmética básica: ADD, ADDI, SUB
###########################################################

    # ADDI: x11 = 5
    addi x11, x0, 5
    # ADDI: x12 = 7
    addi x12, x0, 7

    # ADD: x13 = 5 + 7 = 12
    add  x13, x11, x12
    sw   x13, 0(x5)
    addi x5, x5, 4

    # SUB: x14 = 7 - 5 = 2
    sub  x14, x12, x11
    sw   x14, 0(x5)
    addi x5, x5, 4

    # ADDI com negativo: x15 = -1
    addi x15, x0, -1
    sw   x15, 0(x5)
    addi x5, x5, 4

###########################################################
# 2. LUI e AUIPC (teste baseado em diferença)
###########################################################

    # LUI: x16 = 0x12345000
    lui  x16, 0x12345
    sw   x16, 0(x5)
    addi x5, x5, 4

    # AUIPC: diferença entre dois AUIPC com mesmo imediato
auipc_test_1:
    auipc x17, 0x1                # x17 = PC1 + 0x1000
auipc_test_2:
    auipc x18, 0x1                # x18 = PC2 + 0x1000
    sub   x19, x18, x17           # = PC2 - PC1 (constante)
    sw    x19, 0(x5)
    addi  x5, x5, 4

###########################################################
# 3. Lógicos: XOR, OR, AND, e imediatos
###########################################################

    # x20 = 0x000000FF
    addi x20, x0, 0x0F0
    ori  x20, x20, 0x00F          # 0x0FF

    # x21 = 0x000000F0
    addi x21, x0, 0x0F0

    # XOR
    xor  x22, x20, x21
    sw   x22, 0(x5)
    addi x5, x5, 4

    # OR
    or   x23, x20, x21
    sw   x23, 0(x5)
    addi x5, x5, 4

    # AND
    and  x24, x20, x21
    sw   x24, 0(x5)
    addi x5, x5, 4

    # XORI
    xori x25, x20, 0x00F
    sw   x25, 0(x5)
    addi x5, x5, 4

    # ORI
    ori  x26, x20, 0x00F
    sw   x26, 0(x5)
    addi x5, x5, 4

    # ANDI
    andi x27, x20, 0x00F
    sw   x27, 0(x5)
    addi x5, x5, 4

###########################################################
# 4. Comparações: SLT, SLTU, SLTI, SLTIU
###########################################################

    # x28 = -5, x29 = 3
    addi x28, x0, -5
    addi x29, x0, 3

    # SLT signed: -5 < 3 → 1
    slt  x30, x28, x29
    sw   x30, 0(x5)
    addi x5, x5, 4

    # SLTU unsigned: 0xFFFFFFFB < 3 → 0
    sltu x31, x28, x29
    sw   x31, 0(x5)
    addi x5, x5, 4

    # SLTI: 3 < 10 → 1
    addi x10, x0, 3
    slti x10, x10, 10
    sw   x10, 0(x5)
    addi x5, x5, 4

    # SLTIU: 3 < 1 unsigned → 0
    addi x11, x0, 3
    sltiu x11, x11, 1
    sw   x11, 0(x5)
    addi x5, x5, 4

###########################################################
# 5. Shifts: SLL, SRL, SRA, SLLI, SRLI, SRAI
###########################################################

    # SLL: 1 << 4 = 16
    addi x12, x0, 1
    addi x13, x0, 4
    sll  x14, x12, x13
    sw   x14, 0(x5)
    addi x5, x5, 4

    # SRL: 16 >> 2 = 4
    addi x15, x0, 16
    addi x16, x0, 2
    srl  x17, x15, x16
    sw   x17, 0(x5)
    addi x5, x5, 4

    # SRA: -16 >> 2 = -4
    addi x18, x0, -16
    addi x19, x0, 2
    sra  x20, x18, x19
    sw   x20, 0(x5)
    addi x5, x5, 4

    # SLLI: 1 << 3 = 8
    addi x21, x0, 1
    slli x22, x21, 3
    sw   x22, 0(x5)
    addi x5, x5, 4

    # SRLI: 32 >> 3 = 4
    addi x23, x0, 32
    srli x24, x23, 3
    sw   x24, 0(x5)
    addi x5, x5, 4

    # SRAI: -32 >> 3 = -4
    addi x25, x0, -32
    srai x26, x25, 3
    sw   x26, 0(x5)
    addi x5, x5, 4

###########################################################
# 6. Loads/Stores: LB, LH, LW, LBU, LHU, SB, SH, SW
#    (usando TEST_DATA_BASE e TEMP_SLOT_BASE)
###########################################################

    # LW de word em TEST_DATA_BASE+8 → 0x12345678
    lw   x10, 8(x8)
    sw   x10, 0(x5)
    addi x5, x5, 4

    # LH signed de half em TEST_DATA_BASE+4 → 0x00001234
    lh   x11, 4(x8)
    sw   x11, 0(x5)
    addi x5, x5, 4

    # LHU de half → 0x00001234
    lhu  x12, 4(x8)
    sw   x12, 0(x5)
    addi x5, x5, 4

    # LB signed de 0xFF → -1
    lb   x13, 2(x8)
    sw   x13, 0(x5)
    addi x5, x5, 4

    # LBU de 0xFF → 0x000000FF
    lbu  x14, 2(x8)
    sw   x14, 0(x5)
    addi x5, x5, 4

    # Teste de SB/LB em TEMP_SLOT_BASE
    addi x15, x0, 0x55
    sb   x15, 0(x9)
    lb   x16, 0(x9)
    sw   x16, 0(x5)
    addi x5, x5, 4

    # SH/LH em TEMP_SLOT_BASE+2
    addi x17, x0, 0x7F
    slli x17, x17, 1          # 0xFE
    sh   x17, 2(x9)
    lh   x18, 2(x9)
    sw   x18, 0(x5)
    addi x5, x5, 4

    # SW/LW em TEMP_SLOT_BASE+4
    lui  x19, 0x7F000         # 0x7F000000
    sw   x19, 4(x9)
    lw   x20, 4(x9)
    sw   x20, 0(x5)
    addi x5, x5, 4

###########################################################
# 7. Branches: BEQ, BNE, BLT, BGE, BLTU, BGEU
#   gravamos 1 se branch foi tomado, 0 se não
###########################################################

    # BEQ: 5 == 5 → 1
    addi x10, x0, 5
    addi x11, x0, 5
    beq  x10, x11, beq_taken
    addi x12, x0, 0
    sw   x12, 0(x5)
    addi x5, x5, 4
    jal  x0, beq_done
beq_taken:
    addi x12, x0, 1
    sw   x12, 0(x5)
    addi x5, x5, 4
beq_done:

    # BNE: 5 != 6 → 1
    addi x10, x0, 5
    addi x11, x0, 6
    bne  x10, x11, bne_taken
    addi x12, x0, 0
    sw   x12, 0(x5)
    addi x5, x5, 4
    jal  x0, bne_done
bne_taken:
    addi x12, x0, 1
    sw   x12, 0(x5)
    addi x5, x5, 4
bne_done:

    # BLT signed: -1 < 1 → 1
    addi x10, x0, -1
    addi x11, x0, 1
    blt  x10, x11, blt_taken
    addi x12, x0, 0
    sw   x12, 0(x5)
    addi x5, x5, 4
    jal  x0, blt_done
blt_taken:
    addi x12, x0, 1
    sw   x12, 0(x5)
    addi x5, x5, 4
blt_done:

    # BGE signed: 3 >= -2 → 1
    addi x10, x0, 3
    addi x11, x0, -2
    bge  x10, x11, bge_taken
    addi x12, x0, 0
    sw   x12, 0(x5)
    addi x5, x5, 4
    jal  x0, bge_done
bge_taken:
    addi x12, x0, 1
    sw   x12, 0(x5)
    addi x5, x5, 4
bge_done:

    # BLTU unsigned: 1 < 0xFFFFFFFF → 1
    addi x10, x0, 1
    addi x11, x0, -1         # 0xFFFFFFFF
    bltu x10, x11, bltu_taken
    addi x12, x0, 0
    sw   x12, 0(x5)
    addi x5, x5, 4
    jal  x0, bltu_done
bltu_taken:
    addi x12, x0, 1
    sw   x12, 0(x5)
    addi x5, x5, 4
bltu_done:

    # BGEU unsigned: 0xFFFFFFFF >= 1 → 1
    addi x10, x0, -1
    addi x11, x0, 1
    bgeu x10, x11, bgeu_taken
    addi x12, x0, 0
    sw   x12, 0(x5)
    addi x5, x5, 4
    jal  x0, bgeu_done
bgeu_taken:
    addi x12, x0, 1
    sw   x12, 0(x5)
    addi x5, x5, 4
bgeu_done:

###########################################################
# 8. Jumps: JAL e JALR (sem usar endereço de label)
###########################################################

    # --- JAL: testa salto + fluxo de controle ---
    # x13 vai acumular um padrão conhecido se passar
    addi x13, x0, 0

    jal  x1, jal_helper          # salta para jal_helper
after_jal:
    addi x13, x13, 1             # +1 se voltou do helper
    sw   x13, 0(x5)              # valor esperado = 3 (2 no helper + 1 aqui)
    addi x5, x5, 4

    jal  x0, jal_done            # segue para teste de JALR

jal_helper:
    addi x13, x13, 2             # +2 ao entrar
    jal  x0, after_jal

jal_done:

    # --- JALR: usa ra de um JAL como retorno ---
    # x14 conta quantas vezes passou pelos pontos certos
    addi x14, x0, 0

    # Faz um JAL para obter ra em x1
    jal  x1, jalr_helper_entry
after_jal_for_jalr:
    addi x14, x14, 2             # +2 se voltou corretamente via JALR
    sw   x14, 0(x5)              # valor esperado = 3 (1 no helper + 2 aqui)
    addi x5, x5, 4

    jal  x0, jalr_done

jalr_helper_entry:
    addi x14, x14, 1             # +1 ao entrar
    # usa JALR com x1 (ra) como destino pra voltar pra after_jal_for_jalr
    jalr x0, x1, 0

jalr_done:

###########################################################
# 9. Teste de x0 (não pode ser modificado)
###########################################################

    addi x0, x0, 5               # deve ser ignorado
    sw   x0, 0(x5)               # grava 0
    addi x5, x5, 4

###########################################################
# Fim: loop infinito
###########################################################

end:
    jal x0, end
