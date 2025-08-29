library ieee;
use ieee.std_logic_1164.all;

entity unidadeControle is
  port ( opcode : in std_logic_vector(6 downto 0);
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
  constant S_type : std_logic_vector(6 downto 0) := "0100011";
  constant I_type : std_logic_vector(6 downto 0) := "0010011";
  constant R_type : std_logic_vector(6 downto 0) := "0110011";
  constant ECALL_EBREAK : std_logic_vector(6 downto 0) := "1110011";

begin
saida <= "100000111100" when (opcode = LUI) else
			"100000100001" when (opcode = AUIPC) else
			"100001000010" when (opcode = JAL) else
			"100001100010" when (opcode = JALR) else
			"000010000100" when (opcode = B_type) else
			"111000100000" when (opcode = L_type) else
			"000100100000" when (opcode = S_type) else
			"100000101000" when (opcode = I_type) else
			"100000001000" when (opcode = R_type) else
         "000000000000";  -- NOP para os opcodes Indefinidos

end architecture;