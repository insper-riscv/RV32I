# RISC-V Processor (RV32I) — VHDL + Automated Testing

**Authors:** [Ilana Finger](https://github.com/ilacftemp), [Leonardo Paloschi](), [Lucas Lima](https://github.com/lucasouzamil) e [Pedro Ventura](https://github.com/pedropcventura).
**Advisor:** [Rafael Corsi](https://github.com/rafaelcorsi).

This repository implements, in **VHDL**, a processor based on the **RV32I instruction set** (32-bit RISC-V).
The focus is on **architecture implementation and verification**: in addition to the hardware itself, the project provides a **simulation infrastructure with Cocotb** (Python) and **Quartus projects** for FPGA testing.

## Project Overview

* **Architecture**: RV32I (32-bit integers).
* **Typical blocks**: register bank, ALU, immediate generator, simple ROM/RAM, control unit, and the *top* `riscv.vhd`.
* **Verification**: automated tests in **Cocotb** (Python testing library) with **GHDL** (VHDL simulator). Simulation waveforms can be opened in **GTKWave**.
* **FPGA**: **Quartus projects** for synthesis and practical experiments (target board used: *Cyclone V: 5CEBA4F23C7 (the FPGA on the DE0-CV board)*).


## Repository Structure (function of each folder)

```
.
├── quartus/        # Main Quartus project for the processor (FPGA)
├── src/            # VHDL modules used by the Quartus project and in tests
└── tests/          # Verification tests (simulation + FPGA projects for modules)
    ├── FPGA/       # Small Quartus projects to test modules separately
    └── python/     # Cocotb tests (simulated), runner, and simulation artifacts
```

### `quartus/`

Where the **main FPGA project** is located. This is where you open in Quartus, configure pins, compile, and generate the bitstream. Uses the modules from `src/`.

### `src/`

All **VHDL modules** of the processor (register bank, ALU, control unit, etc.).
These files are included in the **Quartus project** and are also **targets for simulation tests**.

### `tests/`

Brings together two verification fronts:

* `tests/FPGA/`: **support Quartus projects** to test **isolated modules** directly on the FPGA (useful for debugging blocks outside the complete processor).
* `tests/python/`: where the **Cocotb testbenches** (Python), the **runner**, and **simulation artifacts** are located.

  * `cocotb/`: **Python tests** (each file tests a VHDL module/entity).
  * `utils/runner.py`: **orchestrates** compilation and simulation (reads the `tests.json` catalog).
  * `tests.json`: **test catalog**, mapping each test to the VHDL *toplevel* and required modules/entities.
  * `sim_build/<toplevel>/`: **simulation output** for the respective *toplevel* test (e.g., `results.xml`, `waves.ghw` to open in GTKWave).

  > To learn more about the simulated tests, check the [README in `tests/python/`](tests/python/README.md)


## Development Environment (Dev Container)

This project ships with a ready-to-use VS Code **Dev Container** so you don’t have to install cocotb, GHDL, or Python manually.

### Prerequisites
1. [Docker](https://docs.docker.com/get-docker/) (Desktop on Mac/Windows, Engine on Linux)
2. [Visual Studio Code](https://code.visualstudio.com/)
3. VS Code extension: **Dev Containers** (ms-vscode-remote.remote-containers)

### First time setup
1. Open the folder in VS Code.
2. VS Code will detect automatically `.devcontainer/devcontainer.json` and prompt:
    
    **“Reopen in Container?”** → click **Yes**.

### Usage inside the container
- Run all tests:
    
    ```bash
    make test
    ```
    
- Open waveforms (`.vcd`) with GTKWave:
    
    ```bash
    gtkwave <file>.ghw
    ```