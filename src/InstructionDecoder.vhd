library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity InstructionDecoder is
  port (
    opcode  : in  std_logic_vector(6 downto 0);
    funct3  : in  std_logic_vector(2 downto 0);
    funct7  : in  std_logic_vector(6 downto 0);
    ctrl    : out std_logic_vector(21 downto 0)
  );
end entity;

architecture behaviour of InstructionDecoder is

	-- add necessary signals here
	
begin


process(opcode, funct3, funct7)
begin

  if    (opcode = "0010011" and funct3 = "001" and funct7 = "0000000") then ctrl <= B"0_010_00_1_000_1_1_00101_0000_0"; -- SLLI
  elsif (opcode = "0010011" and funct3 = "101" and funct7 = "0000000") then ctrl <= B"0_010_00_1_000_1_1_00110_0000_0"; -- SRLI
  elsif (opcode = "0010011" and funct3 = "101" and funct7 = "0100000") then ctrl <= B"0_010_00_1_000_1_1_00111_0000_0"; -- SRAI
  
  elsif (opcode = "0110011" and funct3 = "000" and funct7 = "0000000") then ctrl <= B"0_000_00_1_000_0_1_00001_0000_0"; -- ADD
  elsif (opcode = "0110011" and funct3 = "000" and funct7 = "0100000") then ctrl <= B"0_000_00_1_000_0_1_01000_0000_0"; -- SUB
  elsif (opcode = "0110011" and funct3 = "100" and funct7 = "0000000") then ctrl <= B"0_000_00_1_000_0_1_00010_0000_0"; -- XOR
  elsif (opcode = "0110011" and funct3 = "110" and funct7 = "0000000") then ctrl <= B"0_000_00_1_000_0_1_00011_0000_0"; -- OR
  elsif (opcode = "0110011" and funct3 = "111" and funct7 = "0000000") then ctrl <= B"0_000_00_1_000_0_1_00100_0000_0"; -- AND
  elsif (opcode = "0110011" and funct3 = "001" and funct7 = "0000000") then ctrl <= B"0_000_00_1_000_0_1_00101_0000_0"; -- SLL
  elsif (opcode = "0110011" and funct3 = "101" and funct7 = "0000000") then ctrl <= B"0_000_00_1_000_0_1_00110_0000_0"; -- SRL
  elsif (opcode = "0110011" and funct3 = "101" and funct7 = "0100000") then ctrl <= B"0_000_00_1_000_0_1_00111_0000_0"; -- SRA
  elsif (opcode = "0110011" and funct3 = "010" and funct7 = "0000000") then ctrl <= B"0_000_00_1_000_0_1_01001_0000_0"; -- SLT
  elsif (opcode = "0110011" and funct3 = "011" and funct7 = "0000000") then ctrl <= B"0_000_00_1_000_0_1_01010_0000_0"; -- SLTU
  
  elsif (opcode = "0010011" and funct3 = "000") then ctrl <= B"0_001_00_1_000_1_1_00001_0000_0"; -- ADDI
  elsif (opcode = "0010011" and funct3 = "100") then ctrl <= B"0_001_00_1_000_1_1_00010_0000_0"; -- XORI
  elsif (opcode = "0010011" and funct3 = "110") then ctrl <= B"0_001_00_1_000_1_1_00011_0000_0"; -- ORI
  elsif (opcode = "0010011" and funct3 = "111") then ctrl <= B"0_001_00_1_000_1_1_00100_0000_0"; -- ANDI
  
  elsif (opcode = "1100011" and funct3 = "000") then ctrl <= B"0_000_00_0_000_0_1_01011_0000_0"; -- BEQ
  elsif (opcode = "1100011" and funct3 = "001") then ctrl <= B"0_000_00_0_000_0_1_01100_0000_0"; -- BNE
  elsif (opcode = "1100011" and funct3 = "100") then ctrl <= B"0_000_00_0_000_0_1_01101_0000_0"; -- BLT
  elsif (opcode = "1100011" and funct3 = "101") then ctrl <= B"0_000_00_0_000_0_1_01110_0000_0"; -- BGE
  elsif (opcode = "1100011" and funct3 = "110") then ctrl <= B"0_000_00_0_000_0_1_01111_0000_0"; -- BLTU
  elsif (opcode = "1100011" and funct3 = "111") then ctrl <= B"0_000_00_0_000_0_1_10000_0000_0"; -- BGEU
  
  elsif (opcode = "0000011" and funct3 = "010") then ctrl <= B"0_001_10_1_000_1_1_00001_0000_0"; -- LW
  elsif (opcode = "0000011" and funct3 = "001") then ctrl <= B"0_001_10_1_001_1_1_00001_0000_0"; -- LH
  elsif (opcode = "0000011" and funct3 = "101") then ctrl <= B"0_001_10_1_010_1_1_00001_0000_0"; -- LHU
  elsif (opcode = "0000011" and funct3 = "000") then ctrl <= B"0_001_10_1_011_1_1_00001_0000_0"; -- LB
  elsif (opcode = "0000011" and funct3 = "100") then ctrl <= B"0_001_10_1_100_1_1_00001_0000_0"; -- LBU
  
  elsif (opcode = "0100011" and funct3 = "010") then ctrl <= B"0_101_00_0_000_1_1_00000_1111_1"; -- SW
  elsif (opcode = "0100011" and funct3 = "001") then ctrl <= B"0_101_00_0_000_1_1_00000_0011_1"; -- SH
  elsif (opcode = "0100011" and funct3 = "000") then ctrl <= B"0_101_00_0_000_1_1_00000_0001_1"; -- SB
  
  elsif (opcode = "0110111") then ctrl <= B"0_000_00_1_000_1_0_00000_0000_0"; -- LUI
  elsif (opcode = "0010111") then ctrl <= B"0_000_00_1_000_1_0_00001_0000_0"; -- AUIPC
  
  elsif (opcode = "1101111") then ctrl <= B"1_011_01_1_000_1_0_00001_0000_0"; -- JAL
  elsif (opcode = "1100111") then ctrl <= B"1_100_01_1_000_1_1_00001_0000_0"; -- JALR

  
  
  else ctrl <= "0000000000000000000000"; -- NOP
  end if;


end process;


end architecture;
