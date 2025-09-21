library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_consts.all;

entity InstructionDecoder is
  port (
    opcode  : in  std_logic_vector(6 downto 0);
    funct3  : in  std_logic_vector(2 downto 0);
    funct7  : in  std_logic_vector(6 downto 0);

    selMuxPc4ALU    : out std_logic;
    opExImm         : out std_logic_vector(2 downto 0);
    selMuxALUPc4RAM : out std_logic_vector(1 downto 0);
    weReg           : out std_logic;
    opExRAM         : out std_logic_vector(2 downto 0);
    selMuxRS2Imm    : out std_logic;
    selPCRS1        : out std_logic;
    opALU           : out std_logic_vector(4 downto 0);
    weRAM           : out std_logic;
    reRAM           : out std_logic;
    eRAM           : out std_logic

  );
end entity;

architecture behaviour of InstructionDecoder is

	-- add necessary signals here
begin

process(opcode, funct3, funct7)
begin

  if    (opcode = "0010011" and funct3 = "001" and funct7 = "0000000") then -- SLLI
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_I_SHAMT;
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_SLL;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

  elsif (opcode = "0010011" and funct3 = "101" and funct7 = "0000000") then -- SRLI
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_I_SHAMT;
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_SRL;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

  elsif (opcode = "0010011" and funct3 = "101" and funct7 = "0100000") then -- SRAI
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_I_SHAMT;
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_SRA;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

  elsif (opcode = "0110011" and funct3 = "000" and funct7 = "0000000") then -- ADD
    selMuxPc4ALU    <= '0';
    opExImm         <= "000";
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_ADD;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

  elsif (opcode = "0110011" and funct3 = "000" and funct7 = "0100000") then -- SUB
    selMuxPc4ALU    <= '0';
    opExImm         <= "000";
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_SUB;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

  elsif (opcode = "0110011" and funct3 = "100" and funct7 = "0000000") then -- XOR
    selMuxPc4ALU    <= '0';
    opExImm         <= "000";
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_XOR;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

  elsif (opcode = "0110011" and funct3 = "110" and funct7 = "0000000") then -- OR
    selMuxPc4ALU    <= '0';
    opExImm         <= "000";
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_OR;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

  elsif (opcode = "0110011" and funct3 = "111" and funct7 = "0000000") then -- AND
    selMuxPc4ALU    <= '0';
    opExImm         <= "000";
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_AND;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

  elsif (opcode = "0110011" and funct3 = "001" and funct7 = "0000000") then -- SLL
    selMuxPc4ALU    <= '0';
    opExImm         <= "000";
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_SLL;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

  elsif (opcode = "0110011" and funct3 = "101" and funct7 = "0000000") then -- SRL
    selMuxPc4ALU    <= '0';
    opExImm         <= "000";
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_SRL;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

  elsif (opcode = "0110011" and funct3 = "101" and funct7 = "0100000") then -- SRA
    selMuxPc4ALU    <= '0';
    opExImm         <= "000";
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_SRA;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

  elsif (opcode = "0110011" and funct3 = "010" and funct7 = "0000000") then -- SLT
    selMuxPc4ALU    <= '0';
    opExImm         <= "000";
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_SLT;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

  elsif (opcode = "0110011" and funct3 = "011" and funct7 = "0000000") then -- SLTU
    selMuxPc4ALU    <= '0';
    opExImm         <= "000";
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_SLTU;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
  

  elsif (opcode = "0010011" and funct3 = "000") then -- ADDI
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_I;
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_ADD;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
     
  elsif (opcode = "0010011" and funct3 = "100") then -- XORI
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_I;
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_XOR;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
     
  elsif (opcode = "0010011" and funct3 = "110") then -- ORI
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_I;
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_OR;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
     
  elsif (opcode = "0010011" and funct3 = "111") then -- ANDI
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_I;
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_AND;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';


  
  elsif (opcode = "1100011" and funct3 = "000") then -- BEQ
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_B;
    selMuxALUPc4RAM <= "00";
    weReg           <= '0';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_BEQ;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
     
  elsif (opcode = "1100011" and funct3 = "001") then -- BNE
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_B;
    selMuxALUPc4RAM <= "00";
    weReg           <= '0';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_BNE;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
     
  elsif (opcode = "1100011" and funct3 = "100") then -- BLT
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_B;
    selMuxALUPc4RAM <= "00";
    weReg           <= '0';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_BLT;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
     
  elsif (opcode = "1100011" and funct3 = "101") then -- BGE
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_B;
    selMuxALUPc4RAM <= "00";
    weReg           <= '0';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_BGE;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
     
  elsif (opcode = "1100011" and funct3 = "110") then -- BLTU
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_B;
    selMuxALUPc4RAM <= "00";
    weReg           <= '0';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_BLTU;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
     
  elsif (opcode = "1100011" and funct3 = "111") then -- BGEU
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_B;
    selMuxALUPc4RAM <= "00";
    weReg           <= '0';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '1';
    opALU           <= OPALU_BGEU;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
     

  
  elsif (opcode = "0000011" and funct3 = "010") then -- LW
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_I;
    selMuxALUPc4RAM <= "10";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_ADD;
    weRAM           <= '0';
    reRAM           <= '1';
    eRAM            <= '1';
     
  elsif (opcode = "0000011" and funct3 = "001") then -- LH
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_I;
    selMuxALUPc4RAM <= "10";
    weReg           <= '1';
    opExRAM         <= OPEXRAM_LH;
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_ADD;
    weRAM           <= '0';
    reRAM           <= '1';
    eRAM            <= '1';
     
  elsif (opcode = "0000011" and funct3 = "101") then -- LHU
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_I;
    selMuxALUPc4RAM <= "10";
    weReg           <= '1';
    opExRAM         <= OPEXRAM_LHU;
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_ADD;
    weRAM           <= '0';
    reRAM           <= '1';
    eRAM            <= '1';
     
  elsif (opcode = "0000011" and funct3 = "000") then -- LB
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_I;
    selMuxALUPc4RAM <= "10";
    weReg           <= '1';
    opExRAM         <= OPEXRAM_LB;
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_ADD;
    weRAM           <= '0';
    reRAM           <= '1';
    eRAM            <= '1';
     
  elsif (opcode = "0000011" and funct3 = "100") then -- LBU
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_I;
    selMuxALUPc4RAM <= "10";
    weReg           <= '1';
    opExRAM         <= OPEXRAM_LBU;
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_ADD;
    weRAM           <= '0';
    reRAM           <= '1';
    eRAM            <= '1';
     

  
  elsif (opcode = "0100011" and funct3 = "010") then -- SW
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_S;
    selMuxALUPc4RAM <= "00";
    weReg           <= '0';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_PASS_B;
    weRAM           <= '1';
    reRAM           <= '0';
    eRAM            <= '1';
     
  elsif (opcode = "0100011" and funct3 = "001") then -- SH
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_S;
    selMuxALUPc4RAM <= "00";
    weReg           <= '0';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_PASS_B;
    weRAM           <= '1';
    reRAM           <= '0';
    eRAM            <= '1';
     
  elsif (opcode = "0100011" and funct3 = "000") then -- SB
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_S;
    selMuxALUPc4RAM <= "00";
    weReg           <= '0';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_PASS_B;
    weRAM           <= '1';
    reRAM           <= '0';
    eRAM            <= '1';
     

  
  elsif (opcode = "0110111") then -- LUI
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_U;
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '0';
    opALU           <= OPALU_PASS_B;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
     
  elsif (opcode = "0010111") then -- AUIPC
    selMuxPc4ALU    <= '0';
    opExImm         <= OPEXIMM_U;
    selMuxALUPc4RAM <= "00";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '0';
    opALU           <= OPALU_ADD;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
     
  

  elsif (opcode = "1101111") then -- JAL
    selMuxPc4ALU    <= '1';
    opExImm         <= OPEXIMM_J;
    selMuxALUPc4RAM <= "01";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '0';
    opALU           <= OPALU_ADD;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
     
  elsif (opcode = "1100111") then -- JALR
    selMuxPc4ALU    <= '1';
    opExImm         <= OPEXIMM_I;
    selMuxALUPc4RAM <= "01";
    weReg           <= '1';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '1';
    selPCRS1        <= '1';
    opALU           <= OPALU_ADD;
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
  

  else 
    selMuxPc4ALU    <= '0';
    opExImm         <= "000";
    selMuxALUPc4RAM <= "00";
    weReg           <= '0';
    opExRAM         <= "000";
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '0';
    opALU           <= "00000";
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';
  end if;


end process;


end architecture;
