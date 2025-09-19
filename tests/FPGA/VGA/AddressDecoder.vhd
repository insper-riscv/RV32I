library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AddressDecoder is
  port (
	signal_in : in std_logic_vector(31 downto 0);
	
	enable_posCol : out std_logic;
	enable_posLin : out std_logic;
	enable_dadoIN : out std_logic;
	
	enable_ram : out std_logic;
	
	enable_keys : out std_logic;
	
	signal_out : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behaviour of AddressDecoder is

begin

process(signal_in)
begin

	if (signal_in = "00000000000000000010000000000000") then -- signal_in(13) = 1
		enable_posCol  <= '1';
		enable_posLin  <= '0';
		enable_dadoIN  <= '0';
		enable_keys <= '0';
		enable_ram  <= '0';
	
	elsif (signal_in = "00000000000000000010000000000001") then
		enable_posCol  <= '0';
		enable_posLin  <= '1';
		enable_dadoIN  <= '0';
		enable_keys <= '0';
		enable_ram  <= '0';
	
	elsif (signal_in = "00000000000000000010000000000010") then
		enable_posCol  <= '0';
		enable_posLin  <= '0';
		enable_dadoIN  <= '1';
		enable_keys <= '0';
		enable_ram  <= '0';
	
	elsif (signal_in = "00000000000000000100000000000000") then -- signal_in(14) = 1
		enable_posCol  <= '0';
		enable_posLin  <= '0';
		enable_dadoIN  <= '0';
		enable_keys <= '1';
		enable_ram  <= '0';
		
	else
		enable_posCol  <= '0';
		enable_posLin  <= '0';
		enable_dadoIN  <= '0';
		enable_keys <= '0';
		enable_ram  <= '1';
    
  end if;

end process;

signal_out <= signal_in;

end architecture;
