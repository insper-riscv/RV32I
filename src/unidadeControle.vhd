library ieee;
use ieee.std_logic_1164.all;

entity unidadeControle is
  port ( opcode : in std_logic_vector(5 downto 0);
			saida : out std_logic_vector(11 downto 0)
  );
end entity;

architecture comportamento of unidadeControle is

  constant R  : std_logic_vector(5 downto 0) := "000000";
  constant LW : std_logic_vector(5 downto 0) := "100011";
  constant SW : std_logic_vector(5 downto 0) := "101011";
  constant BEQ : std_logic_vector(5 downto 0) := "000100";
  constant JMP : std_logic_vector(5 downto 0) := "000010";
  constant addi : std_logic_vector(5 downto 0) := "001000";
  constant andi : std_logic_vector(5 downto 0) := "001100";
  constant ori : std_logic_vector(5 downto 0) := "001101";
  constant slti : std_logic_vector(5 downto 0) := "001010";
  constant BNE : std_logic_vector(5 downto 0) := "000101";
  constant jal : std_logic_vector(5 downto 0) := "000011";

begin
saida <= "000110100000" when (opcode = R) else
			"000011001010" when (opcode = LW) else
			"000001000001" when (opcode = SW) else
			"000000000100" when (opcode = BEQ) else
			"010000000000" when (opcode = JMP) else
			"000111100000" when (opcode = (addi OR andi OR ori OR slti)) else
			"100000000000" when (opcode = BNE) else
			"011010010000" when (opcode = jal) else
         "000000000000";  -- NOP para os opcodes Indefinidos

end architecture;