# utils/runner.py

import os
import sys
import json  
import argparse
from pathlib import Path
from cocotb.runner import get_runner

import subprocess

# utils/runner.py (trechos relevantes)

# utils/runner.py (trechos relevantes)

def run_cocotb_test(toplevel: str, sources: list, test_module: str, waves: bool=False, open_wave: bool=False):
    sim = os.getenv("SIM", "ghdl")
    proj_root = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_root))
    vhdl_sources = [proj_root / src for src in sources]

    runner = get_runner(sim)
    build_dir = proj_root / "sim_build"

    runner.build(
        vhdl_sources=vhdl_sources,
        hdl_toplevel=toplevel,
        always=True
    )

    wave_file = None
    plusargs = []
    if waves and sim == "ghdl":
        wave_file = build_dir / f"{toplevel}.ghw"
        plusargs.append(f"--wave={wave_file}")   

    runner.test(
        hdl_toplevel=toplevel,
        test_module=test_module,
        build_dir=build_dir,
        plusargs=plusargs,        
    )

    if waves:
        print(f"Waves: {wave_file} {'(gerado)' if wave_file and wave_file.exists() else '(não encontrado)'}")

    if waves and open_wave and wave_file and wave_file.exists():
        os.system(f"gtkwave {wave_file} &")


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
    parser.add_argument("--waves", "-w", action="store_true", help="Gravar ondas")
    parser.add_argument("--open-wave", action="store_true", help="Abrir no GTKWave ao final")
    args = parser.parse_args()

    if args.test_name == "all":
        print("Executando TODOS os testes definidos em tests.json...")
        for name, config in TEST_CONFIGS.items():
            print(f"\n{'='*20} INICIANDO TESTE: {name.upper()} {'='*20}")
            try:
                # >>> propaga waves também no modo all:
                run_cocotb_test(**config, waves=args.waves, open_wave=False)
                print(f"{'-'*20} TESTE {name.upper()} FINALIZADO COM SUCESSO {'-'*20}")
            except Exception as e:
                print(f"[ERRO] O teste '{name}' falhou: {e}")
        print("\nTodos os testes foram executados.")
    elif args.test_name in TEST_CONFIGS:
        print(f"Executando teste específico: {args.test_name}")
        config = TEST_CONFIGS[args.test_name]
        run_cocotb_test(**config, waves=args.waves, open_wave=args.open_wave)
        print(f"\nTeste {args.test_name} finalizado.")
    else:
        print(f"Erro: Teste '{args.test_name}' não encontrado em tests.json.")
        print(f"Opções disponíveis: {list(TEST_CONFIGS.keys()) + ['all']}")
        sys.exit(1)