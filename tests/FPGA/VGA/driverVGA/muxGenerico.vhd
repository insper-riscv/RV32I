LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity muxGenerico is

	generic (
	inputSize : natural := 16;
	selSize   : natural := 4;
	invertido : boolean := TRUE
	);
	port (
	input    : in  std_logic_vector(inputSize-1 downto 0);
	sel      : in  std_logic_vector(selSize-1 downto 0);
	output   : out std_logic
	);
	
end entity;



architecture Behavioral of muxGenerico is

begin

tipo:	if invertido generate
		output <= input((inputSize-1) - to_integer(unsigned(sel)));
		else generate
		output <= input(to_integer(unsigned(sel)));
		end generate;
		
end architecture;