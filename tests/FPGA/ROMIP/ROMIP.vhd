library ieee;
use ieee.std_logic_1164.all;

entity ROMIP is
  port   (
    CLOCK_50 : in std_logic;
	 HEX0, HEX1, HEX2, HEX3,HEX4, HEX5 : out std_logic_vector(6 downto 0);
    SW: in std_logic_vector(9 downto 0);
	 FPGA_RESET_N : in std_logic
  );
end entity;


architecture arquitetura of ROMIP is

  
  signal dadoROM, endROM : std_logic_vector(31 downto 0);
  signal CLK : std_logic;

  
begin

edgeDetectorKey : entity work.edgeDetector
			port map (clk => CLOCK_50, entrada => NOT(FPGA_RESET_N), saida => CLK);

ROM0 : entity work.room
		port map(
		  address => SW(8 downto 0),
		  clock => CLK,
		  q     => dadoROM
	   );			

DecoderDisplay0 :  entity work.conversorHex7Seg
        port map(dadoHex => SW(3 downto 0),
                 saida7seg => HEX0);

DecoderDisplay1 :  entity work.conversorHex7Seg
		  port map(dadoHex => SW(7 downto 4),
					  saida7seg => HEX1);
					  
DecoderDisplay2 :  entity work.conversorHex7Seg
		  port map(dadoHex => dadoROM(3 downto 0),
					  saida7seg => HEX2);
					  
DecoderDisplay3 :  entity work.conversorHex7Seg
		  port map(dadoHex => dadoROM(7 downto 4),
					  saida7seg => HEX3);
			
DecoderDisplay4 :  entity work.conversorHex7Seg
		  port map(dadoHex => dadoROM(11 downto 8),
					  saida7seg => HEX4);
					  
DecoderDisplay5 :  entity work.conversorHex7Seg
		  port map(dadoHex => dadoROM(15 downto 12),
					  saida7seg => HEX5);
					  

	  
end architecture;