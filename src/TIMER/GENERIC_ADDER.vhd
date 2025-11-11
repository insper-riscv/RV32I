library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;

--! Realiza operação aritmética de soma entre dois inteiros codificados em vetores booleanos.
entity GENERIC_ADDER is

    generic (
        --! Largura dos vetores de dados
        DATA_WIDTH       : natural := 8;
        --! Dispensa necessidade de atribuir entrada `source_2`
        DEFAULT_SOURCE_2 : integer := 1
    );

    port (
        --! Vetor de dados primário
        source_1    : in  std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0');
        --! Vetor de dados secundário
        source_2    : in  std_logic_vector((DATA_WIDTH - 1) downto 0) := std_logic_vector(to_signed(DEFAULT_SOURCE_2, DATA_WIDTH));
        --! Resultado da soma dos vetores de dados
        destination : out std_logic_vector((DATA_WIDTH - 1) downto 0)
    );

end entity;

architecture RTL of GENERIC_ADDER is

    signal source_and      : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal half_add        : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal carry_out       : std_logic_vector((DATA_WIDTH - 2) downto 0);

begin

    source_and  <= source_1 AND source_2;
    half_add    <= source_1 XOR source_2;
    destination <= half_add XOR carry_out & '0';

    CARRY_LOOKAHEAD : entity WORK.GENERIC_CARRY_LOOKAHEAD
        generic map (
            DATA_WIDTH => DATA_WIDTH - 1
        )
        port map(
            carry_in        => '0',
            carry_generate  => source_and((DATA_WIDTH - 2) downto 0),
            carry_propagate => half_add((DATA_WIDTH - 2) downto 0),
            carry_out       => carry_out
        );

end architecture;