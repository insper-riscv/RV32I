library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity GENERIC_MUX_8X1 is
    generic (
        DATA_WIDTH : natural := 8
    );
    port (
        selector    : in  std_logic_vector(2 downto 0) := (others => '0');
        source_1    : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_2    : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_3    : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_4    : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_5    : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_6    : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_7    : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_8    : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        destination : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture RTL of GENERIC_MUX_8X1 is
begin
    with selector select
        destination <= source_1 when "000",
                       source_2 when "001",
                       source_3 when "010",
                       source_4 when "011",
                       source_5 when "100",
                       source_6 when "101",
                       source_7 when "110",
                       source_8 when others;
end architecture;
