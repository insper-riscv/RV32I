# `tests/python` — Guia de testes (Cocotb + GHDL)

Aqui ficam os **testes de simulação** escritos em **Python** usando **Cocotb** e o **runner** que compila/roda tudo com o **GHDL**. Também aqui que fica as **ondas** no **GTKWave**.

## O que tem aqui

```
tests/python/
├── cocotb/           # testes em Python (um arquivo por módulo VHDL)
│   └── ...           # ex.: bancoRegistradores.py, examples/and_gate.py, etc.
├── utils/
│   └── runner.py     # script que compila VHDL + executa testes
├── tests.json        # catálogo: registro dos testes que podem ser executados
└── sim_build/
    └── <toplevel>/   # outputs da simulação (results.xml, waves.ghw, etc.)
```

* **`cocotb/`**: cada `.py` contém um ou mais `@cocotb.test()`.
* **`tests.json`**: registra *nome do teste* → (*toplevel VHDL*, *arquivos VHDL*, *módulo Python*).
* **`sim_build/<toplevel>/`**: saída da simulação; aqui nasce o `waves.ghw`.


## Criando um novo teste

### 1) Escreva o testbench em `cocotb/`

Crie `tests/python/cocotb/meu_modulo.py`:

```python
# tests/python/cocotb/meu_modulo.py
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def basico(dut):
    ...
```


### 2) Registre no `tests.json`

Abra `tests/python/tests.json` e adicione um bloco:

```json
{
  "meu_modulo": {
    "toplevel": "minhaentidade",                 // entity VHDL (nome exato em minusculo!)
    "sources": [
      "src/DependenciaA.vhd",
      "src/DependenciaB.vhd",
      "src/MinhaEntidade.vhd"
    ],
    "test_module": "tests.python.cocotb.meu_modulo"          
  }
}
```

**Campos:**

* `toplevel`: o nome da **entity** VHDL que você quer simular.
* `sources`: **todos** os `.vhd` necessários (a entity + dependências).

  > Use caminhos **relativos à raiz do repositório** (ex.: `src/...`).
* `test_module`: caminho Python do arquivo realtivo a raiz do projeto separado por pontos (ex.: `tests.python.cocotb.meu_modulo`).


## Executando

Rode com o venv ativo, a partir da **raiz do repo**:

* **Todos os testes** do catálogo:

  ```bash
  python3 tests/python/utils/runner.py
  # ou
  python3 tests/python/utils/runner.py all
  ```

* **Um teste específico**:

  ```bash
  python3 tests/python/utils/runner.py meu_modulo
  ```

Saída (por teste):
`tests/python/sim_build/<toplevel>/results.xml` + `waves.ghw` (ondas).

Exemplo de log de um teste (bancoRegistradores):
![Exemplo log teste](docs/exemplo_log_teste.png)


## Visualizando ondas (GTKWave)

Cada execução gera `waves.ghw` em `sim_build/<toplevel>/`:

```bash
gtkwave tests/python/sim_build/<entidade>/waves.ghw
```

Dicas:

* Adicione sinais do DUT (ex.: `clk`, `escreveC`, endereços, dados e saídas).
* Salve um layout `.sav` no mesmo diretório para reutilizar a seleção de sinais.

Exemplo das Waves de um teste (bancoRegistradores):
![Exemplo log teste](docs/todos_testes.png)
