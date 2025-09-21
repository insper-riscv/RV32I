library ieee;
use ieee.std_logic_1164.all;

package rv32i_ctrl_consts is

  ------------------------------------------------------------------
  -- opExImm[2:0]
  ------------------------------------------------------------------
  constant OPEXIMM_U       : std_logic_vector(2 downto 0) := "000";
  constant OPEXIMM_I       : std_logic_vector(2 downto 0) := "001";
  constant OPEXIMM_I_SHAMT : std_logic_vector(2 downto 0) := "010";
  constant OPEXIMM_J       : std_logic_vector(2 downto 0) := "011";
  constant OPEXIMM_S       : std_logic_vector(2 downto 0) := "100";
  constant OPEXIMM_B       : std_logic_vector(2 downto 0) := "101";

  ------------------------------------------------------------------
  -- opExRAM[2:0]
  ------------------------------------------------------------------
  constant OPEXRAM_LW  : std_logic_vector(2 downto 0) := "000";
  constant OPEXRAM_LH  : std_logic_vector(2 downto 0) := "001";
  constant OPEXRAM_LHU : std_logic_vector(2 downto 0) := "010";
  constant OPEXRAM_LB  : std_logic_vector(2 downto 0) := "011";
  constant OPEXRAM_LBU : std_logic_vector(2 downto 0) := "100";

  ------------------------------------------------------------------
  -- opALU[4:0]
  ------------------------------------------------------------------
  constant OPALU_PASS_B : std_logic_vector(4 downto 0) := "00000";
  constant OPALU_ADD    : std_logic_vector(4 downto 0) := "00001";
  constant OPALU_XOR    : std_logic_vector(4 downto 0) := "00010";
  constant OPALU_OR     : std_logic_vector(4 downto 0) := "00011";
  constant OPALU_AND    : std_logic_vector(4 downto 0) := "00100";
  constant OPALU_SLL    : std_logic_vector(4 downto 0) := "00101";
  constant OPALU_SRL    : std_logic_vector(4 downto 0) := "00110";
  constant OPALU_SRA    : std_logic_vector(4 downto 0) := "00111";
  constant OPALU_SUB    : std_logic_vector(4 downto 0) := "01000";
  constant OPALU_SLT    : std_logic_vector(4 downto 0) := "01001";
  constant OPALU_SLTU   : std_logic_vector(4 downto 0) := "01010";
  constant OPALU_BEQ    : std_logic_vector(4 downto 0) := "01011";
  constant OPALU_BNE    : std_logic_vector(4 downto 0) := "01100";
  constant OPALU_BLT    : std_logic_vector(4 downto 0) := "01101";
  constant OPALU_BGE    : std_logic_vector(4 downto 0) := "01110";
  constant OPALU_BLTU   : std_logic_vector(4 downto 0) := "01111";
  constant OPALU_BGEU   : std_logic_vector(4 downto 0) := "10000";

end package rv32i_ctrl_consts;
