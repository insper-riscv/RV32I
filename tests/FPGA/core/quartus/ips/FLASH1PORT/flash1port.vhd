-- FLASH: this test's own "firmware" (.flash_entry trampoline + .text
-- -- see tools/riscv_build/crt0.S/link.ld), JTAG-rewritten per test
-- via the In-System Memory Content Editor, init_file "./init.mif"
-- (same top-level filename build_fpga.py already overwrites for
-- every test -- see config.yaml quartus.rom_mif_target).
--
-- Single-port now (unlike the old combined ROM, which needed a
-- second physical instance -- ips/ROM1PORT_MEM -- for the MEM
-- stage's own read port, since Quartus Lite can't do DUAL_PORT +
-- ENABLE_RUNTIME_MOD together, confirmed empirically via
-- quartus_map): the MEM stage no longer touches FLASH at all (see
-- rv32im_pipeline_core.vhd), so that whole workaround -- and its
-- doubled chip-memory cost -- goes away.
--
-- numwords_a/widthad_a must match rv32im_pipeline_core.vhd's IF-stage
-- decode being address-RAW (no base subtraction -- see
-- is_boot_rom_if/is_boot_rom_d): this IP is sized to cover the FULL
-- 0..RAM_BASE range, not just FLASH's own logical span, so if_addr
-- can index it directly. See config.yaml memory.rom_base/rom_words
-- and bin_to_image.read_words' pad_words parameter (the tooling side
-- of this same convention -- a test's own image gets left-padded with
-- rom_base/4 zero words before conversion to .mif/.hex).
LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY flash1port IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		rden		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0) := (OTHERS => '0');
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END flash1port;

ARCHITECTURE SYN OF flash1port IS

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
		lpm_hint => "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=FLASH",
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
