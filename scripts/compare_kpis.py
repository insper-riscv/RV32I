#!/usr/bin/env python3
"""
compare_kpis.py — Comparação de KPIs entre versão base (2025.2) e atual (2026.1)
Insper / CTI Renato Archer

Uso:
  # 1. Gerar o JSON da versão base (fazer UMA vez e commitar):
  python3 scripts/kpi_report.py \\
    --quartus-dir  <repo_base>/tests/FPGA/core/quartus \\
    --cocotb-log   /dev/null \\
    --testbench-dirs <repo_base>/tests \\
    --asm          <repo_base>/tests/FPGA/core/asm_tests/full.S \\
    --freq-base    1.0 \\
    --output       docs/baseline_2025_2.json

  # 2. Gerar o JSON da versão atual:
  python3 scripts/kpi_report.py --output docs/current_2026_1.json

  # 3. Comparar:
  python3 scripts/compare_kpis.py \\
    --baseline docs/baseline_2025_2.json \\
    --current  docs/current_2026_1.json
"""

import argparse, json, sys
from pathlib import Path


def load(path: str) -> dict:
    p = Path(path)
    if not p.exists():
        print(f"ERRO: arquivo não encontrado: {p}", file=sys.stderr)
        sys.exit(1)
    return json.loads(p.read_text())


def fmt(val, fmt_str="{}", na="N/A"):
    return fmt_str.format(val) if val is not None else na


def delta_str(old, new, unit="", higher_is_better=True):
    """Retorna string com variação e seta."""
    if old is None or new is None:
        return ""
    diff = new - old
    if diff == 0:
        return "  (=)"
    arrow = "↑" if diff > 0 else "↓"
    good  = (diff > 0) == higher_is_better
    sign  = "+" if diff > 0 else ""
    mark  = "✓" if good else "✗"
    return f"  {arrow} {sign}{diff:.2f}{unit} {mark}"


