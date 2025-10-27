SHELL := /bin/bash

.PHONY: test run clean compliance compliance-one refs build-refs arch-elves

RISCV_PREFIX := $(abspath toolchain/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-)
export RISCV_PREFIX
export PYTHONPATH := $(PWD)

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
refs:
	ARCHTEST_REF_POLICY=regen python3 tests/third_party/riscv-arch-test/tools/gen_reference_outputs.py

build-refs:
	$(MAKE) arch-elves
	$(MAKE) refs

clean:
	rm -rf build/archtest tests/python/sim_build