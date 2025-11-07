# ==========================================================
# Makefile para L2IP - compilação, geração de bin/hex/mif e boot
# ==========================================================

# Diretórios
SRC_DIR := .
BUILD_DIR := build
TOOLS_DIR := tools

# Ferramentas
CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
PYTHON = python3

# Flags / arquitetura
ARCH = -march=rv32i -mabi=ilp32
CFLAGS = $(ARCH) -O0 -Wall
ASFLAGS = $(ARCH)

# Linker script
LDSCRIPT = L2IP.ld

# Nome base
OUT_BASENAME := firmware
OUT_ELF := $(BUILD_DIR)/$(OUT_BASENAME).elf
OUT_BIN := $(BUILD_DIR)/$(OUT_BASENAME).bin
OUT_HEX := $(BUILD_DIR)/$(OUT_BASENAME).hex
OUT_MIF := $(BUILD_DIR)/$(OUT_BASENAME).mif

# Script de boot / utilitários
HEX2MIF = $(PYTHON) $(TOOLS_DIR)/hex2mif.py
MIFBOOT = $(PYTHON) $(TOOLS_DIR)/MIFboot.py

# ==========================================================
# Alvos públicos
# ==========================================================
.PHONY: build boot clean all

all: build

# ----------------------------------------------------------
# make build FILE=src/main.c
#   Compila startup_L2IP.S e $(FILE), linka, gera bin/hex/mif
# ----------------------------------------------------------
build:
	@if [ -z "$(FILE)" ]; then \
		echo "Uso: make build FILE=<arquivo.c>"; \
		exit 1; \
	fi
	@echo "=== Build iniciado ==="
	@mkdir -p $(BUILD_DIR)

	@echo "--> compilando startup_L2IP.S"
	$(CC) $(ASFLAGS) -O0 -c startup_L2IP.S -o $(BUILD_DIR)/startup_L2IP.o

	@echo "--> compilando $(FILE)"
	$(CC) $(CFLAGS) -O0 -c $(FILE) -o $(BUILD_DIR)/main.o

	@echo "--> linkando (gerando ELF)"
	$(CC) -nostdlib -nostartfiles -T $(LDSCRIPT) $(BUILD_DIR)/startup_L2IP.o $(BUILD_DIR)/main.o -lgcc -o $(OUT_ELF)

	@echo "--> gerando BIN (imagem binária)"
	$(OBJCOPY) -O binary $(OUT_ELF) $(OUT_BIN)

	@echo "--> gerando HEX (32-bit words, big-endian per linha)"
	hexdump -v -e '1/4 "%08X\n"' $(OUT_BIN) > $(OUT_HEX)


	@echo "--> gerando MIF (depth=8192) via $(TOOLS_DIR)/hex2mif.py"
	$(HEX2MIF) $(OUT_HEX) $(OUT_MIF) 8192

	@echo "=== Build concluído ==="
	@echo "Saídas em $(BUILD_DIR):"
	@echo "  $(OUT_ELF)"
	@echo "  $(OUT_BIN)"
	@echo "  $(OUT_HEX)"
	@echo "  $(OUT_MIF)"

# ----------------------------------------------------------
# make boot FILE=src/main.c
#   Limpa build, executa build, e envia MIF para FPGA (MEM ID = ROM)
# ----------------------------------------------------------
boot:
	@if [ -z "$(FILE)" ]; then \
		echo "Uso: make boot FILE=<arquivo.c>"; \
		exit 1; \
	fi
	@echo "=== Boot: limpando build e rebuild ==="
	@rm -f $(BUILD_DIR)/* || true
	@$(MAKE) build FILE=$(FILE)
	@echo "=== Enviando $(OUT_MIF) para a FPGA (MEM ID = ROM) ==="
	@$(MIFBOOT) $(abspath $(OUT_MIF)) ROM
	@echo "=== Boot concluído ==="

# ----------------------------------------------------------
# make clean
# ----------------------------------------------------------
clean:
	@echo "Limpando diretório $(BUILD_DIR)..."
	@rm -rf $(BUILD_DIR)
	@echo "Limpeza concluída."

# ==========================================================
# Regras auxiliares (se desejar compilar componentes separadamente)
# Não usadas diretamente pelos alvos acima, mantidas para referência.
# ==========================================================
$(BUILD_DIR)/startup_L2IP.o: startup_L2IP.S
	@mkdir -p $(BUILD_DIR)
	$(CC) $(ASFLAGS) -O0 -c startup_L2IP.S -o $@

$(BUILD_DIR)/main.o:
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -O0 -c $(FILE) -o $@

$(OUT_ELF): $(BUILD_DIR)/startup_L2IP.o $(BUILD_DIR)/main.o
	$(CC) -nostdlib -nostartfiles -T $(LDSCRIPT) $^ -o $@

$(OUT_BIN): $(OUT_ELF)
	$(OBJCOPY) -O binary $< $@

$(OUT_HEX): $(OUT_BIN)
	hexdump -v -e '1/4 "%08X\n"' $< > $@

$(OUT_MIF): $(OUT_HEX)
	$(HEX2MIF) $< $@ 8192
