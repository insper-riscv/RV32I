# Scripts de Medição de KPIs — Capstone RV32IM

Insper / CTI Renato Archer — 2026.1

## Visão Geral

Dois scripts Python medem e comparam os KPIs do projeto automaticamente:

| Script | Função |
|--------|--------|
| `scripts/kpi_report.py` | Coleta os KPIs de uma versão do processador e salva em JSON |
| `scripts/compare_kpis.py` | Compara dois JSONs (baseline vs atual) lado a lado |

O JSON do baseline (`docs/baseline_2025_2.json`) já está commitado no repo e **não deve ser alterado** — ele representa a versão recebida do grupo anterior (2025.2, RV32I puro).

---

## KPIs Medidos

| KPI | O que mede | Fonte |
|-----|-----------|-------|
| **KPI 1** — Clock do Sistema | Frequência real configurada no PLL da CPU | `src/PLL/pll_0002.v` |
| **KPI 2** — Cobertura de Testes | Testes cocotb passando | `results.xml` ou `tests.json` |
| **KPI 3** — Instruções Suportadas | Quantas instruções RV32I e RV32M têm testes | Testbenches `.py` e `.S` |
| **KPI 4** — Speedup | Ciclos e tempo de execução do benchmark | Análise estática de `full.S` |

---

## Uso Rápido

Rodar da raiz do repositório (`~/RV32I`):

```bash
# Gerar KPIs da versão atual
python3 scripts/kpi_report.py --output docs/current_2026_1.json

# Comparar com o baseline
python3 scripts/compare_kpis.py \
  --baseline docs/baseline_2025_2.json \
  --current  docs/current_2026_1.json
```

---

## Após Implementar o Pipeline

Quando o pipeline de 5 estágios estiver implementado, adicionar `--pipeline`:

```bash
python3 scripts/kpi_report.py \
  --pipeline \
  --output docs/current_2026_1.json

python3 scripts/compare_kpis.py \
  --baseline docs/baseline_2025_2.json \
  --current  docs/current_2026_1.json
```

Para refinar o speedup com valores reais de hazards (extraídos do waveform):

```bash
python3 scripts/kpi_report.py \
  --pipeline \
  --load-use-hazards <N> \
  --branch-taken <N> \
  --output docs/current_2026_1.json
```

---

## Referência Completa de Argumentos

### `kpi_report.py`

```
Quartus (KPI 1):
  --quartus-dir   Diretório do projeto Quartus
                  default: tests/FPGA/core/quartus
  --sta-rpt       Relatório do Timing Analyzer (relativo a --quartus-dir)
                  default: output_files/core_fpga_test.sta.rpt
  --fit-rpt       Relatório do Fitter (relativo a --quartus-dir)
                  default: output_files/core_fpga_test.fit.rpt

Cocotb (KPI 2):
  --cocotb-log    results.xml do cocotb, ou /dev/null para usar tests.json
                  default: tests/component/multdiv/results.xml

Instruções (KPI 3):
  --testbench-dirs  Diretórios para buscar testbenches .py e .S
                    default: tests

Speedup (KPI 4):
  --asm             Benchmark assembly
                    default: tests/FPGA/core/asm_tests/full.S
  --freq-base       Clock do baseline em MHz  (default: 1.0)
  --freq-new        Clock da versão nova em MHz  (default: 1.0)
  --pipeline        Ativa modelo pipeline 5 estágios
  --cpi-m           CPI das instruções M no pipeline  (default: 3.0)
  --load-use-hazards  Número real de load-use hazards (estimado se omitido)
  --branch-taken      Número real de branches tomados (estimado se omitido)

Saída:
  --output        Salva JSON neste arquivo
  --json-only     Imprime apenas JSON (sem resumo formatado)
```

### `compare_kpis.py`

```
  --baseline   JSON da versão base (docs/baseline_2025_2.json)
  --current    JSON da versão atual (docs/current_2026_1.json)
```

---

## Estrutura de Arquivos

```
RV32I/
├── scripts/
│   ├── kpi_report.py          # Coleta KPIs de uma versão
│   └── compare_kpis.py        # Compara dois JSONs
└── docs/
    ├── baseline_2025_2.json   # ⚠ NÃO EDITAR — snapshot da versão base
    └── current_2026_1.json    # Gerado a cada execução do kpi_report.py
```

---

## Como o KPI 1 Funciona

O clock real da CPU é lido do arquivo `src/PLL/pll_0002.v`, que é gerado pelo
wizard do Quartus e reflete o que foi sintetizado no PLL:

```verilog
.output_clock_frequency0("1.000000 MHz"),  // clock da CPU
```

O script sobe a árvore de diretórios a partir do `--quartus-dir` até encontrar
`src/PLL/pll_0002.v`, sem depender de caminhos fixos.

**Nota:** A redução de 17 MHz (2025.2) para 1 MHz (2026.1) é intencional —
o `lpm_divide` sem pipeline não fecha timing a frequências maiores. O pipeline
de 5 estágios com stalls resolverá esse problema.

---

## Como o KPI 2 Funciona

O script aceita dois formatos automaticamente:

- **`results.xml`** (xunit gerado pelo cocotb/Questa): conta `<testcase>` diretamente
- **`tests.json`** (formato do runner GHDL do grupo anterior): conta as suites definidas,
  e tenta agregar `results.xml` de `sim_build/` se existirem

Passa `/dev/null` em `--cocotb-log` para forçar a leitura do `tests.json`.

---

## Contexto do Projeto

| Versão | Semestre | Clock | Instruções | Notas |
|--------|----------|-------|------------|-------|
| 2025.2 (base) | 2025.2 | 17 MHz | RV32I (37 instr) | Grupo anterior |
| 2026.1 (atual) | 2026.1 | 1 MHz | RV32IM (45 instr) | Pipeline pendente |
| 2026.1 (pipeline) | 2026.1 | TBD | RV32IM (45 instr) | Meta do semestre |
