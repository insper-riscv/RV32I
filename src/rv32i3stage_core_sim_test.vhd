library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_consts.all;

entity rv32i3stage_core_sim_test is
	generic (
	  SIMULATION : boolean := FALSE; 
	  ROM_FILE : string := "default.hex" 
  	);
	port (
    	CLK  : in  std_logic;
		reset : in std_logic := '0'   
  	);
end entity;

architecture behaviour of rv32i3stage_core_sim_test is

-- sinais aqui
signal CLK_IF, CLK_IDEXMEM : std_logic;

signal rom_addr : std_logic_vector(31 downto 0);
signal rom_rden : std_logic;
signal rom_data : std_logic_vector(31 downto 0);

signal ram_addr : std_logic_vector(31 downto 0);
signal ram_wdata : std_logic_vector(31 downto 0);
signal ram_rdata : std_logic_vector(31 downto 0);
signal ram_en : std_logic;
signal ram_wren : std_logic;
signal ram_rden : std_logic;
signal ram_byteena : std_logic_vector(3 downto 0);

begin

	CORE : entity work.rv32i3stage_core	
		port map (
			-- clock e reset
			clk  		=> CLK,
			clk_if_signal  	=> CLK_IF,
			clk_idexmem_signal	=> CLK_IDEXMEM,
			reset 		=> reset,

			----------------------------------------------------------------------
			-- Interface com a ROM (somente leitura)
			----------------------------------------------------------------------
			rom_addr => rom_addr,	-- endereço de instrução
			rom_rden => rom_rden,	-- enable de leitura
			rom_data => rom_data,	-- dados lidos da ROM

			----------------------------------------------------------------------
			-- Interface com a RAM (leitura e escrita)
			----------------------------------------------------------------------
			ram_addr    => ram_addr, 	-- endereço de palavra
			ram_wdata   => ram_wdata, 	-- dados a escrever (saida do store manager)
			ram_rdata   => ram_rdata, 	-- dados lidos
			ram_en      => ram_en, 		-- enable ram	
			ram_wren    => ram_wren,    -- write enable
			ram_rden    => ram_rden,    -- read enable
			ram_byteena => ram_byteena 	-- máscara de bytes
	);

	ROM : entity work.ROM_simulation
		generic map (ROM_FILE => ROM_FILE)  
		port map (
			addr 	=> rom_addr(31 downto 2),--word addressable
			clk 	=> CLK_IF,
			re 		=> rom_rden,
			data	=> rom_data
	);

	RAM : entity work.RAM_simulation
		port map(
			addr 		=> ram_addr(31 downto 2), -- word addressable
			mask 		=> ram_byteena,
			clk		 	=> CLK_IDEXMEM,
			data_in 	=> ram_wdata,
			reRAM 		=> ram_rden and ram_en,
			weRAM 		=> ram_wren and ram_en,
			eRAM 		=> ram_en,
			data_out 	=> ram_rdata
	);

end architecture;