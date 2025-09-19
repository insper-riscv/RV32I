library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM IS
   generic (
          dataWidth: natural := 32;
          addrWidth: natural := 32;
          memoryAddrWidth:  natural := 6 );   
   port (
          addr : in  std_logic_vector (addrWidth-1 downto 0);
          data : out std_logic_vector (dataWidth-1 downto 0) );
end entity;

architecture rtl OF ROM IS
  type blocoMemoria IS ARRAY(0 TO 2**memoryAddrWidth - 1) OF std_logic_vector(dataWidth-1 downto 0);
  
constant ROMDATA : blocoMemoria := (
  0  => x"00000093",  -- addi x1, x0, 0
  1  => x"AABBD137",  -- lui  x2, 0xAABBD
  2  => x"CDD10113",  -- addi x2, x2, -803  (0xAABBCCDD)

  -- Stores
  3  => x"0020A023",  -- sw  x2, 0(x1)
  4  => x"00209223",  -- sh  x2, 4(x1)
  5  => x"00208323",  -- sb  x2, 6(x1)

  -- Loads + exposição em t3
  6  => x"0000A183",  -- lw  x3, 0(x1)
  7  => x"00018E33",  -- add t3, x3, x0

  8  => x"00409203",  -- lh  x4, 4(x1)
  9  => x"00020E33",  -- add t3, x4, x0

  10 => x"0040D283",  -- lhu x5, 4(x1)
  11 => x"00028E33",  -- add t3, x5, x0

  12 => x"00608303",  -- lb  x6, 6(x1)
  13 => x"00030E33",  -- add t3, x6, x0

  14 => x"0060C383",  -- lbu x7, 6(x1)
  15 => x"00038E33",  -- add t3, x7, x0

  -- Loop infinito
  16 => x"0000006F",  -- j 0

  17 to 63 => x"00000000"  -- restante zerado
);




  signal memROM : blocoMemoria := ROMDATA;

  signal localAddress : std_logic_vector(memoryAddrWidth-1 downto 0);
begin
  localAddress <= addr(memoryAddrWidth+1 downto 2);
  data <= memROM(to_integer(unsigned(localAddress)));
end architecture;