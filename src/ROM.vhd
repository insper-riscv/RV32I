library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM IS
   generic (
          dataWidth: natural := 32;
          addrWidth: natural := 32;
          memoryAddrWidth:  natural := 8 );   
   port (
          addr : in  std_logic_vector (addrWidth-1 downto 0);
          data : out std_logic_vector (dataWidth-1 downto 0) );
end entity;

architecture rtl OF ROM IS
  type blocoMemoria IS ARRAY(0 TO 2**memoryAddrWidth - 1) 
  OF std_logic_vector(dataWidth-1 downto 0);
  
constant ROMDATA : blocoMemoria := (
  0   => x"20000293",
  1   => x"00028E33",
  2   => x"00900313",
  3   => x"00030E33",
  4   => x"0062A023",
  5   => x"FF5FF06F",
  6 to 255 => x"00000000"  -- restante zerado
);

  signal memROM : blocoMemoria := ROMDATA;

  signal localAddress : std_logic_vector(memoryAddrWidth-1 downto 0);
begin
  localAddress <= addr(memoryAddrWidth+1 downto 2);
  data <= memROM(to_integer(unsigned(localAddress)));
end architecture;




