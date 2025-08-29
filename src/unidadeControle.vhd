library ieee;
use ieee.std_logic_1164.all;

entity unidadeControle is
  port ( opcode : in std_logic_vector(5 downto 0);
			saida : out std_logic_vector(11 downto 0)
  );
end entity;

architecture comportamento of unidadeControle is
  
  constant LUI : std_logic_vector(6 downto 0) := "0110111";
  constant AUIPC : std_logic_vector(6 downto 0) := "0010111";
  constant JAL : std_logic_vector(6 downto 0) := "1101111";
  constant JALR : std_logic_vector(6 downto 0) := "1100111";
  constant B_type : std_logic_vector(6 downto 0) := "1100011";
  constant L_type : std_logic_vector(6 downto 0) := "0000011";
  constant SB_SH_SW : std_logic_vector(6 downto 0) := "0100011";
  constant I_type : std_logic_vector(6 downto 0) := "0010011";
  constant R_type : std_logic_vector(6 downto 0) := "0110011";
  constant ECALL_EBREAK : std_logic_vector(6 downto 0) := "0110111";

begin
saida <= "000110100000" when (opcode = R) else
			"000111100000" when (opcode = (addi OR andi OR ori OR slti)) else
			"100000000000" when (opcode = BNE) else
         "000000000000";  -- NOP para os opcodes Indefinidos

end architecture;