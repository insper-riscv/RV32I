library ieee;
use ieee.std_logic_1164.all;

entity alu_control is
  port (
    ALUOp  : in  std_logic_vector(1 downto 0);   -- 00=ADD gen (ld/st/auipc/jalr), 01=branch, 10=R/I-ALU
    funct3 : in  std_logic_vector(2 downto 0);
    funct7 : in  std_logic_vector(6 downto 0);   -- instr(31 downto 25)
    op_ALU : out std_logic_vector(3 downto 0) 
  );
end entity;

architecture rtl of alu_control is
  constant OP_ADD   : std_logic_vector(3 downto 0) := "0000";
  constant OP_SUB   : std_logic_vector(3 downto 0) := "0001";
  constant OP_AND   : std_logic_vector(3 downto 0) := "0010";
  constant OP_OR    : std_logic_vector(3 downto 0) := "0011";
  constant OP_XOR   : std_logic_vector(3 downto 0) := "0100";
  constant OP_SLL   : std_logic_vector(3 downto 0) := "0101";
  constant OP_SRL   : std_logic_vector(3 downto 0) := "0110";
  constant OP_SRA   : std_logic_vector(3 downto 0) := "0111";
  constant OP_SLT   : std_logic_vector(3 downto 0) := "1000";
  constant OP_SLTU  : std_logic_vector(3 downto 0) := "1001";
  -- OP_PASSB (para LUI) será forçado no top, não sai daqui.

  constant F7_NORM  : std_logic_vector(6 downto 0) := "0000000";
  constant F7_ALT   : std_logic_vector(6 downto 0) := "0100000"; -- SUB/SRA(I)
begin
  process(ALUOp, funct3, funct7)
  begin
    case ALUOp is
      when "00" => 
        op_ALU <= OP_ADD;

      when "01" =>
        op_ALU <= OP_SUB;

      when "10" =>
        case funct3 is
          when "000" =>
            if (funct7 = F7_ALT) then op_ALU <= OP_SUB; else op_ALU <= OP_ADD; end if;
          when "111" => op_ALU <= OP_AND;
          when "110" => op_ALU <= OP_OR;
          when "100" => op_ALU <= OP_XOR;
          when "001" => op_ALU <= OP_SLL;
          when "101" =>
            if (funct7 = F7_ALT) then op_ALU <= OP_SRA; else op_ALU <= OP_SRL; end if;
          when "010" => op_ALU <= OP_SLT;
          when "011" => op_ALU <= OP_SLTU;
          when others => op_ALU <= OP_ADD;
        end case;

      when others =>
        op_ALU <= OP_ADD;
    end case;
  end process;
end architecture;
