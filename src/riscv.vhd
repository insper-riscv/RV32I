library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips is
  generic   (
    DATA_WIDTH  : natural :=  32;
    ADDR_WIDTH  : natural :=  32
  );

  port   (
    clk     : in  std_logic;
    dataOUT : out  std_logic_vector(31 downto 0)
  );
end entity;


architecture arch_name of mips is
		
	signal proxPC         : std_logic_vector(31 downto 0);
	signal Endereco       : std_logic_vector(31 downto 0);
	signal Instrucao      : std_logic_vector(31 downto 0);
	
	signal PCTarget   	 : std_logic_vector(31 downto 0);
	signal entradaPC   	 : std_logic_vector(31 downto 0);
	signal ImmExt     	 : std_logic_vector(31 downto 0);
	signal saida_MUX_ResultSrc : std_logic_vector(31 downto 0);
	signal entradaA_ULA   : std_logic_vector(31 downto 0);
	signal saidaB_bancoReg   : std_logic_vector(31 downto 0);
	signal saida_MUX_SrcB : std_logic_vector(31 downto 0);
	signal ALUControl : std_logic_vector(3 downto 0);
	signal flagZero       : std_logic;
	signal saida_ULA      : std_logic_vector(31 downto 0);
	signal dadoLeituraRAM : std_logic_vector(31 downto 0);
	signal saida_MUX_ResultSrc : std_logic_vector(31 downto 0);
	
	alias opcode 			 : std_logic_vector(6 downto 0) is Instrucao(6 downto 0);
	alias rd     			 : std_logic_vector(4 downto 0) is Instrucao(11 downto 7);
	alias funct3 			 : std_logic_vector(2 downto 0) is Instrucao(14 downto 12);
	alias rs1    			 : std_logic_vector(4 downto 0) is Instrucao(19 downto 15);
	alias rs2    			 : std_logic_vector(4 downto 0) is Instrucao(24 downto 20);
	alias funct7 			 : std_logic_vector(6 downto 0) is Instrucao(31 downto 25);
	
	signal sinaisControle : std_logic_vector(11 downto 0);
	signal RegWrite   	 : std_logic;
	signal ResultSrc  		 : std_logic;
	signal MemWrite  		 : std_logic;
	signal ALUControl    : std_logic;
	signal ALUSrc : std_logic;
	signal ImmSrc : std_logic;
	signal PCSrc  : std_logic;

begin

-- MUX_PCSrc:				 
entradaPC <= PCTarget when (PCSrc = '1') else proxPC;

entradaPC <= proxPC when (PCSrc = "00") else 
					  saida_ULA when (PCSrc = "01") else
					  PCTarget when (PCSrc = "10") else
					  entradaD_MUX;

PC : entity work.registradorGenerico   generic map (larguraDados => 32)
			port map( DIN => entradaPC, 
						 DOUT => Endereco, 
						 ENABLE => '1', 
						 CLK => clk, 
						 RST => '0');
						 
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
						 escreveC => RegWrite, 
						 saidaA => entradaA_ULA, 
						 saidaB => saidaB_bancoReg);
						 
ULA_32bits : entity work.ULA32bits
			port map( entradaA => entradaA_ULA,
						 entradaB => saida_MUX_SrcB,
						 op_ULA => ALUControl,
						 flagZero => flagZero,
						 resultado => saida_ULA);
						 
-- MUX_ALUSrc:					 
saida_MUX_SrcB <= ImmExt when (ALUSrc = '1') else saidaB_bancoReg;
		  
RAM : entity work.RAMMIPS
			port map( clk => clk,
						 Endereco => saida_ULA,
						 Dado_in => saidaB_bancoReg,
						 Dado_out => dadoLeituraRAM, 
						 we => MemWrite, 
						 re => habLeituraMEM, 
						 habilita => habMEM);
						 
-- MUX_ResultSrc:
saida_MUX_ResultSrc <= dadoLeituraRAM when (ResultSrc = '1') else saida_ULA;
						 
extensor : entity work.immediateGen
			port map( instru => Instrucao(31 downto 7),
						 ImmSrc => ImmSrc(1 downto 0),
						 ImmExt => ImmExt(31 downto 0));
			 
UC : entity work.unidadeControle
			port map( opcode => Instrucao(6 downto 0),
						 funct3 => funct3,
						 funct7 => funct7,
						 saida => sinaisControle);


RegWrite 	<= sinaisControle(12);
ResultSrc 	<= sinaisControle(11 downto 10);
MemWrite 	<= sinaisControle(9);
ALUControl 	<= sinaisControle(8 downto 5);
ALUSrc 		<= sinaisControle(4);
ImmSrc 		<= sinaisControle(3 downto 2);
Branch 		<= sinaisControle(1);
Jump 			<= sinaisControle(0);

PCSrc <= (Branch and Zero) or Jump;
			 

-- ainda nao alterado:			 

			 
dataOUT <= saida_ULA;

end architecture;