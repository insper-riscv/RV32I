library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity BLinkLed is
  port (
    CLOCK_50 : in  std_logic;
    FPGA_RESET_N : in std_logic;
    KEY      : in  std_logic_vector(3 downto 0);
	 LEDR : out std_logic_vector(9 downto 0);

    HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0)
  );
end entity;

architecture behaviour of BLinkLed is

  signal CLK : std_logic;
  signal RAM_out : std_logic_vector(31 downto 0);
  signal ALU_out_CPU : std_logic_vector (31 downto 0);
  signal mask_ram_CPU : std_logic_vector(3 downto 0);
  signal weRAM_CPU : std_logic;
  signal reRAM_CPU : std_logic;
  signal eRAM_CPU : std_logic;
  signal data_rs2 : std_logic_vector(31 downto 0);
  signal PC_out : std_logic_vector(31 downto 0);
  signal instruction : std_logic_vector(31 downto 0);

  signal hex0_in, hex1_in, hex2_in, hex3_in, hex4_in, hex5_in : std_logic_vector(7 downto 0);

  -- endereço do CPU é byte-addressable
  signal addr_bit11  : std_logic;               -- ALU_out_CPU(11)
  signal addr_word   : unsigned(8 downto 0);    -- bits [10:2] => índice de palavra (9 bits)
  signal enable_ram  : std_logic;
  signal enable_io   : std_logic;

  signal hex0_we, hex1_we, hex2_we, hex3_we, hex4_we, hex5_we : std_logic;

begin

  --CLK <= CLOCK_50;
  
  edgeDetectorKey : entity work.edgeDetector
			port map (clk => CLOCK_50, entrada => NOT(FPGA_RESET_N), saida => CLK);

  -- ROM (instruções): PC_out é byte-address; ROM interno indexa por palavra via [memoryAddrWidth+1 downto 2]
  ROM : entity work.ROM
    port map (
      addr => PC_out,
      data => instruction
    );

  -- CPU
  CPU : entity work.rv32i
    port map (
      CLK => CLK,
		inst_addr => PC_out,
		inst => instruction,
		weRAM => weRAM_CPU,
		reRAM => reRAM_CPU,
		eRAM => eRAM_CPU,
		data_addr => ALU_out_CPU, --ALU OTU
		byte_enable => mask_ram_CPU, -- MASK RAM
		data_in => RAM_out, -- EXTENDER RAM IN
		data_out => data_rs2 -- STORE MANAGER OUT
    );

  -- pega bit 11 e word index (addr/4)
  addr_bit11 <= ALU_out_CPU(11);
  addr_word  <= unsigned(ALU_out_CPU(10 downto 2));  -- word index 0..511

  -- usa somente o bit 11 para escolher RAM vs IO:
  -- note: aqui definimos que bit11 = '1' -> RAM; bit11 = '0' -> IO (HEXs)
  enable_ram <= '1' when addr_bit11 = '1' else '0';
  enable_io  <= '1' when addr_bit11 = '0' else '0';

  -- RAM: recebe índice de palavra (9 bits) como std_logic_vector
  RAM : entity work.RAM
    port map (
      clk      => CLK,
      addr     => ALU_out_CPU,         -- 9 bits: 0..511
      data_in  => data_rs2,
      data_out => RAM_out,
      weRAM    => weRAM_CPU and enable_ram,            -- só aceita writes no bloco RAM (bit11='1')
      reRAM    => reRAM_CPU and enable_ram,
      eRAM     => eRAM_CPU and enable_ram,
      mask     => mask_ram_CPU
    );

  -- HEXs mapados para os endereços byte: 512,516,520,524,528,532
  -- correspondem a word indices: 512/4=128, 516/4=129, ..., 532/4=133
  hex0_we <= '1' when ((enable_io = '1' and weRAM_CPU = '1') and (ALU_out_CPU(31 downto 2) = "000000000000000000001000000000")) else '0';
  hex1_we <= '1' when ((enable_io = '1' and weRAM_CPU = '1') and (ALU_out_CPU(31 downto 2) = "000000000000000000001000000100")) else '0';
  hex2_we <= '1' when ((enable_io = '1' and weRAM_CPU = '1') and (ALU_out_CPU(31 downto 2) = "000000000000000000001000001000")) else '0';
  hex3_we <= '1' when ((enable_io = '1' and weRAM_CPU = '1') and (ALU_out_CPU(31 downto 2) = "000000000000000000001000001100")) else '0';
  hex4_we <= '1' when ((enable_io = '1' and weRAM_CPU = '1') and (ALU_out_CPU(31 downto 2) = "000000000000000000001000010000")) else '0';
  hex5_we <= '1' when ((enable_io = '1' and weRAM_CPU = '1') and (ALU_out_CPU(31 downto 2) = "000000000000000000001000010100")) else '0';

  -- registradores dos HEXes (cada um grava se seu hexN_we = '1')
  hex0_reg : entity work.genericRegister
    generic map ( data_width => 8 )
    port map (
      clock => CLK,
      clear => '0',
      enable => hex0_we,
      source => data_rs2(7 downto 0),
      destination => hex0_in
    );

  hex1_reg : entity work.genericRegister
    generic map ( data_width => 8 )
    port map (
      clock => CLK,
      clear => '0',
      enable => hex1_we,
      source => data_rs2(7 downto 0),
      destination => hex1_in
    );

  hex2_reg : entity work.genericRegister
    generic map ( data_width => 8 )
    port map (
      clock => CLK,
      clear => '0',
      enable => hex2_we,
      source => data_rs2(7 downto 0),
      destination => hex2_in
    );

  hex3_reg : entity work.genericRegister
    generic map ( data_width => 8 )
    port map (
      clock => CLK,
      clear => '0',
      enable => hex3_we,
      source => data_rs2(7 downto 0),
      destination => hex3_in
    );

  hex4_reg : entity work.genericRegister
    generic map ( data_width => 8 )
    port map (
      clock => CLK,
      clear => '0',
      enable => hex4_we,
      source => data_rs2(7 downto 0),
      destination => hex4_in
    );

  hex5_reg : entity work.genericRegister
    generic map ( data_width => 8 )
    port map (
      clock => CLK,
      clear => '0',
      enable => hex5_we,
      source => data_rs2(7 downto 0),
      destination => hex5_in
    );

  -- decodificadores 7-seg
  DecoderDisplay0 : entity work.conversorHex7Seg
    port map ( dadoHex => "0000" & PC_out(3 downto 0), saida7seg => HEX0 ); -- PC
	 
	DecoderDisplay1 : entity work.conversorHex7Seg
    port map ( dadoHex => "0000" & ALU_out_CPU(3 downto 0), saida7seg => HEX1 ); -- DADO QUE ESTOU ESCREVENDO

  DecoderDisplay2 : entity work.conversorHex7Seg 
    port map ( dadoHex => "0000" & ALU_out_CPU(7 downto 4), saida7seg => HEX2 );

  DecoderDisplay3 : entity work.conversorHex7Seg
    port map ( dadoHex => "0000" & ALU_out_CPU(11 downto 8), saida7seg => HEX3 );

  DecoderDisplay4 : entity work.conversorHex7Seg
    port map ( dadoHex => "0000" & ALU_out_CPU(15 downto 12), saida7seg => HEX4 );

  DecoderDisplay5 : entity work.conversorHex7Seg
    port map ( dadoHex => hex0_in, saida7seg => HEX5 );
	 
	 LEDR(0) <= weRAM_CPU;
	 LEDR(1) <= enable_io;
	 LEDR(2) <= hex0_we;
	 LEDR(9) <= '1';

end architecture;
