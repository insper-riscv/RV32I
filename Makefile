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
CHECK_SRCS := $(shell find src -type f \( -name '*.vhd' -o -name '*.vhdl' \) | sort)
CHECK_SRCS := src/rv32i_ctrl_consts.vhd src/genericRegister.vhd \
              $(filter-out src/rv32i_ctrl_consts.vhd src/genericRegister.vhd, \
                $(filter-out src/ROM_IP/%,$(CHECK_SRCS)))

check:
	@echo "🔍 Checking VHDL syntax with GHDL..."
	@ghdl -s --std=08 $(CHECK_SRCS)
	@echo "✅ VHDL syntax check passed"
