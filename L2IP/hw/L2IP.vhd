library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity L2IP is
  port   (
    CLOCK_50 : in std_logic;
	HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0) := (others => '0');
	LEDR : out std_logic_vector(9 downto 0) := (others => '0');
	SW : in std_logic_vector(9 downto 0);
	FPGA_RESET_N : in std_logic
  );
end entity;

architecture behaviour of L2IP is
	-- sinais aqui

	-- ======= cpu <-> memorias =======
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

	-- ======= perifericos =======

	signal CLK, CLKbtn : std_logic;
	signal enable_led : std_logic;

begin

	edgeDetectorKey : entity work.edgeDetector	
		port map (
			clk    => CLOCK_50 and (not SW(0)), -- SW0 PRA CIMA PARA O CLOCK E RESETA A CPU (ENTRA EM MODO DE BOOT)
			entrada=> not FPGA_RESET_N,
			saida  => CLKbtn
	);

	CLK <= CLOCK_50 when SW(1) else CLKbtn; -- SW1 ESCOLHE ENTRE O CLOCK DA PLACA OU USAR O CLOCK NO DEDO COM O BOTAO FPGA_RESET

	CORE : entity work.rv32i3stage_core	
		port map (
			-- clock e reset
			clk  		=> CLK,
			clk_if_signal  	=> CLK_IF,
			clk_idexmem_signal	=> CLK_IDEXMEM,
			reset 		=> SW(0),

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
	
	ROM : entity work.rom1port
		port map (
			address => rom_addr(14 downto 2),
			clock => CLK_IF,
			rden =>  rom_rden,
			q => rom_data
	);
	
	RAM : entity work.ram1port
		port map(
			address => ram_addr(13 downto 2), -- word addressable (alu out ´e byte, entao ignora os dois bits menos significativos)
			byteena => ram_byteena,
			clock => CLK_IDEXMEM,
			data => ram_wdata,
			rden => ram_rden and (ram_en and not(ram_addr(14))),
			wren => ram_wren and (ram_en and not(ram_addr(14))),
			q => ram_rdata
	);
	
	enable_led <= '1'
		when (ram_en = '1' and ram_wren = '1' and unsigned(ram_addr(31 downto 2)) = to_unsigned(4096, 30))
		else '0'
	;
	  
	leds : entity work.genericRegister
		generic map ( data_width => 8 )
		port map (
			clock => CLK,
			clear => SW(0),
			enable => enable_led,
			source => ram_wdata(7 downto 0),
			destination => LEDR(7 downto 0)
	);
					  
	example_blinky : entity work.Blinky
		port map (
			clk => CLOCK_50,      
			led => LEDR(9)    
	);

end architecture;