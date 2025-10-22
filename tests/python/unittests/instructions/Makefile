# Ferramentas
AS = riscv32-unknown-elf-as
LD = riscv32-unknown-elf-ld
OBJCOPY = riscv32-unknown-elf-objcopy
ARCH = -march=rv32i -mabi=ilp32

# Se FILE não for passado, mostra ajuda
ifeq ($(FILE),)
$(error Uso: make FILE=<arquivo.S>  (ex: make FILE=programa.S))
endif

# Nome base (sem extensão)
BASENAME := $(basename $(FILE))

# Alvo principal: gerar .hex a partir de um arquivo .S passado via FILE=
all: $(BASENAME).hex

# Regras de conversão
$(BASENAME).hex: $(FILE)
	$(AS) $(ARCH) -o $(BASENAME).o $(FILE)
	$(LD) -Ttext=0x0 -o $(BASENAME).elf $(BASENAME).o
	$(OBJCOPY) -O binary $(BASENAME).elf $(BASENAME).bin
	hexdump -v -e '1/4 "%08X\n"' $(BASENAME).bin > $(BASENAME).hex
	rm -f $(BASENAME).o $(BASENAME).elf $(BASENAME).bin
	@echo "Gerado: $(BASENAME).hex"

# Limpeza
clean:
	find . -type f \( -name "*.o" -o -name "*.elf" -o -name "*.bin" -o -name "*.hex" \) -delete
	@echo "Limpeza concluída"
# Ferramentas
AS = riscv32-unknown-elf-as
LD = riscv32-unknown-elf-ld
OBJCOPY = riscv32-unknown-elf-objcopy
ARCH = -march=rv32i -mabi=ilp32

# Se FILE não for passado, mostra ajuda
ifeq ($(FILE),)
$(error Uso: make FILE=<arquivo.S>  (ex: make FILE=programa.S))
endif

# Nome base (sem extensão)
BASENAME := $(basename $(FILE))

# Alvo principal: gerar .hex a partir de um arquivo .S passado via FILE=
all: $(BASENAME).hex

# Regras de conversão
$(BASENAME).hex: $(FILE)
	$(AS) $(ARCH) -o $(BASENAME).o $(FILE)
	$(LD) -Ttext=0x0 -o $(BASENAME).elf $(BASENAME).o
	$(OBJCOPY) -O binary $(BASENAME).elf $(BASENAME).bin
	hexdump -v -e '1/4 "%08X\n"' $(BASENAME).bin > $(BASENAME).hex
	rm -f $(BASENAME).o $(BASENAME).elf $(BASENAME).bin
	@echo "Gerado: $(BASENAME).hex"

# Limpeza
clean:
	find . -type f \( -name "*.o" -o -name "*.elf" -o -name "*.bin" -o -name "*.hex" \) -delete
	@echo "Limpeza concluída"
