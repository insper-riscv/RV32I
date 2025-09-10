library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rv32i_ctrl_pkg is
  -- enums
  type mux_alu_pc4_ram_t is (mux_ALU_pc4_ram, mux_alu_pc4_RAM, mux_alu_PC4_ram);
  type op_ex_imm_t       is (IMM_I, IMM_I_shamt, IMM_S, IMM_U, IMM_JAL, IMM_JALR);
  type op_ex_ram_t       is (RAM_LW, RAM_LH, RAM_LHU, RAM_LB, RAM_LBU);
  type op_alu_t          is (ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR, ALU_SLT, ALU_SLTU, ALU_SLL,
                             ALU_SRL, ALU_SRA, ALU_PASS_A, ALU_PASS_B, ALU_ILLEGAL, ALU_NOP, 
                             ALU_BR_NONE, ALU_BR_EQ, ALU_BR_NE, ALU_BR_LT, ALU_BR_GE, ALU_BR_LTU, ALU_BR_GEU);

  subtype alu_slv_t is std_logic_vector(3 downto 0);

  -- conjunto de sinais de controle
  type ctrl_t is record
    selMuxPc4ALU    : std_logic;
    opExImm         : op_ex_imm_t;
    selMuxALUPc4RAM : mux_alu_pc4_ram_t;
    weReg           : std_logic;
    opExRAM         : op_ex_ram_t;
    selMuxRs2Imm    : std_logic;
    selMuxPcRs1     : std_logic;
    ALUCtrl         : alu_slv_t;
    mask            : 
    weRAM           : std_logic;
  end record;

  -- opcodes
  constant OP_LUI    : std_logic_vector(6 downto 0) := "0110111";
  constant OP_AUIPC  : std_logic_vector(6 downto 0) := "0010111";
  constant OP_I      : std_logic_vector(6 downto 0) := "0010011";
  constant OP_R      : std_logic_vector(6 downto 0) := "0110011";
  constant OP_JAL    : std_logic_vector(6 downto 0) := "1101111";
  constant OP_JALR   : std_logic_vector(6 downto 0) := "1100111";
  constant OP_B      : std_logic_vector(6 downto 0) := "1100011";
  constant OP_L      : std_logic_vector(6 downto 0) := "0000011";
  constant OP_S      : std_logic_vector(6 downto 0) := "0100011";
  constant OP_NOP    : std_logic_vector(6 downto 0) := "0000000";

  -- codificação dos 4 bits
  constant ALU_SLV_ADD    : alu_slv_t := "00000";
  constant ALU_SLV_SUB    : alu_slv_t := "00001";
  constant ALU_SLV_AND    : alu_slv_t := "00010";
  constant ALU_SLV_OR     : alu_slv_t := "00011";
  constant ALU_SLV_XOR    : alu_slv_t := "00100";
  constant ALU_SLV_SLT    : alu_slv_t := "00101";
  constant ALU_SLV_SLTU   : alu_slv_t := "00110";
  constant ALU_SLV_SLL    : alu_slv_t := "01000";
  constant ALU_SLV_SRL    : alu_slv_t := "01001";
  constant ALU_SLV_SRA    : alu_slv_t := "01010";
  constant ALU_SLV_PASS_A : alu_slv_t := "01011";
  constant ALU_SLV_PASS_B : alu_slv_t := "01100";
  constant ALU_SLV_ILLEGAL: alu_slv_t := "01111";
  constant ALU_SLV_NOP    : alu_slv_t := "00111";
  constant ALU_BR_NONE    : alu_slv_t := "10000";
  constant ALU_BR_EQ      : alu_slv_t := "10001";
  constant ALU_BR_NE      : alu_slv_t := "10010";
  constant ALU_BR_LT      : alu_slv_t := "10011";
  constant ALU_BR_GE      : alu_slv_t := "10100";
  constant ALU_BR_LTU     : alu_slv_t := "10101";
  constant ALU_BR_GEU     : alu_slv_t := "10110";

  pure function alu_slv_to_enum(slv : alu_slv_t) return op_alu_t;

end package;