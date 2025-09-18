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
  0  => x"008002EF",  -- jal   x5,8
  1  => x"00000013",  -- addi  x6,x7,0   (NOP real, mas com dependência)
  2  => x"00028333",  -- add   x6,x5,x0  (expõe link em x6)
  3  => x"000283E7",  -- jalr  x7,x5,0   (volta para endereço salvo)
  4  => x"00000013",  -- addi  x0,x0,0   (NOP após retorno)
  5  => x"0000006F",  -- j     0 (loop infinito)
  6 to 63 => x"00000000"  -- restante zerado
);

  signal memROM : blocoMemoria := ROMDATA;

  signal localAddress : std_logic_vector(memoryAddrWidth-1 downto 0);
begin
  localAddress <= addr(memoryAddrWidth+1 downto 2);
  data <= memROM(to_integer(unsigned(localAddress)));
end architecture;