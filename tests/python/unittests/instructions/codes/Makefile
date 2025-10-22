# APENAS DIGITE MAKE PARA GERAR OS .hex dos .S que estiverem nessa pasta.


# Ferramentas
AS = riscv32-unknown-elf-as
LD = riscv32-unknown-elf-ld
OBJCOPY = riscv32-unknown-elf-objcopy
ARCH = -march=rv32i -mabi=ilp32

# Diretórios
SRC_DIR := .
BUILD_DIR := build

# Arquivos-fonte e saídas
SOURCES := $(wildcard $(SRC_DIR)/*.S)
HEX_FILES := $(patsubst $(SRC_DIR)/%.S, $(BUILD_DIR)/%.hex, $(SOURCES))

# Alvo padrão
all: $(HEX_FILES)
	@echo "Todos os arquivos .hex foram gerados na pasta '$(BUILD_DIR)'."

# Regra geral: compilar cada .S para .hex dentro de build/
$(BUILD_DIR)/%.hex: $(SRC_DIR)/%.S | $(BUILD_DIR)
	@echo "Gerando $@ a partir de $< ..."
	$(AS) $(ARCH) -o $(BUILD_DIR)/$*.o $<
	$(LD) -Ttext=0x0 -o $(BUILD_DIR)/$*.elf $(BUILD_DIR)/$*.o
	$(OBJCOPY) -O binary $(BUILD_DIR)/$*.elf $(BUILD_DIR)/$*.bin
	hexdump -v -e '1/4 "%08X\n"' $(BUILD_DIR)/$*.bin > $@
	rm -f $(BUILD_DIR)/$*.o $(BUILD_DIR)/$*.elf $(BUILD_DIR)/$*.bin
	@echo "Gerado: $@"

# Cria diretório build/ se não existir
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Limpeza
clean:
	rm -rf $(BUILD_DIR)
	@echo "Limpeza concluída."
