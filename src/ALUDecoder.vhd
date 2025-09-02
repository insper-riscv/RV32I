library ieee;
use ieee.std_logic_1164.all;

entity unidadeControle is
  port ( opcode : in std_logic_vector(6 downto 0);
			saida : out std_logic_vector(11 downto 0)
  );
end entity;

architecture comportamento of ALUDecoder is