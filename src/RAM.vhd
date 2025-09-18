library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
  generic (
    dataWidth: natural := 32;
    addrWidth: natural := 32;
    memoryAddrWidth: natural := 6   -- 64 posicoes de 32 bits cada
  );
  port (
    clk      : in  std_logic;
    addr     : in  std_logic_vector(addrWidth-1 downto 0);
    data_in  : in  std_logic_vector(dataWidth-1 downto 0);
    data_out : out std_logic_vector(dataWidth-1 downto 0);
    weRAM    : in  std_logic;                     -- habilita escrita
    reRAM    : in  std_logic;                     -- habilita leitura
    eRAM     : in  std_logic;                     -- chip enable (RAM ativa)
    mask     : in  std_logic_vector(3 downto 0)   -- byte enables
  );
end entity;

architecture rtl of RAM is
  type mem_t is array(0 to 2**memoryAddrWidth - 1) of std_logic_vector(31 downto 0);
  signal mem : mem_t := (others => (others => '0'));

  -- word index (32-bit aligned)
  signal widx : std_logic_vector(memoryAddrWidth-1 downto 0);
begin
  widx <= addr(memoryAddrWidth+1 downto 2);

  process(clk)
  begin
    if rising_edge(clk) then
      if (weRAM = '1' and eRAM = '1') then
        -- update selected bytes inside the 32-bit word
        if mask(0) = '1' then
          mem(to_integer(unsigned(widx)))(7 downto 0)   <= data_in(7 downto 0);
        end if;
        if mask(1) = '1' then
          mem(to_integer(unsigned(widx)))(15 downto 8)  <= data_in(15 downto 8);
        end if;
        if mask(2) = '1' then
          mem(to_integer(unsigned(widx)))(23 downto 16) <= data_in(23 downto 16);
        end if;
        if mask(3) = '1' then
          mem(to_integer(unsigned(widx)))(31 downto 24) <= data_in(31 downto 24);
        end if;
      end if;
    end if;
  end process;

  -- leitura assíncrona, só ativa se reRAM=1 e eRAM=1
  data_out <= mem(to_integer(unsigned(widx))) when (reRAM = '1' and eRAM = '1')
              else (others => '0');

end architecture;
