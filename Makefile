SHELL := /bin/bash

.PHONY: test run clean compliance compliance-one

RISCV_PREFIX := $(abspath toolchain/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-)
export RISCV_PREFIX

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

clean:
	rm -rf build/archtest tests/python/sim_build