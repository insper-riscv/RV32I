LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity calcMemAddr IS

	port(
		posLin, posCol :  IN std_logic_vector(8 DOWNTO 0);
		MemAddrVALUE :  OUT std_logic_vector(8 DOWNTO 0) 
	); 
	
end entity;



architecture arc OF calcMemAddr IS

	signal calcPosLin : std_logic_vector(8 DOWNTO 0);
	
signal contador : integer range 0 to 299 := 0;


begin
			
		CalcPosVIDEO_A :  entity work.somadorGenerico  generic map (larguraDados => 9)
		port map( entradaA =>  posLIN(4 downto 0) & "0000", entradaB =>  posLIN(6 downto 0) & "00", saida => calcPosLin);
		  
		CalcPosVIDEO_B :  entity work.somadorGenerico  generic map (larguraDados => 9)
		port map( entradaA => calcPosLin, entradaB =>  posCol, saida => MemAddrVALUE);
		
end architecture;
