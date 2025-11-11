-- =============================================================================
-- Entity: GENERIC_MUX_8X1
-- Description:
--   Multiplexador 8 para 1 genérico. Cada entrada é um vetor de largura configurável.
--   Seleciona uma das oito fontes com base em um seletor de 3 bits.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library WORK;

entity GENERIC_MUX_8X1 is
    generic (
        --! Largura dos vetores de dados
        DATA_WIDTH : natural := 8
    );
    port (
        --! Seletor de 3 bits (valor de 0 a 7)
        selector     : in  std_logic_vector(2 downto 0) := (others => '0');
        --! Fontes de dados
        source_1     : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_2     : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_3     : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_4     : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_5     : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_6     : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_7     : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        source_8     : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        --! Saída multiplexada
        destination  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture RTL of GENERIC_MUX_8X1 is

    signal s0 : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal s1 : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal s2 : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    -- Replicação dos bits do seletor
    s0 <= (others => selector(0));
    s1 <= (others => selector(1));
    s2 <= (others => selector(2));

    -- Lógica combinacional vetorial para seleção da fonte
    destination <=
        (source_1 AND (NOT s2 AND NOT s1 AND NOT s0)) OR
        (source_2 AND (NOT s2 AND NOT s1 AND     s0)) OR
        (source_3 AND (NOT s2 AND     s1 AND NOT s0)) OR
        (source_4 AND (NOT s2 AND     s1 AND     s0)) OR
        (source_5 AND (    s2 AND NOT s1 AND NOT s0)) OR
        (source_6 AND (    s2 AND NOT s1 AND     s0)) OR
        (source_7 AND (    s2 AND     s1 AND NOT s0)) OR
        (source_8 AND (    s2 AND     s1 AND     s0));

end architecture;
