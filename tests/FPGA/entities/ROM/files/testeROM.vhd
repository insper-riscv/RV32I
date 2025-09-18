library ieee;
use ieee.std_logic_1164.all;

entity testeROM is
  port   (
	 HEX0, HEX1, HEX2, HEX3,HEX4, HEX5 : out std_logic_vector(6 downto 0);
    SW: in std_logic_vector(9 downto 0)
  );
end entity;


architecture arquitetura of testeROM is

  
  signal dadoROM, endROM : std_logic_vector(31 downto 0);

  
begin

endROM <= "0000000000000000000000" & SW(9 downto 0);

ROM0 : entity work.ROM generic map (dataWidth => 32, addrWidth => 32)
		port map(
		  Endereco => endROM,
		  Dado     => dadoROM
	   );			

DecoderDisplay0 :  entity work.conversorHex7Seg
        port map(dadoHex => endROM(3 downto 0),
                 saida7seg => HEX0);

DecoderDisplay1 :  entity work.conversorHex7Seg
		  port map(dadoHex => endROM(7 downto 4),
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