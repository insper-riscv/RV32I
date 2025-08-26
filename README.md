# Processador RISC-V (RV32I) em VHDL

**Autores:** [Ilana Finger](https://github.com/ilacftemp), [Leonardo Paloschi](), [Lucas Lima](https://github.com/lucasouzamil) e [Pedro Ventura](https://github.com/pedropcventura).

**Orientador:** [Rafael Corsi](https://github.com/rafaelcorsi).

Este repositório contém o desenvolvimento de um processador [RISC-V](https://riscv.org/) baseado na arquitetura RV32I. O projeto é implementado em VHDL e utiliza uma infraestrutura de testes automatizados.

## Índice

1.  [Estrutura de Pastas](#-estrutura-de-pastas)
2.  [Configuração do Ambiente de Testes](#-configuração-do-ambiente-de-testes)
3.  [Executando os Testes](#-executando-os-testes)
4.  [Como Criar um Novo Teste](#-como-criar-um-novo-teste)

## Estrutura de Pastas

O projeto está organizado nas seguintes pastas, cada uma com um propósito específico:

```bash
.
├── quartus
├── src
├── tests
├── tests.json
└── utils
```

* **/src**: Contém todos os arquivos-fonte `.vhd` do processador. Este é o coração do projeto, onde os componentes como a ULA, banco de registradores e unidade de controle são definidos. Estes também são os arquivos que estão presente no projeto do Quartus.

* **/quartus**: É a pasta do projeto do Quartus, com os arquivos de configurações e setup necessários, como `.qpf` e `.qsf` (no projeto estamos usando a placa **DE0-CV: 5CEBA4F23C7**). Esta pasta é utilizada exclusivamente no Quartus.

* **/tests**: Contém todos os testbenches escritos em Python com o framework Cocotb. Cada arquivo `.py` é responsável por verificar o funcionamento de um componente específico da pasta `/src`.

* **/utils**: Contém scripts de utilidade que auxiliam no desenvolvimento. Atualmente, abriga o `runner.py`, o orquestrador de testes automatizados.

* **tests.json**: Arquivo de configuração, no formato JSON, que descreve todos os testes disponíveis, seus componentes VHDL associados e o módulo de teste correspondente.

## Configuração do Ambiente de Testes

Para executar os testes de verificação, você precisará instalar as dependências e o simulador VHDL.

### 1. Pré-requisitos

Certifique-se de ter os seguintes softwares instalados no seu sistema (projeto baseado em distro Debian Linux):

* **Python** (versão 3.8 ou superior)
* **GHDL**: Um simulador VHDL de código aberto.

    ```bash
    sudo apt-get update
    sudo apt-get install ghdl
    ```

### 2. Instalação das Dependências Python

É uma forte recomendação usar um ambiente virtual (`venv`) para isolar as dependências do projeto.

```bash
# 1. Na raiz do projeto, crie um ambiente virtual na pasta .venv
python3 -m venv .venv

# 2. Ative o ambiente virtual
source .venv/bin/activate

# 3. Instale as dependências
pip install requirements.txt
```

Com o ambiente ativado, você está pronto para rodar os testes.

## Executando os Testes

O script `utils/runner.py` automatiza todo o processo de compilação e simulação. Ele lê o arquivo `tests.json` para saber quais testes estão disponíveis.

**Importante:** Sempre execute os comandos com seu ambiente virtual ativado! (`source .venv/bin/activate`)

### Para executar TODOS os testes disponíveis:

Este comando irá executar, um por um, todos os testes definidos no `tests.json`.

```bash
python3 utils/runner.py all
```
*(Se nenhum argumento for passado, `all` é executado por padrão)*

### Para executar um teste ESPECÍFICO:

Passe o nome do teste (a chave do JSON) como argumento para o runner.

```bash
# Exemplo para rodar apenas os testes da ULA
python3 utils/runner.py ula

# Exemplo para rodar apenas os testes do MUX 2x1
python3 utils/runner.py mux_2x1
```

### Para ver a lista de testes disponíveis:

Use a flag `--help` para ver os nomes dos testes que você pode executar.

```bash
python3 utils/runner.py --help
```

## Como Criar um Novo Teste

Para validar um novo componente VHDL, siga estes três passos:

### Passo 1: Criar o Arquivo de Teste em Python

Crie um novo arquivo `test_meu_componente.py` dentro da pasta `/tests`. Use o template abaixo como ponto de partida e olhe os testes já criados para entender como funcionam os comandos:

```python
# tests/test_meu_componente.py
import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def meu_primeiro_teste(dut):
    """Uma breve descrição do que este teste faz."""
    dut._log.info("Iniciando o teste para MeuComponente.")

    # Coloque aqui a lógica do seu teste
    # Ex: Atribuir valores às portas de entrada do DUT
    # dut.entrada.value = 10

    # Esperar um tempo para a lógica se propagar
    await Timer(1, units="ns")

    # Verificar se a saída está correta com uma asserção
    # assert dut.saida.value == 20, "A saída não é o valor esperado!"

    dut._log.info("Teste finalizado com sucesso.")
```

### Passo 2: Configurar o `tests.json`

Abra o arquivo `tests.json` na raiz do projeto e adicione uma nova entrada (um novo "bloco") para o seu componente. Este passo registra o teste no nosso sistema automatizado.

```json
{
  "ula": { ... },
  "example": { ... },
  "meu_componente": {
    "toplevel": "meucomponente",
    "sources": [
      "src/dependencia1.vhd",
      "src/MeuComponente.vhd"
    ],
    "test_module": "tests.test_meu_componente"
  }
}
```

Cada campo neste bloco de configuração tem um papel fundamental:

  * `"toplevel"`: O nome da entidade VHDL principal que você deseja testar (ex: `entity meucomponente is ...`). **Atenção:** Lembre-se que este nome deve estar em letras minúsculas para garantir a compatibilidade com o simulador GHDL.

  * `"test_module"`: O caminho para o seu arquivo de teste Python, escrito no formato de importação. Por exemplo, o arquivo `tests/test_meu_componente.py` se torna `"tests.test_meu_componente"`.

  * `"sources"`: Uma lista de **TODOS** os arquivos `.vhd` necessários para compilar o seu `toplevel`, inclusive ele. Isso inclui não apenas as dependências diretas, mas também as dependências dos seus submódulos. Se `MeuComponente.vhd` usa `dependencia1.vhd`, e `dependencia1.vhd` por sua vez usa `sub_dependencia.vhd`, então os três arquivos precisam estar na lista.

Embora seja tecnicamente possível listar todos os arquivos da pasta `/src` em todos os testes, essa abordagem tem um custo: aumenta o tempo de compilação a cada execução e pode dificultar a depuração. Manter uma lista explícita, como fazemos aqui, é a melhor prática para manter os testes rápidos e organizados.
### Passo 3: Executar!

Salve os arquivos e execute seu novo teste usando o nome que você definiu no JSON:

```bash
python3 utils/runner.py meu_componente
```