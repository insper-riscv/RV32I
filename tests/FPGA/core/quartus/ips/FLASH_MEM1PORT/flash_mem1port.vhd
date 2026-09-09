-- Segunda copia fisica da FLASH, so' para leitura de dado pelo
-- estagio MEM (rv32im_pipeline_core.vhd, flash_addr2/flash_rden2) --
-- necessaria para o copy-loop de .data em boot_rom.S conseguir ler
-- FLASH como dado (a fonte, LMA, de .data). NAO e' uma "porta B" de
-- uma unica FLASH dual-port: uma IP altsyncram DUAL_PORT com
-- ENABLE_RUNTIME_MOD=YES nao compila nesta edicao do Quartus --
-- confirmado empiricamente (mesmo problema documentado, no seu
-- tempo, para a antiga ips/ROM1PORT_MEM). A alternativa e' esta:
-- clone exato de flash1port.vhd (mesma receita), so' com
-- INSTANCE_NAME diferente ("FLASH_MEM") para o In-System Memory
-- Content Editor tratar como uma instancia JTAG separada.
--
-- As DUAS copias (esta e ips/FLASH1PORT/flash1port.vhd) precisam do
-- MESMO conteudo sempre -- riscv_tools.rom_writer regrava as duas via
-- JTAG a cada troca de teste (ver config.yaml quartus.
-- rom_mem_instances, uma lista de 2 indices).
--
-- BOOT_ROM nao precisa desse tratamento -- nunca tem .data proprio
-- (boot_rom.S e' so' codigo com imediatos fixos), entao nunca e' lido
-- como dado.
LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY flash_mem1port IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		rden		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0) := (OTHERS => '0');
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END flash_mem1port;

ARCHITECTURE SYN OF flash_mem1port IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (31 DOWNTO 0);

BEGIN
	q    <= sub_wire0(31 DOWNTO 0);

	altsyncram_component : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "./init.mif",
		intended_device_family => "Cyclone V",
		lpm_hint => "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=FLASH_MEM",
		lpm_type => "altsyncram",
		numwords_a => 7680,
		operation_mode => "SINGLE_PORT",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "UNREGISTERED",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		widthad_a => 13,
		width_a => 32,
		width_byteena_a => 1
	)
	PORT MAP (
		address_a => address,
		clock0 => clock,
		rden_a => rden,
		wren_a => wren,
		data_a => data,
		q_a => sub_wire0
	);

END SYN;
