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
	signal Endereco       : std_logic_vector(31 downto 0);
	signal Instrucao      : std_logic_vector(31 downto 0);
	
	signal PCTarget   	 : std_logic_vector(31 downto 0);
	signal entradaPC   	 : std_logic_vector(31 downto 0);
	signal ImmExt     	 : std_logic_vector(31 downto 0);
	signal saida_MUX_ResultSrc : std_logic_vector(31 downto 0);
	signal saidaA_bancoReg: std_logic_vector(31 downto 0);
	signal saidaB_bancoReg: std_logic_vector(31 downto 0);
	signal saida_MUX_SrcA : std_logic_vector(31 downto 0);
	signal saida_MUX_SrcB : std_logic_vector(31 downto 0);
	signal saida_ULA      : std_logic_vector(31 downto 0);
	signal dadoLeituraRAM : std_logic_vector(31 downto 0);
	
	alias opcode 			 : std_logic_vector(6 downto 0) is Instrucao( 6 downto 0);
	alias rd     			 : std_logic_vector(4 downto 0) is Instrucao(11 downto 7);
	alias funct3 			 : std_logic_vector(2 downto 0) is Instrucao(14 downto 12);
	alias rs1    			 : std_logic_vector(4 downto 0) is Instrucao(19 downto 15);
	alias rs2    			 : std_logic_vector(4 downto 0) is Instrucao(24 downto 20);
	alias funct7 			 : std_logic_vector(6 downto 0) is Instrucao(31 downto 25);
		
	signal sinaisControle : ctrl_t;

begin

-- MUX_PCSrc:			 
PCNext <= (saida_ULA and x"FFFFFFFE") when (JumpType=JT_JALR) else
			    PCTarget when (JumpType=JT_JAL or (Branch='1' and taken='1')) else
				 proxPC; -- se PCSrc for igual a "00" ou "11"

PC : entity work.genericRegister   generic map (larguraDados => 32)
			port map(   clock => clk, 
						clear => '0'
						enable => '1', 
						source => PCNext, 
						destination => Endereco);
						 
ROM : entity work.ROMMIPS
			port map( Endereco => Endereco, 
						 Dado => Instrucao);

-- incrementaPC:					 
proxPC <= std_logic_vector(unsigned(Endereco) + 4);

-- somador_PCTarget:				 
PCTarget <= STD_LOGIC_VECTOR(unsigned(Endereco) + unsigned(ImmExt));
						 
bancoReg : entity work.bancoReg
			port map( clk => clk, 
						 enderecoA => rs1, 
						 enderecoB => rs2, 
						 enderecoC => rd, 
						 dadoEscritaC => saida_MUX_ResultSrc, 
						 escreveC => sinaisControle.RegWrite, 
						 saidaA => saidaA_bancoReg, 
						 saidaB => saidaB_bancoReg);
						 
ULA32bits : entity work.ULA32bits generic map ( DATA_WIDTH => 32 )
			port map (
				select_function => ctrl.ALUCtrl,
				source_1        => srcA,
				source_2        => srcB,
				overflow        => alu_overflow,
				destination     => saida_ULA
			);
						 
-- MUX_ALUSrcA:
with sinaisControle.SrcA select				 
	saida_MUX_SrcA <= saidaA_bancoReg when SRC_A_RS1,
							Endereco        when SRC_A_PC,
							(others => '0') when SRC_A_ZERO;
						 
-- MUX_ALUSrcB:					 
saida_MUX_SrcB <= ImmExt when (sinaisControle.SrcB = '1') else saidaB_bancoReg;
		  
RAM : entity work.RAMMIPS
			port map( clk => clk,
						 Endereco => saida_ULA,
						 Dado_in => saidaB_bancoReg,
						 Dado_out => dadoLeituraRAM, 
						 we => sinaisControle.MemWrite);
						 
-- MUX_ResultSrc:
with sinaisControle.ResultSrc select
	saida_MUX_ResultSrc <= saida_ULA 		when RES_ALU,
								  dadoLeituraRAM  when RES_MEM,
								  proxPC 			when RES_PC4;

entradaPC <= saida_ULA when (PCSrc = "01") else
			    PCTarget when (PCSrc = "10") else
				 proxPC; -- se PCSrc for igual a "00" ou "11"
						 
extensor : entity work.immediateGen
			port map( instru => Instrucao(31 downto 7),
						 ImmSrc => sinaisControle.ImmSrc,
						 ImmExt => ImmExt);
			 
UC : entity work.unidadeControle
			port map( opcode => Instrucao(6 downto 0),
						 funct3 => funct3,
						 funct7 => funct7,
						 ctrl => sinaisControle);
						 
taken <= '1' when ( -- quando for 1, significa que o pulo do branch sera feito
          (sinaisControle.BranchOp = BR_EQ  and (saidaA_bancoReg =  saidaB_bancoReg)) or
          (sinaisControle.BranchOp = BR_NE  and (saidaA_bancoReg /= saidaB_bancoReg)) or
          (sinaisControle.BranchOp = BR_LT  and (signed(saidaA_bancoReg)  <  signed(saidaB_bancoReg))) or
          (sinaisControle.BranchOp = BR_GE  and (signed(saidaA_bancoReg)  >= signed(saidaB_bancoReg))) or
          (sinaisControle.BranchOp = BR_LTU and (unsigned(saidaA_bancoReg) <  unsigned(saidaB_bancoReg))) or
          (sinaisControle.BranchOp = BR_GEU and (unsigned(saidaA_bancoReg) >= unsigned(saidaB_bancoReg)))
        ) else '0';

end architecture;
			 

-- ainda nao alterado:

-- HEX e LED
						 
-- MUXHEXeLED:
EntradaHEXeLED <= dados when (sel = "01") else
					   dados when (sel = "10") else
						dados when (sel = "11") else
					   Endereco;
					  
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