def main():
    p = argparse.ArgumentParser(description="Compara KPIs entre duas versões do processador")
    p.add_argument("--baseline", required=True, help="JSON da versão base (2025.2)")
    p.add_argument("--current",  required=True, help="JSON da versão atual (2026.1)")
    args = p.parse_args()

    base = load(args.baseline)
    curr = load(args.current)

    bk = base["kpis"]
    ck = curr["kpis"]

    sep = "=" * 70
    div = "─" * 70
    col_w = 22  # largura de cada coluna de valor

    def row(label, bval, cval, change=""):
        print(f"  {label:<28} {str(bval):<{col_w}} {str(cval):<{col_w}} {change}")

    print(f"\n{sep}")
    print(f"  COMPARAÇÃO DE KPIs — {base['project']}")
    print(f"  Baseline : {base['generated_at']}  →  {args.baseline}")
    print(f"  Atual    : {curr['generated_at']}  →  {args.current}")
    print(sep)
    print(f"  {'Métrica':<28} {'2025.2 (base)':<{col_w}} {'2026.1 (atual)':<{col_w}} Variação")
    print(div)

    # ── KPI 1 ──────────────────────────────────────────────────────────────
    print("\n  [KPI 1] Clock do Sistema")
    b1 = bk.get("kpi1_clock_mhz", {})
    c1 = ck.get("kpi1_clock_mhz", {})
    bf = b1.get("fmax_mhz")
    cf = c1.get("fmax_mhz")
    row("Fmax (MHz)",
        fmt(bf, "{:.2f} MHz"),
        fmt(cf, "{:.2f} MHz"),
        delta_str(bf, cf, " MHz", higher_is_better=True))


    # ── KPI 2 ──────────────────────────────────────────────────────────────
    print(f"\n  [KPI 2] Cobertura de Testes (cocotb)")
    b2 = bk.get("kpi2_test_coverage", {})
    c2 = ck.get("kpi2_test_coverage", {})
    bp2 = b2.get("coverage_pct")
    cp2 = c2.get("coverage_pct")
    bt2 = b2.get("total", 0)
    ct2 = c2.get("total", 0)
    row("Testes passaram (%)",
        f"{b2.get('passed','?')}/{bt2} ({fmt(bp2,'{:.1f}%')})" if bt2 else "N/A",
        f"{c2.get('passed','?')}/{ct2} ({fmt(cp2,'{:.1f}%')})" if ct2 else "N/A",
        delta_str(bp2, cp2, "%", higher_is_better=True) if bp2 and cp2 else "")

    # ── KPI 3 ──────────────────────────────────────────────────────────────
    print(f"\n  [KPI 3] Instruções Suportadas")
    b3 = bk.get("kpi3_instructions", {})
    c3 = ck.get("kpi3_instructions", {})
    row("Total (instrução/suportadas)",
        b3.get("ratio", "N/A"),
        c3.get("ratio", "N/A"),
        delta_str(b3.get("total_covered"), c3.get("total_covered"),
                  " instr", higher_is_better=True))
    row("RV32I (%)",
        f"{len(b3.get('rv32i_covered',[]))}/{b3.get('rv32i_total','?')} ({b3.get('rv32i_pct','?')}%)",
        f"{len(c3.get('rv32i_covered',[]))}/{c3.get('rv32i_total','?')} ({c3.get('rv32i_pct','?')}%)",
        "")
    row("RV32M (%)",
        f"{len(b3.get('rv32m_covered',[]))}/{b3.get('rv32m_total','?')} ({b3.get('rv32m_pct','?')}%)",
        f"{len(c3.get('rv32m_covered',[]))}/{c3.get('rv32m_total','?')} ({c3.get('rv32m_pct','?')}%)",
        delta_str(b3.get("rv32m_pct"), c3.get("rv32m_pct"), "%", higher_is_better=True))

    # ── KPI 4 ──────────────────────────────────────────────────────────────
    print(f"\n  [KPI 4] Speedup / Desempenho")
    b4 = bk.get("kpi4_speedup", {})
    c4 = ck.get("kpi4_speedup", {})
    bb = b4.get("baseline", {})
    cb = c4.get("baseline", {})
    row("Instruções no benchmark",
        fmt(b4.get("instr_total"), "{} instr"),
        fmt(c4.get("instr_total"), "{} instr"),
        delta_str(b4.get("instr_total"), c4.get("instr_total"),
                  " instr", higher_is_better=True))
    row("CPI (baseline multi-cycle)",
        fmt(bb.get("cpi"), "{:.1f}"),
        fmt(cb.get("cpi"), "{:.1f}"),
        "")
    row("Ciclos totais (baseline)",
        fmt(bb.get("cycles"), "{} ciclos"),
        fmt(cb.get("cycles"), "{} ciclos"),
        delta_str(bb.get("cycles"), cb.get("cycles"), "", higher_is_better=False))
    row("Tempo baseline @ freq",
        f"{fmt(bb.get('time_us'), '{:.1f} µs')} @ {bb.get('freq_mhz','?')} MHz",
        f"{fmt(cb.get('time_us'), '{:.1f} µs')} @ {cb.get('freq_mhz','?')} MHz",
        "")

    # Speedup do pipeline, se disponível
    cs = c4.get("speedup", {})
    cp = c4.get("pipeline", {})
    if "S" in cs:
        print(f"\n  [KPI 4 — Pipeline]")
        row("CPI efetivo (pipeline)",
            "N/A",
            fmt(cp.get("cpi_efetivo"), "{:.3f}"),
            "")
        row("Ciclos totais (pipeline)",
            "N/A",
            fmt(cp.get("cycles"), "{} ciclos"),
            "")
        row("Tempo pipeline @ freq",
            "N/A",
            f"{fmt(cp.get('time_us'), '{:.1f} µs')} @ {cp.get('freq_mhz','?')} MHz",
            "")
        flag = "✓ MELHORA" if cs.get("improved") else "✗ REGRESSÃO"
        print(f"\n  {'SPEEDUP S':<28} {'—':<{col_w}} {cs.get('S','?'):<{col_w}} {flag}")
        if cp.get("hazards_estimated"):
            print(f"\n  ⚠ Hazards estimados — use --load-use-hazards e --branch-taken para valor real")
    else:
        note = cs.get("note", "pipeline não implementado ainda")
        print(f"\n  Speedup: {note}")

    print(f"\n{sep}\n")


if __name__ == "__main__":
    main()
