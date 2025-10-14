# =====================[ COMUM ]=====================
AS       = riscv32-unknown-elf-as
LD       = riscv32-unknown-elf-ld
GCC      = riscv32-unknown-elf-gcc
OBJCOPY  = riscv32-unknown-elf-objcopy
NM       = riscv32-unknown-elf-nm

ARCH     = -march=rv32i -mabi=ilp32
LDS      = tests/hw/link.ld

# raiz vendorizada do arch-test (ajuste se diferente)
ARCHTEST_ROOT = tests/third_party/riscv-arch-test
SUITE_ROOT    = $(ARCHTEST_ROOT)/riscv-test-suite
ENV_INCS      = -I$(SUITE_ROOT)/env -I$(ARCHTEST_ROOT)/env

.PHONY: clean

# =====================[ SEU FLUXO LOCAL ]=====================
# (para os seus .S próprios, no mesmo diretório)
# .S -> .hex via as/ld + hexdump (mantém seu formato atual)
%.hex: %.S
	$(AS) $(ARCH) -o $*.o $<
	$(LD) -Ttext=0x0 -o $*.elf $*.o
	$(OBJCOPY) -O binary $*.elf $*.bin
	hexdump -v -e '1/4 "%08X\n"' $*.bin > $*.hex
	rm -f $*.o $*.elf $*.bin
	@echo "Gerado (local): $*.hex"

# =====================[ ARCH-TEST RV32I ]=====================
# (regras com caminho para evitar colisão com as suas)
# .S (arch-test) -> .elf usando gcc, includes e link.ld (assina .signature)
$(SUITE_ROOT)/rv32i_m/I/src/%.elf: $(SUITE_ROOT)/rv32i_m/I/src/%.S $(LDS)
	$(GCC) -nostdlib -nostartfiles -static $(ARCH) $(ENV_INCS) -T $(LDS) -o $@ $<

# .elf -> .hex: escolha 1 das duas opções abaixo conforme seu testbench

# Opção A) gerar verilog-hex direto (mais simples, mas mude seu loader se precisar)
$(SUITE_ROOT)/rv32i_m/I/src/%.hex: $(SUITE_ROOT)/rv32i_m/I/src/%.elf
	$(OBJCOPY) -O verilog $< $@
	@echo "Gerado (arch-test verilog): $@"

# Opção B) manter o MESMO formato do seu hexdump (descomente e comente a A)
#$(SUITE_ROOT)/rv32i_m/I/src/%.hex: $(SUITE_ROOT)/rv32i_m/I/src/%.elf
#	$(OBJCOPY) -O binary $< $*.bin
#	hexdump -v -e '1/4 "%08X\n"' $*.bin > $@
#	rm -f $*.bin
#	@echo "Gerado (arch-test hexdump): $@"

# util: ver begin/end da assinatura no ELF (para recorte na RAM)
$(SUITE_ROOT)/rv32i_m/I/src/%.siginfo: $(SUITE_ROOT)/rv32i_m/I/src/%.elf
	@$(NM) -n $< | egrep 'begin_signature|end_signature' || true

# =====================[ LIMPEZA ]=====================
clean:
	find . -type f \( -name "*.o" -o -name "*.elf" -o -name "*.bin" -o -name "*.hex" \) -delete