# Banco de Registradores (FPGA)

Este teste coloca o **banco de registradores RV32I (32×32 bits)** na placa (ex.: DE0-CV) para interação direta via **SW**, **KEY**, **LEDs** e **HEX**.
A ideia: escolher endereços A/B/C, escolher um dado de 3 bits, **dar um “passo” de clock** com o botão e ver as leituras nos displays.

#### Vídeo do teste:

[![Demo Banco de Registradores](https://img.youtube.com/vi/6z75OKjMnCE/0.jpg)](https://youtu.be/6z75OKjMnCE?si=i_e1n5RB_PhHB0rD)

## Como funciona (visão rápida)

Top-level: `testeBancoReg`

* O clock do banco (`CLK`) é um **pulso** gerado por `edgeDetector` a partir de `FPGA_RESET_N`. **Cada aperto** do botão de reset (ativo-baixo) gera **1 ciclo** de clock para o banco → gravações são efetivadas na borda.
* **x0 é sempre zero**: ler endereço 0 retorna 0; escrever em 0 é ignorado.
* Os endereços A/B/C são limitados a **0..15** (o MSB é forçado a 0 no toplevel).

## Mapeamento de I/Os

### Entradas

* `SW[9]` → **escreveC** (enable de escrita, 1 = habilita escrita no próximo passo de clock)
* `SW[8:6]` → **dadoEscritaC** (3 bits, zero-extend para 32b)
* `SW[5:4]` → **endC** (2 bits → vira 5 bits como `"0" & "00" & SW[5:4]` → endereços 0..15)
* `SW[3:2]` → **endB**
* `SW[1:0]` → **endA**
* `KEY[0]` (ativo-baixo) → **clear** do banco (ligado em `not(KEY(0))`)
* `FPGA_RESET_N` (ativo-baixo) → **botão de passo** (gera 1 pulso de clock via `edgeDetector`)

### Saídas (displays/LEDs)

* `HEX2` ← **saidaA\[3:0]** (nibble baixo do dado lido em A)
* `HEX3` ← **saidaB\[3:0]** (nibble baixo do dado lido em B)
* `HEX4` ← **{0, dadoEscritaC}** (mostra o nibble escrito: 0 + 3 bits de dado)
* `HEX0` ← **endA** (nibble do endereço A)
* `HEX1` ← **endB**
* `HEX5` ← **endC**
* `LEDR[0]` ← `SW[9]` (escreveC)
* `LEDR[1]` ← `not(KEY[0])` (clear ativo)
* `LEDR[2]` ← `not(FPGA_RESET_N)` (botão de passo pressionado)
* `LEDR[3]` ← `CLOCK_50` (clock da placa — só referência visual)



