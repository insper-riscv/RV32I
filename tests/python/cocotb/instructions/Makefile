# ferramentas
AS = riscv32-unknown-elf-as
LD = riscv32-unknown-elf-ld
OBJCOPY = riscv32-unknown-elf-objcopy
ARCH = -march=rv32i -mabi=ilp32

# alvo: compila um assembly para .hex na mesma pasta
%.hex: %.S
	$(AS) $(ARCH) -o $*.o $<
	$(LD) -Ttext=0x0 -o $*.elf $*.o
	$(OBJCOPY) -O binary $*.elf $*.bin
	hexdump -v -e '1/4 "%08X\n"' $*.bin > $*.hex
	rm -f $*.o $*.elf $*.bin
	@echo "Gerado: $*.hex"

# limpeza
clean:
	find . -type f \( -name "*.o" -o -name "*.elf" -o -name "*.bin" -o -name "*.hex" \) -delete
