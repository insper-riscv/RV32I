library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rv32i_ctrl_pkg is
  -- enums
  type mux_alu_pc4_ram_t is (mux_out_ALU, mux_out_RAM, mux_out_PC4);
  type op_ex_imm_t       is (IMM_I, IMM_I_shamt, IMM_S, IMM_U, IMM_JAL, IMM_JALR);
  type op_ex_ram_t       is (RAM_LW, RAM_LH, RAM_LHU, RAM_LB, RAM_LBU);
  type mask_t            is (MASK_SW, MASK_SH, MASK_SB);
  type op_alu_t          is (ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR, ALU_SLT, ALU_SLTU, ALU_SLL,
                             ALU_SRL, ALU_SRA, ALU_PASS_A, ALU_PASS_B, ALU_ILLEGAL, ALU_NOP, 
                             ALU_BR_NONE, ALU_BR_EQ, ALU_BR_NE, ALU_BR_LT, ALU_BR_GE, ALU_BR_LTU, ALU_BR_GEU);

  subtype op_alu_slv_t is std_logic_vector(4 downto 0);
  subtype op_ex_imm_slv_t is std_logic_vector(2 downto 0);
  subtype op_ex_ram_slv_t is std_logic_vector(2 downto 0);

  -- conjunto de sinais de controle
  type ctrl_t is record
    selMuxPc4ALU    : std_logic;
    opExImm         : op_ex_imm_slv_t;
    selMuxALUPc4RAM : mux_alu_pc4_ram_t;
    weReg           : std_logic;
    opExRAM         : op_ex_ram_slv_t;
    selMuxRs2Imm    : std_logic;
    selMuxPcRs1     : std_logic;
    ALUCtrl         : op_alu_slv_t;
    mask            : mask_t;
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

  -- codificação dos 5 bits de operação da ula
  constant ALU_SLV_ADD    : op_alu_slv_t := "00000";
  constant ALU_SLV_SUB    : op_alu_slv_t := "00001";
  constant ALU_SLV_AND    : op_alu_slv_t := "00010";
  constant ALU_SLV_OR     : op_alu_slv_t := "00011";
  constant ALU_SLV_XOR    : op_alu_slv_t := "00100";
  constant ALU_SLV_SLT    : op_alu_slv_t := "00101";
  constant ALU_SLV_SLTU   : op_alu_slv_t := "00110";
  constant ALU_SLV_SLL    : op_alu_slv_t := "01000";
  constant ALU_SLV_SRL    : op_alu_slv_t := "01001";
  constant ALU_SLV_SRA    : op_alu_slv_t := "01010";
  constant ALU_SLV_PASS_A : op_alu_slv_t := "01011";
  constant ALU_SLV_PASS_B : op_alu_slv_t := "01100";
  constant ALU_SLV_ILLEGAL: op_alu_slv_t := "01111";
  constant ALU_SLV_NOP    : op_alu_slv_t := "00111";
  constant ALU_SLV_BR_NONE: op_alu_slv_t := "10000";
  constant ALU_SLV_BR_EQ  : op_alu_slv_t := "10001";
  constant ALU_SLV_BR_NE  : op_alu_slv_t := "10010";
  constant ALU_SLV_BR_LT  : op_alu_slv_t := "10011";
  constant ALU_SLV_BR_GE  : op_alu_slv_t := "10100";
  constant ALU_SLV_BR_LTU : op_alu_slv_t := "10101";
  constant ALU_SLV_BR_GEU : op_alu_slv_t := "10110";

  -- codificação dos 3 bits de operação do extensor de imediato
  constant IMM_SLV_I      : op_ex_imm_slv_t := "000";
  constant IMM_SLV_I_shamt: op_ex_imm_slv_t := "001";
  constant IMM_SLV_S      : op_ex_imm_slv_t := "010";
  constant IMM_SLV_U      : op_ex_imm_slv_t := "011";
  constant IMM_SLV_JAL    : op_ex_imm_slv_t := "100";
  constant IMM_SLV_JALR   : op_ex_imm_slv_t := "101";

  -- codificação dos 3 bits de operação do extensor da RAM
  constant RAM_SLV_LW     : op_ex_ram_slv_t := "000";
  constant RAM_SLV_LH     : op_ex_ram_slv_t := "001";
  constant RAM_SLV_LHU    : op_ex_ram_slv_t := "010";
  constant RAM_SLV_LB     : op_ex_ram_slv_t := "011";
  constant RAM_SLV_LBU    : op_ex_ram_slv_t := "100";

  -- conversion functions
  pure function alu_slv_to_enum(slv : op_alu_slv_t) return op_alu_t;
  pure function ex_imm_slv_to_enum(slv : op_ex_imm_slv_t) return op_ex_imm_t;
  pure function ex_ram_slv_to_enum(slv : op_ex_ram_slv_t) return op_ex_ram_t;

end package;