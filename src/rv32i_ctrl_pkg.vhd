library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rv32i_ctrl_pkg is
  -- enums legíveis
  type result_src_t is (RES_ALU, RES_MEM, RES_PC4); 
  type imm_src_t    is (IMM_I, IMM_S, IMM_B, IMM_U, IMM_J);
  type src_a_t      is (SRC_A_RS1, SRC_A_PC, SRC_A_ZERO);
  type br_op_t      is (BR_NONE, BR_EQ, BR_NE, BR_LT, BR_GE, BR_LTU, BR_GEU);
  type mem_size_t   is (MS_B, MS_H, MS_W); -- quantos bytes vou ler ou escrever: MS_B - só um byte (8 bits); MS_H - halfword (16 bits); MS_W - word (32 bits)
  type jump_type_t  is (JT_NONE, JT_JAL, JT_JALR);

  -- conjunto de sinais de controle
  type ctrl_t is record
    RegWrite    : std_logic;
    MemWrite    : std_logic;
    ResultSrc   : result_src_t;
    SrcA        : src_a_t;
    SrcB        : std_logic;
    ImmSrc      : imm_src_t;
    Branch      : std_logic;
    BranchOp    : br_op_t;
    MemSize     : mem_size_t;
    MemUnsigned : std_logic; -- como completar resto do que li: 0 - completo com sinal (copia bit mais significativo da leitura para todo o resto); 1 - completo com zeros
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
