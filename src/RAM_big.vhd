library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM_big is
  generic (
    dataWidth: natural := 32;
    addrWidth: natural := 30;
    memoryAddrWidth: natural := 14 -- 16384 palavras de 32 bits -- 16384 * 4 bytes = 65536 bytes = 64 KiB
  );
  port (
    clk      : in  std_logic;
    addr     : in  std_logic_vector(addrWidth-1 downto 0);  -- ALU_out(31 downto 2)
    data_in  : in  std_logic_vector(dataWidth-1 downto 0);
    data_out : out std_logic_vector(dataWidth-1 downto 0);
    weRAM    : in  std_logic;                     -- habilita escrita
    reRAM    : in  std_logic;                     -- habilita leitura
    eRAM     : in  std_logic;                     -- chip enable (RAM ativa)
    mask     : in  std_logic_vector(3 downto 0)   -- byte enables
  );
end entity;

architecture rtl of RAM_big is
  type mem_t is array(0 to 2**memoryAddrWidth - 1) of std_logic_vector(31 downto 0);
  signal mem : mem_t := (others => (others => '0'));

  -- índice em palavras (addr é o endereço >>2 vindo da ALU)
  signal widx : std_logic_vector(memoryAddrWidth-1 downto 0);
begin
  -- pega os 14 LSBs desse endereço em palavras
  -- isso cobre offset byte até 0x0000_FFFC dentro do bloco de 64 KiB
  widx <= addr(memoryAddrWidth-1 downto 0);  -- addr(13 downto 0)

  process(clk)
  begin
    if rising_edge(clk) then
      if (weRAM = '1' and eRAM = '1') then
        -- escrita seletiva por byte
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

  data_out <= mem(to_integer(unsigned(widx))) when (reRAM = '1' and eRAM = '1')
              else (others => '0');

end architecture;