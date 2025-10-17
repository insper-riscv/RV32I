# tests/python/utils/runner.py
import os
import sys
import json
import argparse
from pathlib import Path
from cocotb.runner import get_runner, VHDL


# === Caminhos base (robusto p/ esta árvore) ==================================
FILE = Path(__file__).resolve()          # .../tests/python/utils/runner.py
REPO_ROOT = FILE.parents[3]              # .../RV32I
TESTS_ROOT = REPO_ROOT / "tests"         # .../RV32I/tests
JSON_PATH = TESTS_ROOT / "python/tests.json"    # .../RV32I/tests/tests.json


def _abs_params(parameters):
    """Converte valores de parâmetros que são paths para absolutos (se existirem)."""
    if not parameters:
        return {}
    out = {}
    for k, v in parameters.items():
        p = Path(v)
        out[k] = str(p.resolve()) if p.exists() else v
    return out


def _apply_env_overrides(parameters):
    """
    Permite sobrescrever generics do VHDL via ambiente.
      - ROM_FILE: usa variável ROM_FILE se existir
      - PARAM_<NOME>=valor -> sobrescreve parameters["<NOME>"] = valor
    """
    params = dict(parameters or {})

    env_rom = os.getenv("ROM_FILE")
    if env_rom:
        params["ROM_FILE"] = env_rom

    for k, v in os.environ.items():
        if k.startswith("PARAM_"):
            name = k[len("PARAM_"):]
            if name and name != "ROM_FILE":
                params[name] = v
    return params


def run_cocotb_test(toplevel, sources, test_module, parameters=None):
    """
    Compila e executa um teste cocotb.
      - toplevel: entidade VHDL topo (string)
      - sources: lista de caminhos VHDL RELATIVOS à raiz do repo
      - test_module: módulo Python do teste cocotb (ex.: tests.python.cocotb.instructions.foo)
      - parameters: dict de generics (ex.: {"ROM_FILE": ".../prog.hex"})
    """
    # Para imports dentro dos testes
    sys.path.append(str(REPO_ROOT))

    # Resolução dos caminhos de fontes VHDL
    vhdl_sources = [REPO_ROOT / src for src in sources]

    # Descobre "grupo" p/ organizar diretórios de build
    if ".entities." in test_module:
        group = "entities"
    elif ".instructions." in test_module:
        group = "instructions"
    else:
        group = "misc"

    # Nome do diretório de build
    if group == "instructions":
        test_name = test_module.split(".")[-2]
        build_dir = TESTS_ROOT / "python" / "sim_build" / group / test_name
    else:
        build_dir = TESTS_ROOT / "python" / "sim_build" / group / toplevel
    build_dir.mkdir(parents=True, exist_ok=True)

    # Parâmetros (com paths absolutos) + overrides via ambiente
    params = _abs_params(parameters)
    params = _apply_env_overrides(params)

    # DEBUG rápido
    print(f"ENV ROM_FILE: {os.getenv('ROM_FILE')}")
    print(f"params antes do fail-fast: {params}")

    # Fail-fast se o placeholder não foi substituído
    if params.get("ROM_FILE") == "__SET_AT_RUNTIME__":
        raise RuntimeError("ROM_FILE não definido. Rode via run_compliance.py ou exporte ROM_FILE=<hex>.")


    # Runner
    sim = os.getenv("SIM", "ghdl")
    runner = get_runner(sim)

    print(f"==> toplevel: {toplevel}")
    print(f"==> fontes  :")
    for s in vhdl_sources:
        print(f"    - {s}")
    if params:
        print(f"==> generics: {params}")

    # Build
    runner.build(
        vhdl_sources=vhdl_sources,
        hdl_toplevel=toplevel,
        build_dir=build_dir,
        always=True,
        build_args=[VHDL("--std=08")],
        parameters=params,
    )

    # Execução
    wave_file = build_dir / "waves.ghw"
    plusargs = [f"--wave={wave_file}"]

    runner.test(
        hdl_toplevel=toplevel,
        hdl_toplevel_lang="vhdl",
        test_module=test_module,
        build_dir=build_dir,
        plusargs=plusargs,
        test_args=["--std=08"],
    )

    print(f"Waves: {wave_file} (gerado)")


def main():
    # Carrega tests.json (no lugar certo)
    try:
        with open(JSON_PATH, "r") as f:
            TEST_CONFIGS = json.load(f)
    except FileNotFoundError:
        print(f"Erro: Arquivo '{JSON_PATH}' não encontrado.")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Erro: O arquivo JSON '{JSON_PATH}' está mal formatado.")
        sys.exit(1)

    parser = argparse.ArgumentParser("Runner de Testes Cocotb (RV32I)")
    parser.add_argument(
        "test_name",
        nargs="?",
        default="all",
        help=f"Nome do teste. Opções: {list(TEST_CONFIGS.keys()) + ['all']}",
    )
    args = parser.parse_args()

    if args.test_name == "all":
        print("Executando TODOS os testes definidos em tests.json...")
        for name, cfg in TEST_CONFIGS.items():
            print(f"\n{'='*20} INICIANDO TESTE: {name.upper()} {'='*20}")
            try:
                run_cocotb_test(**cfg)
                print(f"{'-'*20} TESTE {name.upper()} FINALIZADO {'-'*20}")
            except Exception as e:
                print(f"[ERRO] O teste '{name}' falhou: {e}")
        print("\nTodos os testes foram executados.")
    elif args.test_name in TEST_CONFIGS:
        print(f"Executando teste específico: {args.test_name}")
        run_cocotb_test(**TEST_CONFIGS[args.test_name])
        print(f"\nTeste {args.test_name} finalizado.")
    else:
        print(f"Erro: Teste '{args.test_name}' não encontrado em tests.json.")
        print(f"Opções disponíveis: {list(TEST_CONFIGS.keys()) + ['all']}")
        sys.exit(1)


if __name__ == "__main__":
    main()