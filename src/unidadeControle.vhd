library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_pkg.all;

entity unidadeControle is
  port (
    opcode  : in  std_logic_vector(6 downto 0);
    funct3  : in  std_logic_vector(2 downto 0);
    funct7  : in  std_logic_vector(6 downto 0);
    ctrl    : out ctrl_t
  );
end entity;

architecture comportamento of unidadeControle is

	signal c : ctrl_t;
	
begin

	process(all)
		variable v : ctrl_t;
		
		begin
			-- valores default:
			v.RegWrite    := '0';
			v.MemWrite    := '0';
			v.ResultSrc   := RES_ALU;
			v.SrcA        := SRC_A_RS1;
			v.SrcB        := '0';
			v.ImmSrc      := IMM_I;
			v.Branch      := '0';
			v.BranchOp    := BR_NONE;
			v.MemSize     := MS_W;
			v.MemUnsigned := '0';
			v.ALUCtrl     := "0000";
			v.JumpType    := JT_NONE;
			v.JalrMask    := '0';
			
			case opcode is
				when OP_L =>
					v.RegWrite := '1';
					v.ResultSrc:= RES_MEM;
					v.SrcB     := '1';
					v.ImmSrc   := IMM_I;
					v.SrcA     := SRC_A_RS1;
					v.ALUCtrl  := "0000";
					case funct3 is
						when "000" => v.MemSize:=MS_B; v.MemUnsigned:='0';
						when "001" => v.MemSize:=MS_H; v.MemUnsigned:='0';
						when "010" => v.MemSize:=MS_W; v.MemUnsigned:='0';
						when "100" => v.MemSize:=MS_B; v.MemUnsigned:='1';
						when "101" => v.MemSize:=MS_H; v.MemUnsigned:='1';
						when others => null;
					end case;
					
				when OP_S =>
					v.MemWrite := '1';
					v.SrcB     := '1';
					v.ImmSrc   := IMM_S;
					v.SrcA     := SRC_A_RS1;
					v.ALUCtrl  := "0000";
					case funct3 is
						when "000" => v.MemSize:=MS_B;
						when "001" => v.MemSize:=MS_H;
						when "010" => v.MemSize:=MS_W;
						when others => null;
					end case;
					
				when OP_B =>
					v.Branch  := '1';
					v.SrcB    := '0';
					v.ImmSrc  := IMM_B;
					v.SrcA    := SRC_A_RS1;
					v.ALUCtrl := "0001";
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
					v.RegWrite := '1';
					v.SrcB     := '1';
					v.ImmSrc   := IMM_I;
					case funct3 is -- de I para baixo, funct3 define realmente a operacao da ULA, nao eh fixada como acima (tipos L, S e B)
						when "000" => v.ALUCtrl := "0000";
						when "111" => v.ALUCtrl := "0010";
						when "110" => v.ALUCtrl := "0011";
						when "100" => v.ALUCtrl := "0100";
						when "010" => v.ALUCtrl := "0101";
						when "011" => v.ALUCtrl := "0110";
						when "001" => v.ALUCtrl := "1000";
						when "101" => if funct7(5)='1' then v.ALUCtrl:="1010"; else v.ALUCtrl:="1001"; end if;
						when others=> v.ALUCtrl := "0000";
					end case;
				
				when OP_R =>
					v.RegWrite := '1';
					v.SrcB     := '0';
					case funct3 is
						when "000" => if funct7(5)='1' then v.ALUCtrl:="0001"; else v.ALUCtrl:="0000"; end if;
						when "111" => v.ALUCtrl := "0010";
						when "110" => v.ALUCtrl := "0011";
						when "100" => v.ALUCtrl := "0100";
						when "010" => v.ALUCtrl := "0101";
						when "011" => v.ALUCtrl := "0110";
						when "001" => v.ALUCtrl := "1000";
						when "101" => if funct7(5)='1' then v.ALUCtrl:="1010"; else v.ALUCtrl:="1001"; end if;
						when others=> v.ALUCtrl := "0000";
					end case;			
		
				when OP_LUI =>
					v.RegWrite := '1';
					v.SrcB     := '1';
					v.ImmSrc   := IMM_U;
					v.SrcA     := SRC_A_ZERO;
					v.ALUCtrl  := "0000";

				when OP_AUIPC =>
					v.RegWrite := '1';
					v.SrcB     := '1';
					v.ImmSrc   := IMM_U;
					v.SrcA     := SRC_A_PC;
					v.ALUCtrl  := "0000";

				when OP_JAL =>
					v.RegWrite := '1';
					v.ResultSrc:= RES_PC4;
					v.SrcB     := '1';
					v.ImmSrc   := IMM_J;
					v.SrcA     := SRC_A_PC;
					v.ALUCtrl  := "0000";
					v.JumpType := JT_JAL;

				when OP_JALR =>
					v.RegWrite := '1';
					v.ResultSrc:= RES_PC4;
					v.SrcB     := '1';
					v.ImmSrc   := IMM_I;
					v.SrcA     := SRC_A_RS1;
					v.ALUCtrl  := "0000";
					v.JumpType := JT_JALR;
					v.JalrMask := '1';

				when others =>
					null;
					
			end case;
			
			c <= v;
			
		end process;

  ctrl <= c;

end architecture;
