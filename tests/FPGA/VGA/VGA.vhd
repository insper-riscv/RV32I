library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA is
  port (
    CLOCK_50 : in  std_logic;
	 FPGA_RESET_N : in std_logic;
    KEY      : in  std_logic_vector(3 downto 0);
	 
	 HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);

    -- pinos VGA (já mapeados no .qsf)
    VGA_HS   : out std_logic;
    VGA_VS   : out std_logic;
    VGA_R    : out std_logic_vector(3 downto 0);
    VGA_G    : out std_logic_vector(3 downto 0);
    VGA_B    : out std_logic_vector(3 downto 0)
	 
  );
end entity;

architecture behaviour of VGA is

signal CLK : std_logic;
signal RAM_out : std_logic_vector(31 downto 0);
signal ALU_out_CPU : std_logic_vector (31 downto 0);
signal out_StoreManager_CPU : std_logic_vector(31 downto 0);
signal mask_ram_CPU : std_logic_vector(3 downto 0);
signal weRAM_CPU : std_logic;
signal reRAM_CPU : std_logic;
signal eRAM_CPU : std_logic;

signal enable_posCol : std_logic;
signal enable_posLin : std_logic;
signal enable_dadoIN : std_logic;
signal enable_keys : std_logic;
signal enable_ram : std_logic;

signal out_addr_decoder : std_logic_vector(31 downto 0);
signal posCol_reg_out : std_logic_vector(7 downto 0);
signal posLin_reg_out : std_logic_vector(7 downto 0);
signal dadoIN_reg_out : std_logic_vector(7 downto 0);
signal VideoRAMWREnable_out : std_logic;


signal wr_data_byte : std_logic_vector(7 downto 0);
signal wr_posCol    : std_logic;
signal wr_posLin    : std_logic;
signal wr_dadoIN    : std_logic;

signal data_rs2 : std_logic_vector(31 downto 0);

begin

	-- edgeDetectorKey : entity work.edgeDetector
		-- port map (clk => CLOCK_50, entrada => NOT(FPGA_RESET_N), saida => CLK);
	
	CLK <= CLOCK_50;
		
		
		
	CPU : entity work.rv32i
		port map (
			CLK => CLK,
			ExtenderRAM_in => RAM_out,
			ALU_out_cpu => ALU_out_CPU,
			out_StoreManager_cpu => out_StoreManager_CPU,
			mask_ram_cpu => mask_ram_CPU,
			weRAM_cpu => weRAM_CPU,
			reRAM_cpu => reRAM_CPU,
			eRAM_cpu => eRAM_CPU,
			rs2 => data_rs2
		);
	
	RAM : entity work.RAM
		port map (
			clk      => CLK,
			addr     => ALU_out_CPU,
			data_in  => out_StoreManager_cpu,
			data_out => RAM_out,
			weRAM    => weRAM_CPU,   
			reRAM    => reRAM_CPU,   
			eRAM     => eRAM_CPU and enable_ram,
			mask     => mask_ram_CPU
		);
		
	Addr_decoder : entity work.AddressDecoder
		port map(
			signal_in => ALU_out_CPU,
			enable_posCol => enable_posCol,
			enable_posLin => enable_posLin,
			enable_dadoIN => enable_dadoIN,
			enable_keys => enable_keys,
			enable_ram => enable_ram,
			signal_out => out_addr_decoder
		);
	
	dVGA : entity work.driverVGA
		port map (
			CLOCK_50         =>  CLK, 
			VGA_HS           =>  VGA_HS,
			VGA_VS           =>  VGA_VS,
			VGA_R            =>  VGA_R, 
			VGA_G            =>  VGA_G, 
			VGA_B            =>  VGA_B,
			posCol           =>  posCol_reg_out, 
			posLin           =>  posLin_reg_out,
			dadoIN           =>  dadoIN_reg_out, 
			VideoRAMWREnable => '1'
		 );
	posCol_reg : entity work.genericRegister
			generic map ( data_width => 8 )
			port map (
				clock => CLK,
				clear => '0',
				enable => '1',
				source => data_rs2(7 downto 0),
				
				destination => posCol_reg_out
			);
	posLin_reg : entity work.genericRegister
			generic map ( data_width => 8 )
			port map (
				clock => CLK,
				clear => '0',
				enable => '1',
				source => data_rs2(7 downto 0),
				
				destination => posLin_reg_out
			);
	dadoIN_reg : entity work.genericRegister
			generic map ( data_width => 8 )
			port map (
				clock => CLK,
				clear => '0',
				enable => '1',
				source => data_rs2(7 downto 0),
				
				destination => dadoIN_reg_out
			);
			
  
	 
	DecoderDisplay0 :  entity work.conversorHex7Seg
		port map(dadoHex => dadoIN_reg_out(3 downto 0),
                 saida7seg => HEX0);

   DecoderDisplay1 :  entity work.conversorHex7Seg
		port map(dadoHex => dadoIN_reg_out(7 downto 4),
					  saida7seg => HEX1);
				
   DecoderDisplay2 :  entity work.conversorHex7Seg
		port map(dadoHex => posLin_reg_out(3 downto 0),
					  saida7seg => HEX2);
					  
    DecoderDisplay3 :  entity work.conversorHex7Seg
		port map(dadoHex => posLin_reg_out(7 downto 4),
					  saida7seg => HEX3);
					  
    DecoderDisplay4 :  entity work.conversorHex7Seg
		port map(dadoHex => posCol_reg_out(3 downto 0),
					  saida7seg => HEX4);
					  
    DecoderDisplay5 :  entity work.conversorHex7Seg
		port map(dadoHex => posCol_reg_out(7 downto 4),
					  saida7seg => HEX5);

end architecture;
