# Diretórios
SRC_DIR := src
BUILD_DIR := build
TOOLS_DIR := tools

# Ferramentas
AS = riscv32-unknown-elf-as
LD = riscv32-unknown-elf-ld
OBJCOPY = riscv32-unknown-elf-objcopy
ARCH = -march=rv32i -mabi=ilp32
PYTHON = python3

# Nome base fixo
OUT_BASENAME := program
OUT_HEX := $(BUILD_DIR)/$(OUT_BASENAME).hex
OUT_MIF := $(BUILD_DIR)/$(OUT_BASENAME).mif

# Script de boot
LOADER := $(TOOLS_DIR)/MIFloader.py

# ==========================================================
# Comandos principais
# ==========================================================

.PHONY: build load clean

## Compila e gera o MIF
build:
	@if [ -z "$(FILE)" ]; then \
		echo "Uso: make build FILE=<arquivo.S>"; \
		exit 1; \
	fi
	$(MAKE) $(OUT_MIF) FILE=$(FILE)

## Compila e faz upload para a FPGA
boot:
	@if [ -z "$(FILE)" ]; then \
		echo "Uso: make boot FILE=<arquivo.S>"; \
		exit 1; \
	fi
	@echo "Limpando arquivos em $(BUILD_DIR)..."
	rm -f $(BUILD_DIR)/*.o $(BUILD_DIR)/*.elf $(BUILD_DIR)/*.bin $(BUILD_DIR)/*.hex $(BUILD_DIR)/*.mif
	@echo "Limpeza concluída"
	$(MAKE) $(OUT_MIF) FILE=$(FILE)
	@echo "Enviando $(OUT_MIF) para a FPGA (MEM ID = ROM)..."
	$(PYTHON) $(TOOLS_DIR)/MIFboot.py $(abspath $(OUT_MIF)) ROM

## Limpa a pasta build
clean:
	@echo "Limpando arquivos em $(BUILD_DIR)..."
	rm -f $(BUILD_DIR)/*.o $(BUILD_DIR)/*.elf $(BUILD_DIR)/*.bin $(BUILD_DIR)/*.hex $(BUILD_DIR)/*.mif
	@echo "Limpeza concluída"

# ==========================================================
# Regras de build
# ==========================================================

$(OUT_HEX):
	@mkdir -p $(BUILD_DIR)
	$(AS) $(ARCH) -o $(BUILD_DIR)/$(OUT_BASENAME).o $(FILE)
	$(LD) -Ttext=0x0 -o $(BUILD_DIR)/$(OUT_BASENAME).elf $(BUILD_DIR)/$(OUT_BASENAME).o
	$(OBJCOPY) -O binary $(BUILD_DIR)/$(OUT_BASENAME).elf $(BUILD_DIR)/$(OUT_BASENAME).bin
	hexdump -v -e '1/4 "%08X\n"' $(BUILD_DIR)/$(OUT_BASENAME).bin > $(OUT_HEX)
	rm -f $(BUILD_DIR)/$(OUT_BASENAME).o $(BUILD_DIR)/$(OUT_BASENAME).elf $(BUILD_DIR)/$(OUT_BASENAME).bin
	@echo "Gerado: $(OUT_HEX)"

$(OUT_MIF): $(OUT_HEX)
	@mkdir -p $(BUILD_DIR)
	@echo "Gerando $(OUT_MIF)..."
	@$(PYTHON) $(TOOLS_DIR)/hex2mif.py $(OUT_HEX) $(OUT_MIF) 512
	@echo "Gerado: $(OUT_MIF)"
