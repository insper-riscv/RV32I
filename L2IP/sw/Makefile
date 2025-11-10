# ==========================================================
# Makefile para L2IP - compilação, geração de bin/hex/mif e boot
# Atualizado: gera rom/data separadamente e carrega ROM+RAM
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

# --- ROM (instruction) outputs ---
OUT_ROM_BIN := $(BUILD_DIR)/$(OUT_BASENAME)_rom.bin
OUT_ROM_HEX := $(BUILD_DIR)/$(OUT_BASENAME)_rom.hex
OUT_ROM_MIF := $(BUILD_DIR)/$(OUT_BASENAME)_rom.mif

# --- DATA (rodata + data) outputs ---
OUT_DATA_BIN := $(BUILD_DIR)/$(OUT_BASENAME)_data.bin
OUT_DATA_HEX := $(BUILD_DIR)/$(OUT_BASENAME)_data.hex
OUT_DATA_MIF := $(BUILD_DIR)/$(OUT_BASENAME)_data.mif

# Script de boot / utilitários
HEX2MIF = $(PYTHON) $(TOOLS_DIR)/hex2mif.py
MIFBOOT = $(PYTHON) $(TOOLS_DIR)/MIFboot.py

# ==========================================================
# Memória (parâmetros configuráveis)
# ==========================================================
# Profundidade em palavras de 32 bits (word32)
MEM_ROM_WORDS ?= 8192    # ROM depth (words) -> 8192 * 4 = 32768 bytes (32 KB)
MEM_RAM_WORDS ?= 4096    # RAM depth (words) -> 4096 * 4 = 16384 bytes (16 KB)

# Tamanhos em bytes (calculados)
MEM_ROM_BYTES := $(shell echo $$(($(MEM_ROM_WORDS) * 4)))
MEM_RAM_BYTES := $(shell echo $$(($(MEM_RAM_WORDS) * 4)))

# ==========================================================
# Alvos públicos
# ==========================================================
.PHONY: build boot clean all

all: build

# ----------------------------------------------------------
# make build FILE=src/main.c
#   Compila startup_L2IP.S e $(FILE), linka, gera rom.bin e data.bin + hex/mif
# ----------------------------------------------------------
build:
	@if [ -z "$(FILE)" ]; then \
		echo "Uso: make build FILE=<arquivo.c>"; \
		exit 1; \
	fi
	@echo "\n=== Build iniciado ==="
	@mkdir -p $(BUILD_DIR)

	@echo "\n--> compilando startup_L2IP.S"
	$(CC) $(ASFLAGS) -O0 -c startup_L2IP.S -o $(BUILD_DIR)/startup_L2IP.o

	@echo "\n--> compilando $(FILE)"
	$(CC) $(CFLAGS) -O0 -c $(FILE) -o $(BUILD_DIR)/main.o

	@echo "\n--> linkando (gerando ELF)"
	$(CC) -nostdlib -nostartfiles -T $(LDSCRIPT) $(BUILD_DIR)/startup_L2IP.o $(BUILD_DIR)/main.o -lgcc -o $(OUT_ELF)

	@echo "\n--> gerando ROM bin (somente .text)"
	$(OBJCOPY) -O binary --only-section=.text $(OUT_ELF) $(OUT_ROM_BIN)

	@echo "\n--> gerando DATA bin (seções de dados: .rodata, .data, .bss)"
	# extrai todas as seções de dados (.rodata, .data, .bss) em um único binário
	-@$(OBJCOPY) -O binary \
		--only-section=.rodata \
		--only-section=.data \
		--only-section=.sdata \
		--only-section=.bss \
		$(OUT_ELF) $(OUT_DATA_BIN) 2>/dev/null || \
	( echo "Aviso: nenhuma seção de dados encontrada — gerando bin de dados vazio"; \
	  dd if=/dev/zero of=$(OUT_DATA_BIN) bs=1 count=0 >/dev/null 2>&1 )

	@echo "\n--> gerando ROM HEX (32-bit words, big-endian por linha)"
	hexdump -v -e '1/4 "%08X\n"' $(OUT_ROM_BIN) > $(OUT_ROM_HEX)

	@echo "\n--> gerando DATA HEX (32-bit words, big-endian por linha)"
	# garantir múltiplo de 4 bytes usando ferramenta externa (tools/pad_bin.py)
	@$(PYTHON) $(TOOLS_DIR)/pad_bin.py $(OUT_DATA_BIN)
	hexdump -v -e '1/4 "%08X\n"' $(OUT_DATA_BIN) > $(OUT_DATA_HEX)

	@echo "\n--> gerando ROM MIF (depth=$(MEM_ROM_WORDS)) via $(TOOLS_DIR)/hex2mif.py"
	$(HEX2MIF) $(OUT_ROM_HEX) $(OUT_ROM_MIF) $(MEM_ROM_WORDS)

	@echo "\n--> gerando DATA MIF (depth=$(MEM_RAM_WORDS)) via $(TOOLS_DIR)/hex2mif.py"
	$(HEX2MIF) $(OUT_DATA_HEX) $(OUT_DATA_MIF) $(MEM_RAM_WORDS)

	@echo "\n=== Build concluído ==="
	@echo "Saídas em $(BUILD_DIR):"
	@echo "  ELF:  $(OUT_ELF)"
	@echo "  ROM:  $(OUT_ROM_BIN)  $(OUT_ROM_HEX)  $(OUT_ROM_MIF)"
	@echo "  DATA: $(OUT_DATA_BIN)  $(OUT_DATA_HEX)  $(OUT_DATA_MIF)"

