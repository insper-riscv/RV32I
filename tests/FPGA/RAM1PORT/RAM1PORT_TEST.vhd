library ieee;
use ieee.std_logic_1164.all;

entity RAM1PORT_TEST is
  port   (
    CLOCK_50 : in std_logic;
	 HEX0, HEX1, HEX2, HEX3,HEX4, HEX5 : out std_logic_vector(6 downto 0);
    SW: in std_logic_vector(9 downto 0);
	 KEY: in std_logic_vector(3 downto 0);
	 LEDR: out std_logic_vector(9 downto 0);
	 FPGA_RESET_N : in std_logic
  );
end entity;


architecture arquitetura of RAM1PORT_TEST is

  signal data : std_logic_vector(2 downto 0);
  signal byteena : std_logic_vector(3 downto 0);
  signal address : std_logic_vector(2 downto 0);
  signal rden, wren : std_logic;
  signal q : std_logic_vector(31 downto 0);
  signal CLK : std_logic;

  
begin

edgeDetectorKey : entity work.edgeDetector
			port map (clk => CLOCK_50, entrada => NOT(FPGA_RESET_N), saida => CLK);


data <= SW(2 downto 0);	

byteena <= SW(6 downto 3);	
LEDR(6 downto 3) <= byteena;

address <= SW(9 downto 7);	

rden <= not(KEY(0));
LEDR(0) <= rden;

wren <= not(KEY(1));		
LEDR(1) <= wren;

RAM : entity work.ram1port
		port map(
		  clock => CLK,
		  data => "00000000000000000000000000000" & data,
		  byteena => byteena,
		  address => "00000000000" & address,
		  rden => rden,
		  wren => wren,
		  q    => q
	   );			
		
-- MOSTRA DATA IN SW(2 downto 0)
DecoderDisplay0 :  entity work.conversorHex7Seg
        port map(dadoHex => "0" & data,
                 saida7seg => HEX0);

--DecoderDisplay1 :  entity work.conversorHex7Seg
--		  port map(dadoHex => dadoA(7 downto 4),
--					  saida7seg => HEX1);
				
-- MOSTRA Q		
DecoderDisplay2 :  entity work.conversorHex7Seg
		  port map(dadoHex => q(3 downto 0),
					  saida7seg => HEX2);
					  
DecoderDisplay3 :  entity work.conversorHex7Seg
		  port map(dadoHex => q(7 downto 4),
					  saida7seg => HEX3);
			
DecoderDisplay4 :  entity work.conversorHex7Seg
		  port map(dadoHex => q(11 downto 8),
					  saida7seg => HEX4);
					 
-- MOSTRA ADDRS SW(2 downto 0)
DecoderDisplay5 :  entity work.conversorHex7Seg
		  port map(dadoHex => "0" & address,
					  saida7seg => HEX5);
					  
	  
end architecture;