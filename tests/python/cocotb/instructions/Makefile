# tests/python/cocotb/instructions/Makefile
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# ---- Toolchain ----
RISCV_PREFIX ?= riscv32-unknown-elf
AS      := $(RISCV_PREFIX)-as
LD      := $(RISCV_PREFIX)-ld
GCC     := $(RISCV_PREFIX)-gcc
OBJCOPY := $(RISCV_PREFIX)-objcopy
NM      := $(RISCV_PREFIX)-nm

# ---- Flags e includes ----
ARCH := -march=rv32i -mabi=ilp32

# Linker script que define .signature e símbolos begin/end_signature
LDS  := tests/hw/link.ld

# Raiz do riscv-arch-test (vendorizado em tests/)
ARCHTEST_ROOT := tests/third_party/riscv-arch-test
SUITE_ROOT    := $(ARCHTEST_ROOT)/riscv-test-suite

# Includes do ambiente/macros do arch-test
ENV_INCS := -I$(SUITE_ROOT)/env -I$(ARCHTEST_ROOT)/env \
            -I$(SUITE_ROOT)/macros/scalar -I$(ARCHTEST_ROOT)/include

.PHONY: all clean
.SECONDARY:

# (Opcional) constrói todos os .hex encontrados sob instructions/
SRCS := $(shell find tests/python/cocotb/instructions -name '*.S' 2>/dev/null)
ELFS := $(SRCS:.S=.elf)
HEXS := $(SRCS:.S=.hex)
all: $(HEXS)

# .S -> .elf via GCC (usa env do arch-test) + link.ld com .signature
%.elf: %.S $(LDS)
	@mkdir -p $(dir $@)
	$(GCC) -nostdlib -nostartfiles -static $(ARCH) $(ENV_INCS) -T $(LDS) -o $@ $<

# .elf -> .hex (formato verilog; 1 palavra/linha)
%.hex: %.elf
	$(OBJCOPY) -O verilog $< $@
	@echo "Gerado (verilog): $@"

clean:
	@find tests/third_party -type f \( -name '*.o' -o -name '*.elf' -o -name '*.bin' -o -name '*.hex' \) -print -delete 2>/dev/null || true