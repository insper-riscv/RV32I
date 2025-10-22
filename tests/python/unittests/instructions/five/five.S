    .section .text
    .globl _start

_start:
    addi x1, x0, 5
    addi x2, x0, 10
    # ==== BEQ ====
    beq  x1, x2, Lbeq1       # não salta (x1 != x2)
    addi x3, x0, 1           # cai aqui
Lbeq1:
    beq  x1, x1, Lbeq2       # salta (x1 == x1)
    addi x3, x0, 2           # pulado
Lbeq2:
    addi x3, x0, 3           # destino

    # ==== BNE ====
    bne  x1, x2, Lbne1       # salta (x1 != x2)
    addi x4, x0, 1           # pulado
Lbne1:
    addi x4, x0, 2           # destino
    bne  x1, x1, Lbne2       # não salta (x1 == x1)
    addi x4, x0, 3           # cai aqui
Lbne2:

    # ==== BLT ====
    blt  x1, x2, Lblt1       # salta (5 < 10 signed)
    addi x5, x0, 1           # pulado
Lblt1:
    addi x5, x0, 2           # destino
    blt  x2, x1, Lblt2       # não salta (10 !< 5 signed)
    addi x5, x0, 3           # cai aqui
Lblt2:

    # ==== BGE ====
    bge  x2, x1, Lbge1       # salta (10 >= 5 signed)
    addi x6, x0, 1           # pulado
Lbge1:
    addi x6, x0, 2           # destino
    bge  x1, x2, Lbge2       # não salta (5 !>= 10 signed)
    addi x6, x0, 3           # cai aqui
Lbge2:

    # ==== BLTU ====
    bltu x1, x2, Lbltu1      # salta (5 < 10 unsigned)
    addi x7, x0, 1           # pulado
Lbltu1:
    addi x7, x0, 2           # destino
    bltu x2, x1, Lbltu2      # não salta
    addi x7, x0, 3           # cai aqui
Lbltu2:

    # ==== BGEU ====
    bgeu x2, x1, Lbgeu1      # salta (10 >= 5 unsigned)
    addi x8, x0, 1           # pulado
Lbgeu1:
    addi x8, x0, 2           # destino
    bgeu x1, x2, Lbgeu2      # não salta
    addi x8, x0, 3           # cai aqui
Lbgeu2:

1:  j 1b