# ----------------------------------------------------------
# make boot FILE=src/main.c
#   Limpa build, executa build, e envia MIF para FPGA (MEM ID = ROM e RAM)
# ----------------------------------------------------------
boot:
	@if [ -z "$(FILE)" ]; then \
		echo "Uso: make boot FILE=<arquivo.c>"; \
		exit 1; \
	fi
	@echo "\n=== Boot: limpando build e rebuild ==="
	@rm -f $(BUILD_DIR)/* || true
	@$(MAKE) build FILE=$(FILE)

	@echo "\n=== Enviando $(OUT_DATA_MIF) para a FPGA (MEM ID = RAM) ==="
	@quartus_stp -t "$(abspath $(TOOLS_DIR)/atualizaMemoria.tcl)" "$(abspath $(OUT_DATA_MIF))" RAM 1

	@echo "\n=== Enviando $(OUT_ROM_MIF) para a FPGA (MEM ID = ROM) ==="
	@quartus_stp -t "$(abspath $(TOOLS_DIR)/atualizaMemoria.tcl)" "$(abspath $(OUT_ROM_MIF))" ROM 0

Explicação:
	@echo "\n=== Boot concluído ==="

# ----------------------------------------------------------
# make clean
# ----------------------------------------------------------
clean:
	@echo "\nLimpando diretório $(BUILD_DIR)..."
	@rm -rf $(BUILD_DIR)
	@echo "Limpeza concluída."

# ==========================================================
# Regras auxiliares (mantidas compatíveis)
# ==========================================================
$(BUILD_DIR)/startup_L2IP.o: startup_L2IP.S
	@mkdir -p $(BUILD_DIR)
	$(CC) $(ASFLAGS) -O0 -c startup_L2IP.S -o $@

$(BUILD_DIR)/main.o:
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -O0 -c $(FILE) -o $@

$(OUT_ELF): $(BUILD_DIR)/startup_L2IP.o $(BUILD_DIR)/main.o
	$(CC) -nostdlib -nostartfiles -T $(LDSCRIPT) $^ -o $@

$(OUT_ROM_BIN): $(OUT_ELF)
	$(OBJCOPY) -O binary --only-section=.text $< $@

$(OUT_DATA_BIN): $(OUT_ELF)
	$(OBJCOPY) -O binary --only-section=.rodata --only-section=.data $< $@

$(OUT_ROM_HEX): $(OUT_ROM_BIN)
	hexdump -v -e '1/4 "%08X\n"' $< > $@

$(OUT_DATA_HEX): $(OUT_DATA_BIN)
	# garante múltiplos de 4 bytes antes de hexdump
	python3 - <<PY
	import sys,os
	p='$<'
	if os.path.exists(p):
		b=open(p,'rb').read()
		if len(b)%4!=0:
			b+=b'\\x00'*(4-(len(b)%4))
		open(p,'wb').write(b)
	PY
		hexdump -v -e '1/4 "%08X\n"' $< > $@

$(OUT_ROM_MIF): $(OUT_ROM_HEX)
	$(HEX2MIF) $< $@ $(MEM_ROM_WORDS)

$(OUT_DATA_MIF): $(OUT_DATA_HEX)
	$(HEX2MIF) $< $@ $(MEM_RAM_WORDS)
