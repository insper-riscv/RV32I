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
			v.selMuxPc4ALU 		:= '0';
			v.opExImm      		:= IMM_I;
			v.selMuxALUPc4RAM   := mux_ALU_pc4_ram;
			v.weReg    			:= '0';
			v.opExtRAM 			:= RAM_LW;
			v.selMuxRs2Imm      := '0';
			v.selMuxPcRs1       := '0';
			v.ALUCtrl     		:= ALU_SLV_ADD;
			v.mask 				:= MASK_SW;
			v.weRAM    			:= '0';
			
			case opcode is
				when OP_LUI =>
					v.selMuxPc4ALU 		:= '0';
					v.opExImm 			:= IMM_U;
					v.selMuxALUPc4RAM 	:= mux_ALU_pc4_ram;
					v.weReg 			:= '1';
					v.selMuxRs2Imm 		:= '1';
					v.ALUCtrl  			:= ALU_SLV_PASS_B;
					v.weRAM    			:= '0';

				when OP_AUIPC =>
					v.selMuxPc4ALU 		:= '0';
					v.opExImm   		:= IMM_U;
					v.selMuxALUPc4RAM 	:= mux_ALU_pc4_ram;
					v.weReg 			:= '1';
					v.selMuxRs2Imm     	:= '1';
					v.selMuxPcRs1     	:= '0';
					v.ALUCtrl  			:= ALU_SLV_ADD;
					v.weRAM    			:= '0';

				when OP_I =>
					v.selMuxPc4ALU 		:= '0';
					v.opExImm   		:= IMM_U;
					v.selMuxALUPc4RAM 	:= mux_ALU_pc4_ram;
					v.weReg 			:= '1';
					v.selMuxRs2Imm     	:= '1';
					v.selMuxPcRs1     	:= '1';
					v.ALUCtrl  			:= ALU_SLV_ADD;
					v.weRAM    			:= '0';
					case funct3 is
						when "000" => v.ALUCtrl := ALU_SLV_ADD;
						when "111" => v.ALUCtrl := ALU_SLV_AND;
						when "110" => v.ALUCtrl := ALU_SLV_OR;
						when "100" => v.ALUCtrl := ALU_SLV_XOR;
						when "010" => v.ALUCtrl := ALU_SLV_SLT;
						when "011" => v.ALUCtrl := ALU_SLV_SLTU;
						when "001" => v.ALUCtrl := ALU_SLV_SLL;
						when "101" => if funct7(5) = '1' then v.ALUCtrl := ALU_SLV_SRA; else v.ALUCtrl := ALU_SLV_SRL; end if;
						when others=> v.ALUCtrl := ALU_SLV_ADD;
					end case;

				when OP_R =>
					v.selMuxPc4ALU 		:= '0';
					v.selMuxALUPc4RAM   := mux_ALU_pc4_ram;
					v.weReg    			:= '1';
					v.selMuxRs2Imm      := '0';
					v.selMuxPcRs1       := '1';
					v.weRAM    			:= '0';
					case funct3 is
						when "000" => if funct7(5)='1' then v.ALUCtrl := ALU_SLV_SUB; else v.ALUCtrl := ALU_SLV_ADD; end if;
						when "111" => v.ALUCtrl := ALU_SLV_AND;
						when "110" => v.ALUCtrl := ALU_SLV_OR;
						when "100" => v.ALUCtrl := ALU_SLV_XOR;
						when "010" => v.ALUCtrl := ALU_SLV_SLT;
						when "011" => v.ALUCtrl := ALU_SLV_SLTU;
						when "001" => v.ALUCtrl := ALU_SLV_SLL;
						when "101" => if funct7(5)='1' then v.ALUCtrl := ALU_SLV_SRA; else v.ALUCtrl := ALU_SLV_SRL; end if;
						when others=> v.ALUCtrl := ALU_SLV_ADD;
					end case;

				when OP_JAL =>
					v.selMuxPc4ALU 		:= '0';
					v.opExImm      		:= IMM_JAL;
					v.selMuxALUPc4RAM   := mux_alu_PC4_ram;
					v.weReg    			:= '1';
					v.selMuxRs2Imm      := '1';
					v.selMuxPcRs1       := '0';
					v.ALUCtrl     		:= ALU_SLV_ADD;
					v.weRAM    			:= '0';

				when OP_JALR =>
					v.selMuxPc4ALU 		:= '0';
					v.opExImm      		:= IMM_JALR;
					v.selMuxALUPc4RAM   := mux_alu_PC4_ram;
					v.weReg    			:= '1';
					v.selMuxRs2Imm      := '1';
					v.selMuxPcRs1       := '1';
					v.ALUCtrl     		:= ALU_SLV_ADD;
					v.weRAM    			:= '0';

				when OP_B =>
					v.selMuxPc4ALU 		:= '1';
					v.selMuxALUPc4RAM   := mux_alu_pc4_RAM;
					v.weReg    			:= '1';
					v.selMuxRs2Imm      := '0';
					v.selMuxPcRs1       := '1';
					v.weRAM    			:= '0';
					case funct3 is
						when "000" => v.ALUCtrl := ALU_SLV_BR_EQ;
						when "001" => v.ALUCtrl := ALU_SLV_BR_NE;
						when "100" => v.ALUCtrl := ALU_SLV_BR_LT;
						when "101" => v.ALUCtrl := ALU_SLV_BR_GE;
						when "110" => v.ALUCtrl := ALU_SLV_BR_LTU;
						when "111" => v.ALUCtrl := ALU_SLV_BR_GEU;
						when others=> v.ALUCtrl := ALU_SLV_BR_NONE;
					end case;

				when OP_L =>
					v.selMuxPc4ALU 		:= '0';
					v.opExImm      		:= IMM_I;
					v.selMuxALUPc4RAM   := mux_alu_pc4_RAM;
					v.weReg    			:= '1';
					v.selMuxRs2Imm      := '1';
					v.selMuxPcRs1       := '1';
					v.ALUCtrl     		:= ALU_SLV_ADD;
					v.weRAM    			:= '0';
					case funct3 is
						when "000" => v.opExtRAM := RAM_LB;
						when "001" => v.opExtRAM := RAM_LH;
						when "010" => v.opExtRAM := RAM_LW;
						when "100" => v.opExtRAM := RAM_LBU;
						when "101" => v.opExtRAM := RAM_LHU;
						when others=> null;
					end case;

				when OP_S =>
					v.selMuxPc4ALU 		:= '0';
					v.opExImm      		:= IMM_S;
					v.weReg    			:= '0';
					v.selMuxRs2Imm      := '1';
					v.selMuxPcRs1       := '1';
					v.ALUCtrl     		:= ALU_SLV_PASS;
					v.weRAM    			:= '1';
					case funct3 is
						when "000" => v.mask := MASK_SB;
						when "001" => v.mask := MASK_SH;
						when "010" => v.mask := MASK_SW;
						when others => null;
					end case;

				when OP_NOP =>
					v.selMuxPc4ALU 		:= '0';
					v.opExImm      		:= IMM_I;
					v.selMuxALUPc4RAM   := mux_ALU_pc4_ram;
					v.weReg    			:= '0';
					v.opExtRAM 			:= RAM_LW;
					v.selMuxRs2Imm      := '0';
					v.selMuxPcRs1       := '0';
					v.ALUCtrl     		:= ALU_SLV_ADD;
					v.mask 				:= MASK_SW;
					v.weRAM    			:= '0';
					
			end case;
			
			c <= v;
			
		end process;

  ctrl <= c;

end architecture;
