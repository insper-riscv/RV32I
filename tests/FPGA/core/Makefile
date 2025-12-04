# --- variáveis relevantes (atualize conforme seu Makefile existente) ---
PROJECT_NAME := quartus/core_fpga_test
ASM_DIR := asm_tests
BUILD_DIR := build
TOOLS_DIR := tools
ROM_MIF := quartus/ips/ROM1PORT/init.mif
SOF_FILE := quartus/output_files/core_fpga_test.sof
COMPARE_SCRIPT := $(TOOLS_DIR)/compare_mif_with_json.py

# detecta o primeiro .S em asm_tests (mantém comportamento anterior)
ASM_FILE := $(shell ls $(ASM_DIR)/*.S 2>/dev/null | head -n 1)
ifeq ($(ASM_FILE),)
$(error Nenhum arquivo .S encontrado em $(ASM_DIR). Coloque seu .S lá ou ajuste ASM_DIR.)
endif
BNAME := $(basename $(notdir $(ASM_FILE)))

# saída do dump agora em core/output_mifs/<testname>_ram.mif
OUTDIR := output_mifs
MEM_DUMP := $(OUTDIR)/$(BNAME)_ram.mif

# Memória editável: index (conforme sua configuração)
MEM_IDX := 1

# número de palavras (32-bit) da RAM (ajuste se necessário)
RAM_WORDS := 4096

# tempo de espera (segundos) após programar para o teste rodar
WAIT_SECS := 5

# ferramentas RISC-V (assumidas; se tiver toolchain diferente, ajuste)
AS := riscv32-unknown-elf-as
LD := riscv32-unknown-elf-ld
OBJCOPY := riscv32-unknown-elf-objcopy
HEXDUMP := hexdump

PY := python3
HEX2MIF := $(TOOLS_DIR)/hex2mif.py

# -------- regras --------
.PHONY: all asm build_hex update_rom quartus_compile program_board wait dump_ram clean

all: build_and_flash dump_ram compare
	@echo "Fluxo completo finalizado."

# detecta o primeiro .S em asm_tests
ASM_FILE := $(shell ls $(ASM_DIR)/*.S 2>/dev/null | head -n 1)
ifeq ($(ASM_FILE),)
$(error Nenhum arquivo .S encontrado em $(ASM_DIR). Coloque seu .S lá ou ajuste ASM_DIR.)
endif
BNAME := $(basename $(notdir $(ASM_FILE)))
HEX_FILE := $(BUILD_DIR)/$(BNAME).hex
BIN_FILE := $(BUILD_DIR)/$(BNAME).bin
ELF_FILE := $(BUILD_DIR)/$(BNAME).elf

# 1) montar .S -> .hex (raw words 32-bit big-hex lines, compatível com tools/hex2mif.py)
asm: $(HEX_FILE)
	@echo "Assembly gerado: $(HEX_FILE)"

$(BUILD_DIR)/%.hex: $(ASM_DIR)/%.S | $(BUILD_DIR)
	@echo "Compilando $< ..."
	@if command -v $(AS) >/dev/null 2>&1; then \
		$(AS) -march=rv32i -mabi=ilp32 -o $(BUILD_DIR)/$*.o $< ; \
		$(LD) -Ttext=0x0 -o $(ELF_FILE) $(BUILD_DIR)/$*.o ; \
		$(OBJCOPY) -O binary $(ELF_FILE) $(BIN_FILE) ; \
		$(HEXDUMP) -v -e '1/4 "%08X\n"' $(BIN_FILE) > $(HEX_FILE) ; \
		rm -f $(BUILD_DIR)/$*.o $(ELF_FILE) $(BIN_FILE) ; \
	else \
		echo "Aviso: assembler $(AS) não encontrado. Coloque um .hex em $(BUILD_DIR) com mesmo nome ou instale toolchain RISC-V."; \
		exit 1; \
	fi
	@echo "Gerado: $(HEX_FILE)"

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# 2) converter hex -> mif e copiar para ROM do projeto
update_rom: asm
	@echo "Gerando MIF e atualizando $(ROM_MIF) ..."
	@$(PY) $(HEX2MIF) $(HEX_FILE) $(ROM_MIF) 4096
	@echo "ROM atualizada: $(ROM_MIF)"

# 3) sintetizar com quartus_sh
quartus_compile: update_rom
	@echo "Iniciando compilação Quartus (projeto: $(PROJECT_NAME)) ..."
	@quartus_sh --flow compile $(PROJECT_NAME)
	@echo "Compilação Quartus concluída."

# 4) programar placa (SOF)
program_board: quartus_compile
	@echo "Programando placa (SOF: $(SOF_FILE)) ..."
	@quartus_pgm -m JTAG -o "p;$(SOF_FILE)"
	@echo "Programação enviada."

# 5) espera o teste rodar
wait:
	@echo "Aguardando $(WAIT_SECS) segundos para o programa executar na placa..."
	@sleep $(WAIT_SECS)

# helper que junta compile+program
build_and_flash: program_board wait
	@echo "Build e flash completos."

# 6) dump da RAM para a MIF (usa quartus_stp + Tcl gerado dinamicamente)
# gera tools/dumpMemory.tcl que usa save_content_from_memory_to_file do pacote ::quartus::insystem_memory_edit
dump_ram: build_and_flash
	@echo "Criando diretório de saída para MIFs: $(OUTDIR)"
	@mkdir -p $(OUTDIR)
	@echo "Executando quartus_stp para salvar memória em: $(MEM_DUMP)"
	@quartus_stp -t $(TOOLS_DIR)/dumpMemory.tcl $(MEM_DUMP) $(MEM_IDX)
	@echo "Dump gravado em: $(MEM_DUMP)"

# 7) comparar o MIF gerado com o gabarito JSON (gabarito em asm_tests/<name>.json)
compare: dump_ram
	@echo "Comparando $(MEM_DUMP) com asm_tests/$(BNAME).json ..."
	@if [ ! -f "$(COMPARE_SCRIPT)" ]; then \
	    echo "Erro: script de comparação não encontrado: $(COMPARE_SCRIPT)"; exit 1; \
	fi
	@if [ ! -f "$(MEM_DUMP)" ]; then \
	    echo "Erro: MIF de dump não encontrado: $(MEM_DUMP)"; exit 1; \
	fi
	@if [ ! -f "asm_tests/$(BNAME).json" ]; then \
	    echo "Erro: gabarito JSON asm_tests/$(BNAME).json não encontrado"; exit 1; \
	fi
	@$(PY) $(COMPARE_SCRIPT) $(MEM_DUMP) asm_tests/$(BNAME).json
	@echo "Comparação finalizada."
