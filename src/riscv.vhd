library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_pkg.all;

entity riscv is
  generic   (
    DATA_WIDTH  : natural :=  32;
    ADDR_WIDTH  : natural :=  32
  );

  port   (
    clk     : in  std_logic;
    dataOUT : out  std_logic_vector(31 downto 0)
  );
end entity;


architecture arch_name of riscv is
		
	signal proxPC         : std_logic_vector(31 downto 0);
	signal addr       : std_logic_vector(31 downto 0);
	signal Inst      : std_logic_vector(31 downto 0);
	
	signal PCTarget   	  : std_logic_vector(31 downto 0);
	signal PCNext         : std_logic_vector(31 downto 0);
	signal ImmExt     	  : std_logic_vector(31 downto 0);
	signal data_in_RegFile : std_logic_vector(31 downto 0);
	signal d_rs1: std_logic_vector(31 downto 0);
	signal d_rs2: std_logic_vector(31 downto 0);
	signal dA : std_logic_vector(31 downto 0);
	signal dB : std_logic_vector(31 downto 0);
	signal ALU_out      : std_logic_vector(31 downto 0);
	signal RAM_out : std_logic_vector(31 downto 0);
	signal taken          : std_logic;
	signal alu_overflow   : std_logic;
	
	alias opcode 			 : std_logic_vector(6 downto 0) is Inst( 6 downto 0);
	alias rd     			 : std_logic_vector(4 downto 0) is Inst(11 downto 7);
	alias funct3 			 : std_logic_vector(2 downto 0) is Inst(14 downto 12);
	alias rs1    			 : std_logic_vector(4 downto 0) is Inst(19 downto 15);
	alias rs2    			 : std_logic_vector(4 downto 0) is Inst(24 downto 20);
	alias funct7 			 : std_logic_vector(6 downto 0) is Inst(31 downto 25);
		
	signal ctrl : ctrl_t;

begin

-- MUX_PCNext:			 
PCNext <= (ALU_out and x"FFFFFFFE") when (ctrl.JumpType=JT_JALR) else
			    PCTarget when (ctrl.JumpType=JT_JAL or (ctrl.Branch='1' and taken='1')) else
				 proxPC;

PC : entity work.genericRegister   generic map (data_width => 32)
			port map(   clock => clk, 
						clear => '0',
						enable => '1', 
						source => PCNext, 
						destination => addr);
						 
ROM : entity work.ROM
			port map( addr => addr, 
						 data => Inst);

-- incrementaPC:					 
proxPC <= std_logic_vector(unsigned(addr) + 4);

-- somador_PCTarget:				 
PCTarget <= STD_LOGIC_VECTOR(unsigned(addr) + unsigned(ImmExt));
						 
RegFile : entity work.RegFile
			port map( clk => clk, 
					  rs1 => rs1, 
					  rs2 => rs2, 
					  rd => rd, 
					  data_in => data_in_RegFile, 
					  we => ctrl.weReg, 
					  d_rs1 => d_rs1, 
					  d_rs2 => d_rs2);
						 
ALU : entity work.ALU generic map ( DATA_WIDTH => 32 )
			port map (
				op			    => ctrl.ALUCtrl,
				source_1        => dA,
				source_2        => dB,
				destination     => ALU_out
			);
						 
-- MUX_ALUSrcA:
with ctrl.selMuxPcRs1 select				 
	dA <= d_rs1 when SRC_A_RS1,
							addr        when SRC_A_PC,
							(others => '0') when SRC_A_ZERO;
						 
-- MUX_ALUSrcB:					 
dB <= ImmExt when (ctrl.selMuxRs2Imm = '1') else d_rs2;
		  
RAM : entity work.RAM
			port map( clk => clk,
						 addr => ALU_out,
						 data_in => d_rs2,
						 data_out => RAM_out, 
						 we => ctrl.MemWrite);
						 
-- MUX_ResultSrc:
with ctrl.ResultSrc select
	data_in_RegFile <= ALU_out 		when RES_ALU,
								  RAM_out  when RES_MEM,
								  proxPC 			when RES_PC4;
						 
extensor : entity work.immediateGen
			port map( instru => Inst,
						 selImm => ctrl.selImm,
						 ImmExt => ImmExt);
			 
UC : entity work.unidadeControle
			port map( opcode => Inst(6 downto 0),
						 funct3 => funct3,
						 funct7 => funct7,
						 ctrl => ctrl);
						 
taken <= '1' when ( -- quando for 1, significa que o pulo do branch sera feito
          (ctrl.BranchOp = BR_EQ  and (d_rs1 =  d_rs2)) or
          (ctrl.BranchOp = BR_NE  and (d_rs1 /= d_rs2)) or
          (ctrl.BranchOp = BR_LT  and (signed(d_rs1)  <  signed(d_rs2))) or
          (ctrl.BranchOp = BR_GE  and (signed(d_rs1)  >= signed(d_rs2))) or
          (ctrl.BranchOp = BR_LTU and (unsigned(d_rs1) <  unsigned(d_rs2))) or
          (ctrl.BranchOp = BR_GEU and (unsigned(d_rs1) >= unsigned(d_rs2)))
        ) else '0';

end architecture;
			 

-- ainda nao alterado:

-- HEX e LED
						 
-- MUXHEXeLED:
EntradaHEXeLED <= dados when (sel = "01") else
					   dados when (sel = "10") else
						dados when (sel = "11") else
					   addr;
					  
SETE_SEG_0 :  entity work.conversorHex7Seg
        port map(dadoHex => EntradaHEXeLED(3 downto 0),
                 apaga =>  '0',
                 negativo => '0',
                 overFlow =>  '0',
                 saida7seg => HEX0);
					  
SETE_SEG_1 :  entity work.conversorHex7Seg
        port map(dadoHex => EntradaHEXeLED(7 downto 4),
                 apaga =>  '0',
                 negativo => '0',
                 overFlow =>  '0',
                 saida7seg => HEX1);
					  
SETE_SEG_2 :  entity work.conversorHex7Seg
        port map(dadoHex => EntradaHEXeLED(11 downto 8),
                 apaga =>  '0',
                 negativo => '0',
                 overFlow =>  '0',
                 saida7seg => HEX2);	
					  
SETE_SEG_3 :  entity work.conversorHex7Seg
        port map(dadoHex => EntradaHEXeLED(15 downto 12),
                 apaga =>  '0',
                 negativo => '0',
                 overFlow =>  '0',
                 saida7seg => HEX3);
					  
SETE_SEG_4 :  entity work.conversorHex7Seg
        port map(dadoHex => EntradaHEXeLED(19 downto 16),
                 apaga =>  '0',
                 negativo => '0',
                 overFlow =>  '0',
                 saida7seg => HEX4);
					  
SETE_SEG_5 :  entity work.conversorHex7Seg
        port map(dadoHex => EntradaHEXeLED(23 downto 20),
                 apaga =>  '0',
                 negativo => '0',
                 overFlow =>  '0',
                 saida7seg => HEX5);
					  
LEDR(4 downto 0) <= EntradaHEXeLED(28  downto 24);
LEDR(7 downto 5) <= EntradaHEXeLED(31  downto 29);

end architecture;