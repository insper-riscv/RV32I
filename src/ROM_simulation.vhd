library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity ROM_simulation is
  generic (
    dataWidth: natural := 32;
    addrWidth: natural := 32;
    memoryAddrWidth: natural := 9;
    ROM_FILE: string := "initROM.hex"   -- novo generic
  );
  port (
    addr : in  std_logic_vector (addrWidth-1 downto 0);
    data : out std_logic_vector (dataWidth-1 downto 0)
  );
end entity;

architecture rtl of ROM_simulation is
  type blocoMemoria is array(0 to 2**memoryAddrWidth - 1)
    of std_logic_vector(dataWidth-1 downto 0);

  signal memROM : blocoMemoria := (others => (others => '0'));
  signal localAddress : std_logic_vector(memoryAddrWidth-1 downto 0);
begin

  -- inicializa a ROM lendo de um arquivo texto com 1 palavra (32 bits) por linha, em hex
  init: process
    file f : text open read_mode is ROM_FILE;
    variable l : line;
    variable v : std_logic_vector(dataWidth-1 downto 0);
    variable idx : integer := 0;
  begin
    while not endfile(f) loop
      readline(f, l);
      hread(l, v);
      if idx <= memROM'high then
        memROM(idx) <= v;
      end if;
      idx := idx + 1;
    end loop;
    wait;  -- processo só roda uma vez
  end process;

  -- WORD-addressable: 'addr' é interpretado como índice de palavra,
  -- portanto usamos os bits menos-significativos necessários para indexar memROM.
  localAddress <= addr(memoryAddrWidth-1 downto 0);
  data <= memROM(to_integer(unsigned(localAddress)));

end architecture;
