# Processador RISC-V (RV32I) — VHDL + Testes Automatizados

**Autores:** [Ilana Finger](https://github.com/ilacftemp), [Leonardo Paloschi](), [Lucas Lima](https://github.com/lucasouzamil) e [Pedro Ventura](https://github.com/pedropcventura).
**Orientador:** [Rafael Corsi](https://github.com/rafaelcorsi).

Este repositório implementa, em **VHDL**, um processador baseado no **conjunto de instruções RV32I** (RISC-V de 32 bits).
O foco é **implementação da arquitetura e verificação**: além do hardware em si, o projeto traz uma infraestrutura de **simulação com Cocotb** (Python) e **projetos Quartus** para testes em FPGA.

## Visão geral do projeto

* **Arquitetura**: RV32I (inteiros 32-bit).
* **Blocos típicos**: banco de registradores, ULA, gerador de imediato, ROM/RAM simples, unidade de controle, e o *top* `riscv.vhd`.
* **Verificação**: testes automatizados em **Cocotb** (lib pyhton para testes) com **GHDL** (simulador VHDL). As ondas de simulação podem ser abertas no **GTKWave**.
* **FPGA**: projetos **Quartus** para síntese e experimentos práticos (placa alvo utilizada: *Cyclone V: 5CEBA4F23C7 (a FPGA da placa DE0-CV)*).


## Estrutura do repositório (função de cada pasta)

```
.
├── quartus/        # Projeto Quartus "principal" do processador (FPGA)
├── src/            # Módulos VHDL usados pelo projeto Quartus e nos testes
└── tests/          # Testes de verificação (simulação + projetos FPGA de módulos)
    ├── FPGA/       # Projetos Quartus pequenos para testar módulos separadamente
    └── python/     # Testes Cocotb (simulados), runner e artefatos de simulação
```

### `quartus/`

Onde fica o **projeto principal de FPGA**. É aqui que você abre no Quartus, configura pinos, compila e gera o bitstream. Usa os módulos de `src/`.

### `src/`

Todos os **módulos VHDL** do processador (banco de registradores, ULA, unidade de controle, etc.).
Esses arquivos são incluídos no **projeto do Quartus** e também são **alvo dos testes de simulação**.

### `tests/`

Reúne duas frentes de verificação:

* `tests/FPGA/`: **projetos Quartus de apoio** para testar **módulos isolados** diretamente na FPGA (útil para depurar blocos fora do processador completo).
* `tests/python/`: onde ficam os **testbenches Cocotb** (Python), o **runner** e os **artefatos de simulação**.

  * `cocotb/`: **testes em Python** (cada arquivo testa um módulo/entidade VHDL).
  * `utils/runner.py`: **orquestra** a compilação e simulação (lê o catálogo `tests.json`).
  * `tests.json`: **catálogo de testes**, mapeando cada teste para o *toplevel* VHDL e módulos/entidades necessários.
  * `sim_build/<toplevel>/`: **saída da simulação** do respectivo teste *toplevel* (ex.: `results.xml`, `waves.ghw` para abrir no GTKWave).

  > Para entender mais sobre os testes simulados, verificar o [README em `tests/python/`](tests/README.md)


## Dependências

### Sistema (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install ghdl gtkwave
```

* **GHDL**: simulador VHDL — compila e executa os `.vhd` para os testes Cocotb.
* **GTKWave**: visualizador de formas de onda — abre os `.ghw` gerados na simulação (útil para depurar sinais).

### Python

Use ambiente virtual para isolar dependências:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

O `requirements.txt` inclui **Cocotb** (framework de testes em Python para projetos HDL).

> Resumo: **GHDL** executa a simulação, **Cocotb** escreve/verifica testes, **GTKWave** mostra as ondas.


## Rodando um teste simulado

Os testes são lançados pelo runner:

```bash
# da raiz do repositório (com o venv ativo)
python3 tests/python/utils/runner.py           # roda todos os testes do catálogo
python3 tests/python/utils/runner.py bancoRegistradores   # roda um teste específico
```

* O runner lê `tests/python/tests.json`, compila os **sources** indicados e roda os **testes Cocotb**.
* A saída de cada *toplevel* vai para `tests/python/sim_build/<toplevel>/`, incluindo:

  * `results.xml`: relatório xUnit
  * `waves.ghw`: **ondas** da simulação (abra com `gtkwave`)

Exemplo de log de um teste (bancoRegistradores):
![Exemplo log teste](docs/exemplo_log_teste.png)

Exemplo para abrir ondas:

```bash
gtkwave tests/python/sim_build/bancoregistradores/waves.ghw
```

Exemplo das Waves de um teste (bancoRegistradores):
![Exemplo log teste](docs/todos_testes.png)

> Para **criar novos testes** (como adicionar entradas no `tests.json`, padrões de pastas), consulte o [**README da pasta `tests/python`**](tests/README.md).
