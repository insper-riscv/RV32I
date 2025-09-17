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
    0  => x"00000000", -- addi ra, x0, 5
    1  => x"00000001", -- addi sp, x0, 7
    2  => x"00000002", -- add  gp, ra, sp
    3  => x"00000003", -- sub  tp, sp, ra
    4  => x"00000004", -- and  t0, ra, sp
    5  => x"00000005", -- or   t1, ra, sp
    6  => x"00000006", -- xor  t2, ra, sp
    7  => x"00000007", -- sll  s0, ra, sp
    8  => x"00000008", -- srl  s1, s0, sp
    9  => x"00000009", -- slt  a0, ra, sp
    10 => x"0000000A", -- addi a1, a1, 1
    11 => x"0000000B", -- jal x0, loop
    12 to 63 => x"00000000"  -- restante zerado
);

  -- (Para Quartus) mantenha o atributo; GHDL ignora.
  signal memROM : blocoMemoria := ROMDATA;
  -- attribute ram_init_file : string;
  -- attribute ram_init_file of memROM : signal is "initROM.mif";

  signal localAddress : std_logic_vector(memoryAddrWidth-1 downto 0);
begin
  localAddress <= addr(memoryAddrWidth+1 downto 2);
  data <= memROM(to_integer(unsigned(localAddress)));
end architecture;