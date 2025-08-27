# utils/runner.py

import os
import sys
import json  
import argparse
from pathlib import Path
from cocotb.runner import get_runner

def run_cocotb_test(toplevel: str, sources: list, test_module: str):
    """
    Função genérica para compilar e executar um teste cocotb.
    """

    sim = os.getenv("SIM", "ghdl")
    proj_root = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_root))
    
    vhdl_sources = [proj_root / src for src in sources]

    runner = get_runner(sim)

    runner.build(
        vhdl_sources=vhdl_sources,
        hdl_toplevel=toplevel,
        always=True
    )

    runner.test(
        hdl_toplevel=toplevel,
        test_module=test_module
    )

# ====================================================================================
# LÓGICA PRINCIPAL
# ====================================================================================

if __name__ == "__main__":
    
    # 2. Carregue as configurações do arquivo JSON
    proj_root = Path(__file__).resolve().parent.parent
    json_path = proj_root / "tests.json"
    
    try:
        with open(json_path, 'r') as f:
            TEST_CONFIGS = json.load(f)
    except FileNotFoundError:
        print(f"Erro: Arquivo de configuração '{json_path}' não encontrado.")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Erro: O arquivo JSON '{json_path}' está mal formatado.")
        sys.exit(1)

    parser = argparse.ArgumentParser(description="Runner de Testes Cocotb para o projeto RV32I")
    parser.add_argument(
        "test_name",
        nargs='?',
        default="all",
        help=f"Nome do teste a ser executado. Opções: {list(TEST_CONFIGS.keys()) + ['all']}"
    )
    args = parser.parse_args()

    if args.test_name == "all":
        print("🚀 Executando TODOS os testes definidos em tests.json...")
        for name, config in TEST_CONFIGS.items():
            print(f"\n{'='*20} INICIANDO TESTE: {name.upper()} {'='*20}")
            try:
                run_cocotb_test(**config)
                print(f"{'-'*20} TESTE {name.upper()} FINALIZADO COM SUCESSO {'-'*20}")
            except Exception as e:
                print(f"[ERRO] O teste '{name}' falhou: {e}")
        print("\nTodos os testes foram executados.")

    elif args.test_name in TEST_CONFIGS:
        print(f"🚀 Executando teste específico: {args.test_name}")
        config = TEST_CONFIGS[args.test_name]
        run_cocotb_test(**config)
        print(f"\nTeste {args.test_name} finalizado.")
    else:
        print(f"Erro: Teste '{args.test_name}' não encontrado em tests.json.")
        print(f"Opções disponíveis: {list(TEST_CONFIGS.keys()) + ['all']}")
        sys.exit(1)