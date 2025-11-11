library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library WORK;

--! Auxilia a implementação do [CLA](https://en.wikipedia.org/wiki/Carry-lookahead_adder) para ganhos de
--! performance em circuitos somadores como o Somador Genérico e a Unidade de Lógica Aritmética.
entity GENERIC_CARRY_LOOKAHEAD is

    generic(
        --! Largura dos vetores de dados
        DATA_WIDTH : natural := 8
    );

    port (
        --! Carry de entrada da soma
        carry_in        : in  std_logic                                   := '0';
        --! Carry de geração do CLA
        carry_generate  : in  std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0');
        --! Carry de propagação do CLA
        carry_propagate : in  std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0');
        --! Carry de saída da soma
        carry_out       : out std_logic_vector((DATA_WIDTH - 1) downto 0)
    );

end entity;

architecture RTL of GENERIC_CARRY_LOOKAHEAD is

    signal carry : std_logic_vector(DATA_WIDTH downto 0);

begin

    carry(0)  <= carry_in;
    carry_out <= carry(DATA_WIDTH downto 1);

    BIT_TO_BIT : for i in 0 to (DATA_WIDTH - 1) generate
        carry(i + 1) <= (carry(i) AND carry_propagate(i)) OR carry_generate(i);
    end generate;

end architecture;