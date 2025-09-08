library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_pkg.all;

entity InstructionDecoder is
  port (
    opcode  : in  std_logic_vector(6 downto 0);
    funct3  : in  std_logic_vector(2 downto 0);
    funct7  : in  std_logic_vector(6 downto 0);
    ctrl    : out ctrl_t
  );
end entity;

architecture comportamento of InstructionDecoder is

	signal c : ctrl_t;
	
begin

	process(all)
		variable v : ctrl_t;
		
		begin
			-- valores default:
			v.weReg    := '0';
			v.MemWrite    := '0';
			v.ResultSrc   := RES_ALU;
			v.selMuxPcRs1        := SRC_A_RS1;
			v.selMuxRs2Imm        := '0';
			v.selImm      := IMM_I;
			v.Branch      := '0';
			v.BranchOp    := BR_NONE;
			v.MemSize     := MS_W;
			v.MemUnsigned := '0';
			v.ALUCtrl     := ALU_ADD;
			v.JumpType    := JT_NONE;
			v.JalrMask    := '0';
			
			case opcode is
				when OP_L =>
					v.weReg := '1';
					v.ResultSrc:= RES_MEM;
					v.selMuxRs2Imm     := '1';
					v.selImm   := IMM_I;
					v.selMuxPcRs1     := SRC_A_RS1;
					v.ALUCtrl  := ALU_ADD;
					case funct3 is
						when "000" => v.MemSize := MS_B; v.MemUnsigned := '0';
						when "001" => v.MemSize := MS_H; v.MemUnsigned := '0';
						when "010" => v.MemSize := MS_W; v.MemUnsigned := '0';
						when "100" => v.MemSize := MS_B; v.MemUnsigned := '1';
						when "101" => v.MemSize := MS_H; v.MemUnsigned := '1';
						when others => null;
					end case;
					
				when OP_S =>
					v.MemWrite := '1';
					v.selMuxRs2Imm     := '1';
					v.selImm   := IMM_S;
					v.selMuxPcRs1     := SRC_A_RS1;
					v.ALUCtrl  := ALU_ADD;
					case funct3 is
						when "000" => v.MemSize := MS_B;
						when "001" => v.MemSize := MS_H;
						when "010" => v.MemSize := MS_W;
						when others => null;
					end case;
					
				when OP_B =>
					v.Branch  := '1';
					v.selMuxRs2Imm    := '0';
					v.selImm  := IMM_B;
					v.selMuxPcRs1    := SRC_A_RS1;
					v.ALUCtrl := ALU_SUB;
					case funct3 is
						when "000" => v.BranchOp := BR_EQ;
						when "001" => v.BranchOp := BR_NE;
						when "100" => v.BranchOp := BR_LT;
						when "101" => v.BranchOp := BR_GE;
						when "110" => v.BranchOp := BR_LTU;
						when "111" => v.BranchOp := BR_GEU;
						when others=> v.BranchOp := BR_NONE;
					end case;

				when OP_I =>
					v.weReg := '1';
					v.selMuxRs2Imm     := '1';
					v.selImm   := IMM_I;
					case funct3 is -- de I para baixo, funct3 define realmente a operacao da ULA, nao eh fixada como acima (tipos L, S e B)
						when "000" => v.ALUCtrl := ALU_ADD;
						when "111" => v.ALUCtrl := ALU_AND;
						when "110" => v.ALUCtrl := ALU_OR;
						when "100" => v.ALUCtrl := ALU_XOR;
						when "010" => v.ALUCtrl := ALU_SLT;
						when "011" => v.ALUCtrl := ALU_SLTU;
						when "001" => v.ALUCtrl := ALU_SLL;
						when "101" => if funct7(5) = '1' then v.ALUCtrl := ALU_SRA; else v.ALUCtrl := ALU_SRL; end if;
						when others=> v.ALUCtrl := ALU_ADD;
					end case;
				
				when OP_R =>
					v.weReg := '1';
					v.selMuxRs2Imm     := '0';
					case funct3 is
						when "000" => if funct7(5)='1' then v.ALUCtrl := ALU_SUB; else v.ALUCtrl := ALU_ADD; end if;
						when "111" => v.ALUCtrl := ALU_AND;
						when "110" => v.ALUCtrl := ALU_OR;
						when "100" => v.ALUCtrl := ALU_XOR;
						when "010" => v.ALUCtrl := ALU_SLT;
						when "011" => v.ALUCtrl := ALU_SLTU;
						when "001" => v.ALUCtrl := ALU_SLL;
						when "101" => if funct7(5)='1' then v.ALUCtrl := ALU_SRA; else v.ALUCtrl := ALU_SRL; end if;
						when others=> v.ALUCtrl := ALU_ADD;
					end case;	
		
				when OP_LUI =>
					v.weReg := '1';
					v.selMuxRs2Imm     := '1';
					v.selImm   := IMM_U;
					v.selMuxPcRs1     := SRC_A_ZERO;
					v.ALUCtrl  := ALU_ADD;

				when OP_AUIPC =>
					v.weReg := '1';
					v.selMuxRs2Imm     := '1';
					v.selImm   := IMM_U;
					v.selMuxPcRs1     := SRC_A_PC;
					v.ALUCtrl  := ALU_ADD;

				when OP_JAL =>
					v.weReg := '1';
					v.ResultSrc:= RES_PC4;
					v.selMuxRs2Imm     := '1';
					v.selImm   := IMM_J;
					v.selMuxPcRs1     := SRC_A_PC;
					v.ALUCtrl  := ALU_ADD;
					v.JumpType := JT_JAL;

				when OP_JALR =>
					v.weReg := '1';
					v.ResultSrc:= RES_PC4;
					v.selMuxRs2Imm     := '1';
					v.selImm   := IMM_I;
					v.selMuxPcRs1     := SRC_A_RS1;
					v.ALUCtrl  := ALU_ADD;
					v.JumpType := JT_JALR;
					v.JalrMask := '1';

				when others =>
					null;
					
			end case;
			
			c <= v;
			
		end process;

  ctrl <= c;

end architecture;
