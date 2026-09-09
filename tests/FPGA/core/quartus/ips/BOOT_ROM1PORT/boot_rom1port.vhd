-- BOOT_ROM: the fixed, generic bootloader's own memory. Programmed
-- ONCE (initial full Quartus compile, init_file "./boot_rom_init.mif"
-- -- built from tools/riscv_build/boot_rom.S/boot_rom.ld), never
-- JTAG-rewritten per test -- only FLASH (ips/FLASH1PORT/flash1port.vhd)
-- gets that treatment. See rv32im_pipeline_core.vhd's
-- BOOT_ROM_SIZE_BYTES / config.yaml memory.boot_rom_words -- both
-- must agree with numwords_a/widthad_a below (2K = 512 words, 9
-- bits).
--
-- Formerly "ROM1PORT" (this same recipe held the WHOLE combined
-- text+data image before the BOOT_ROM/FLASH/RAM split) -- renamed to
-- make its now-narrower, fixed role explicit. ENABLE_RUNTIME_MOD is
-- kept for consistency/JTAG In-System Memory Content Editor
-- compatibility even though nothing JTAG-rewrites this in normal
-- operation.
LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY boot_rom1port IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		rden		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0) := (OTHERS => '0');
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END boot_rom1port;

ARCHITECTURE SYN OF boot_rom1port IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (31 DOWNTO 0);

BEGIN
	q    <= sub_wire0(31 DOWNTO 0);

	altsyncram_component : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "./boot_rom_init.mif",
		intended_device_family => "Cyclone V",
		lpm_hint => "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=BOOT_ROM",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "SINGLE_PORT",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "UNREGISTERED",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		widthad_a => 9,
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
