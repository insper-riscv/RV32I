# Make sure /bin/bash is used for the 'find' in clean
SHELL := /bin/bash

.PHONY: test run clean

# Run all tests (no args)
test:
	python3 tests/python/runner.py

# Run a single test by name
# Usage: make run TEST=<test_name>
run:
ifndef TEST
	$(error Usage: make run TEST=<test_name>)
endif
	python3 tests/python/runner.py $(TEST)

# Remove generated waveforms
clean:
	find . -type f \( -name '*.vcd' -o -name '*.ghw' \) -print -delete


# ---------------------------------------------------------------
# VHDL Syntax Check (using GHDL)
# Run with:  make check
# ---------------------------------------------------------------
# ---------------------------------------------------------------
# VHDL Syntax Check (GHDL) — EXCLUI IPs de vendor (altera_mf etc.)
# ---------------------------------------------------------------
GHDL := ghdl
STD  := --std=08
WDIR := build/ghdl

# 1) Coleta todos .vhd/.vhdl
CHECK_SRCS_ALL := $(shell find src -type f \( -name '*.vhd' -o -name '*.vhdl' \) | sort)

# 2) EXCLUI vendors/IPs (ajuste os padrões conforme seu repo)
EXCLUDE_GLOB := \
  src/ROM1PORT/% \
  src/RAM1PORT/% \
  src/ROM_IP/% \
  src/%/ip/% \
  src/%/quartus_ip/% \
  src/**/ip/% \
  src/**/quartus_ip/%

CHECK_SRCS_ALL := $(filter-out $(EXCLUDE_GLOB),$(CHECK_SRCS_ALL))

# 3) Coloque consts e genericRegister primeiro
CHECK_SRCS := src/rv32i_ctrl_consts.vhd src/genericRegister.vhd \
              $(filter-out src/rv32i_ctrl_consts.vhd src/genericRegister.vhd,$(CHECK_SRCS_ALL))

# 4) (Opcional) Forçar ordem dos GPIO: filhos → topo (auto-descoberta)
GPIO_DEC  := $(firstword $(shell find src -type f -iname "gpio*_operation*decoder*.vh*"))
GPIO_CELL := $(firstword $(shell find src -type f -iname "gpio*_cell*.vh*"))
GPIO_TOP  := $(firstword $(shell find src -type f -iname "gpio.vh*"))

ifeq ($(strip $(GPIO_TOP)),)
  ORDERED_SRCS := $(CHECK_SRCS)
else
  ORDERED_SRCS := \
    $(GPIO_DEC) $(GPIO_CELL) \
    $(filter-out $(GPIO_TOP) $(GPIO_DEC) $(GPIO_CELL),$(CHECK_SRCS)) \
    $(GPIO_TOP)
endif

.PHONY: print-check check
print-check:
	@echo "Arquivos que o check vai analisar:"; echo
	@printf '  %s\n' $(ORDERED_SRCS)

check:
	@echo "🔍 Checking VHDL syntax with GHDL..."
	@mkdir -p $(WDIR)
	@$(GHDL) -a $(STD) --work=work --workdir=$(WDIR) $(ORDERED_SRCS)
	@$(GHDL) -e $(STD) --work=work --workdir=$(WDIR) GPIO || true
	@echo "✅ VHDL syntax check passed"