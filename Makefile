SHELL := /bin/bash

.PHONY: test run clean compliance compliance-one refs build-refs arch-elves

RISCV_PREFIX := $(abspath toolchain/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-)
export RISCV_PREFIX
export PYTHONPATH := $(PWD)

ARCHTEST_ISA           ?= rv32i
ARCHTEST_BUILD_DIR     ?= build/archtest
ARCHTEST_REF_DIR       ?= tests/third_party/riscv-arch-test/tools/reference_outputs
# Spike 1.1.1-dev: usa UM único -m com lista ROM,RAM (decimal)
ARCHTEST_SPIKE_MEM     ?= -m2147483648:1048576,536870912:65536
# Logs + testes mais faladores/rápidos
PYTHONUNBUFFERED       ?= 1
ARCHTEST_MAX_CYCLES    ?= 200000
export ARCHTEST_ISA ARCHTEST_BUILD_DIR ARCHTEST_REF_DIR ARCHTEST_SPIKE_MEM PYTHONUNBUFFERED ARCHTEST_MAX_CYCLES

test:
	python3 tests/python/runner.py

run:
ifndef TEST
	$(error Use: make run TEST=<test_name>)
endif
	python3 tests/python/runner.py $(TEST)

compliance:
	python3 tests/python/runner.py compliance

compliance-one:
ifndef TEST
	$(error Use: make compliance-one TEST=<add|sub|and|...>)
endif
	python3 tests/python/runner.py compliance $(TEST)

# monta apenas os ELFs/HEX/META da suíte arch-test, sem rodar Cocotb
arch-elves:
	python3 tests/python/runner.py assemble

# Gera assinaturas de referência com Spike (independente da simulação)
arch-refs:
	python3 tests/third_party/riscv-arch-test/tools/gen_reference_outputs.py --isa=$(ARCHTEST_ISA) --build-dir=$(ARCHTEST_BUILD_DIR) --ref-dir=$(ARCHTEST_REF_DIR) --spike-mem="$(ARCHTEST_SPIKE_MEM)"

build-refs:
	$(MAKE) arch-elves
	$(MAKE) arch-refs
	
clean:
	rm -rf build/archtest tests/python/sim_build