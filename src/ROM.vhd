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
    0  => x"00000000",
    1  => x"00000001",
    2  => x"00000002",
    3  => x"00000003",
    4  => x"00000004",
    5  => x"00000005",
    6  => x"00000006",
    7  => x"00000007",
    8  => x"00000008",
    9  => x"00000009",
    10 => x"0000000A",
    11 => x"0000000B",
    12 => x"0000000C",
    13 => x"0000000D",
    14 => x"0000000E",
    15 => x"0000000F",
    16 => x"00000011",
    17 => x"00000012",
    18 => x"00000013",
    19 => x"00000014",
    20 => x"00000015",
    21 => x"00000016",
    22 to 63 => x"00000000"
  );

  -- (Para Quartus) mantenha o atributo; GHDL ignora.
  signal memROM : blocoMemoria := ROMDATA;
  attribute ram_init_file : string;
  attribute ram_init_file of memROM : signal is "initROM.mif";

  signal localAddress : std_logic_vector(memoryAddrWidth-1 downto 0);
begin
  localAddress <= addr(memoryAddrWidth+1 downto 2);
  data <= memROM(to_integer(unsigned(localAddress)));
end architecture;