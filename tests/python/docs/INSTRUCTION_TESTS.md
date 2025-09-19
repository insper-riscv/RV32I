# Documentação dos Testes da CPU RV32I (Single-Cycle)

Este documento descreve os testes implementados para validar a CPU **RISC-V RV32I single-cycle**.  
Cada instrução do conjunto base foi testada em **simulação (cocotb + GHDL)** e em **FPGA**, garantindo cobertura modular e integrada.

---

## Sumário

1. [U-Type (LUI, AUIPC)](#u-type-lui-auipc)
2. [I-Type (ADDI, XORI, ORI, ANDI, SLLI, SRLI, SRAI)](#i-type-addi-xori-ori-andi-slli-srli-srai)
3. [R-Type (ADD, SUB, XOR, OR, AND, SLL, SRL, SRA, SLT, SLTU)](#r-type-add-sub-xor-or-and-sll-srl-sra-slt-sltu)
4. [Jumps (JAL, JALR)](#jumps-jal-jalr)
5. [Branches (BEQ, BNE, BLT, BGE, BLTU, BGEU)](#branches-beq-bne-blt-bge-bltu-bgeu)
6. [Loads e Stores (LW, LH, LHU, LB, LBU, SW, SH, SB)](#loads-e-stores-lw-lh-lhu-lb-lbu-sw-sh-sb)

---

## Como funciona cada teste

### U-Type (LUI, AUIPC)

#### Assembly
- Executa instruções `AUIPC` e `LUI` com diferentes imediatos (normais, limites positivos, negativos e `-1`).
- Cada resultado é exposto em `t3` para leitura via saída da ALU.

#### Python (cocotb)
- Calcula os valores esperados:
    - `AUIPC`: soma do PC com o imediato deslocado.
    - `LUI`: imediato deslocado 12 bits à esquerda.
- A cada ciclo de clock, o teste compara a saída da ULA com o valor esperado.

#### Garante que o cálculo de imediatos de 20 bits (positivos e negativos) está correto.

---

### I-Type (ADDI, XORI, ORI, ANDI, SLLI, SRLI, SRAI)

#### Assembly
- Inicializa `x1` com o valor base `0x0000F0F0`.
- Executa as instruções aritméticas e lógicas com imediatos de 12 bits.
- Cada resultado é exposto em `t3` para leitura via saída da ALU.

#### Python (cocotb)
- Calcula os valores esperados com extensão de sinal de 12 bits:
    - `ADDI`: soma.
    - `XORI`, `ORI`, `ANDI`: operações lógicas.
    - `SLLI`, `SRLI`, `SRAI`: shifts lógicos e aritméticos.
- A cada ciclo de clock, o teste compara a saída da ULA com o valor esperado.

#### Confirma que a CPU trata corretamente imediatos de 12 bits e executa operações lógicas/aritméticas básicas.

---

### R-Type (ADD, SUB, XOR, OR, AND, SLL, SRL, SRA, SLT, SLTU)

#### Assembly
- Inicializa registradores:
    - `x1 = 1` (mínimo positivo).
    - `x2 = 0x7FFFFFFF` (máximo positivo signed).
- Executa todas as instruções R-type
- Cada resultado é exposto em `t3` para leitura via saída da ALU.

#### Python (cocotb)
- Calcula resultados esperados considerando:
    - Operações aritméticas e lógicas.
    - Shifts (com máscara `rs2 & 0x1F`).
    - Comparações signed (`SLT`) e unsigned (`SLTU`).
- A cada ciclo de clock, o teste compara a saída da ULA com o valor esperado.

#### Assegura que a ULA implementa corretamente todas as operações binárias.

---

### Jumps (JAL, JALR)

#### Assembly
- `JAL`: salva o PC+4 em `x5` e pula para o destino (offset 8).
- `JALR`: usa `x5` como endereço de retorno, alinhado.
- Cada resultado é exposto em `x6`.

#### Python (cocotb)
- Calcula os valores esperados:
    - PC após `JAL`: `(PC_before + offset)`.
    - Link register (`x5`): `(PC+4)`.
    - `JALR`: retorna para endereço salvo em `x5`.
- Compara `PC_out` e `ALU_out` com os valores calculados.

#### Confirma funcionamento do salto incondicional (`JAL`) e do salto indireto (`JALR`).

---

### Branches (BEQ, BNE, BLT, BGE, BLTU, BGEU)

#### Assembly
- Inicializa registradores:
    - `x1 = 5`.
    - `x2 = 10`.
- Testa cada branch nos dois cenários:
    - Condição verdadeira (salta).
    - Condição falsa (segue para próxima instrução).

#### Python (cocotb)
- Monitora `PC_out` a cada instrução.
- Verifica se o PC avança corretamente:
    - Salto → `PC + offset`.
    - Não salto → `PC + 4`.

#### Valida instruções condicionais signed e unsigned, cobrindo os dois cenários (salta / não salta).

---

### Loads e Stores (LW, LH, LHU, LB, LBU, SW, SH, SB)

#### Assembly
- Monta o valor `0xAABBCCDD` em `x2`:
- Executa:
    - Stores: `SW` (palavra inteira), `SH` (halfword), `SB` (byte).
    - Loads: `LW` (palavra completa), `LH` (halfword com extensão de sinal), `LHU` (halfword com extensão de zero), `LB` (byte com extensão de sinal), `LBU` (byte com extensão de zero).

#### Python (cocotb)
- Compara duas saídas:
    - `RAM_out`: valor de saída da memória.
    - `extenderRAM_out`: valor já estendido (sign/zero).
- Valida se cada load corresponde ao comportamento esperado do store.

#### Garante funcionamento da memória com alinhamento e extensões corretas.

---
