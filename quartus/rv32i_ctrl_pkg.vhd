library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rv32i_ctrl_pkg is
  -- enums legíveis
  type mux_alu_pc4_ram_t is (mux_ALU_pc4_ram, mux_alu_pc4_RAM, mux_alu_PC4_ram);
  type op_ex_imm_t    is (IMM_I, IMM_I_shamt IMM_S, IMM_U, IMM_J);
  type a_sel_t      is (A_RS1, A_PC, A_ZERO);
  type branch_op_t      is (ALU_BR_NONE, ALU_BR_EQ, ALU_BR_NE, ALU_BR_LT, ALU_BR_GE, ALU_BR_LTU, ALU_BR_GEU);
  type mem_size_t   is (MS_B, MS_H, MS_W);
  type jump_type_t  is (JT_NONE, JT_JAL, JT_JALR);

  -- “pacote” de controle
  type ctrl_t is record
    weReg    : std_logic;
    weRAM    : std_logic;
    selMuxImmPc4ALU   : mux_alu_pc4_ram_t;
    ASel        : a_sel_t;
    ALUSrc      : std_logic;
    opExImm      : op_ex_imm_t;
    Branch      : std_logic;
    BranchOp    : branch_op_t;
    MemSize     : mem_size_t;
    MemUnsigned : std_logic;
    ALUCtrl     : std_logic_vector(3 downto 0);
    JumpType    : jump_type_t;
    JalrMask    : std_logic;
  end record;

  -- opcodes
  constant OP_LUI    : std_logic_vector(6 downto 0) := "0110111";
  constant OP_AUIPC  : std_logic_vector(6 downto 0) := "0010111";
  constant OP_JAL    : std_logic_vector(6 downto 0) := "1101111";
  constant OP_JALR   : std_logic_vector(6 downto 0) := "1100111";
  constant OP_B      : std_logic_vector(6 downto 0) := "1100011";
  constant OP_L      : std_logic_vector(6 downto 0) := "0000011";
  constant OP_S      : std_logic_vector(6 downto 0) := "0100011";
  constant OP_I      : std_logic_vector(6 downto 0) := "0010011";
  constant OP_R      : std_logic_vector(6 downto 0) := "0110011";
end package;
