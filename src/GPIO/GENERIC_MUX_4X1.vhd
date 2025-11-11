library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity GENERIC_MUX_4X1 is
    generic (
        DATA_WIDTH : natural := 8
    );
    port (
        selector    : in  std_logic_vector(1 downto 0);
        source_1    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        source_2    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        source_3    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        source_4    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        destination : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture RTL of GENERIC_MUX_4X1 is
begin
    with selector select
        destination <= source_1 when "00",
                       source_2 when "01",
                       source_3 when "10",
                       source_4 when others;
end architecture;
