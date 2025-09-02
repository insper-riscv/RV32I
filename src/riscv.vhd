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
	
	signal saida_MUX_bancoReg : std_logic_vector(4 downto 0);
	signal entradaA_ULA   : std_logic_vector(31 downto 0);
	signal saida_ULA      : std_logic_vector(31 downto 0);
	signal sinalExtendido : std_logic_vector(31 downto 0);
	signal saidaShift2    : std_logic_vector(31 downto 0);
	signal saidaB_bancoReg : std_logic_vector(31 downto 0);
	signal saida_MUXRtImed : std_logic_vector(31 downto 0);
	signal saida_MUX_ULA_MEM : std_logic_vector(31 downto 0);
	signal entradaMUX_BEQ : std_logic_vector(31 downto 0);
	signal entradaA_MUX_proxInstru : std_logic_vector(31 downto 0);
   signal entradaB_MUX_proxInstru : std_logic_vector(31 downto 0);
	signal dadoLeituraRAM : std_logic_vector(31 downto 0);
	
	signal proxPC         : std_logic_vector(31 downto 0);
	signal Endereco       : std_logic_vector(31 downto 0);
	signal proxInstru     : std_logic_vector(31 downto 0);
	signal Instrucao      : std_logic_vector(31 downto 0);
	
	alias opcode 			 : std_logic_vector(6 downto 0) is Instrucao(6 downto 0);
	alias rd     			 : std_logic_vector(4 downto 0) is Instrucao(11 downto 7);
	alias funct3 			 : std_logic_vector(2 downto 0) is Instrucao(14 downto 12);
	alias rs1    			 : std_logic_vector(4 downto 0) is Instrucao(19 downto 15);
	alias rs2    			 : std_logic_vector(4 downto 0) is Instrucao(24 downto 20);
	alias funct7 			 : std_logic_vector(6 downto 0) is Instrucao(31 downto 25);
	
	signal op_ULA         : std_logic_vector(3 downto 0);
   signal flagZero       : std_logic;
	
	signal sinaisControle : std_logic_vector(11 downto 0);
	signal habEscritaMEM  : std_logic;
	signal habLeituraMEM  : std_logic;
	signal hab_escritaC   : std_logic;
	signal BEQ            : std_logic;
	signal BNE            : std_logic;
	signal tipo_R         : std_logic;
	signal sel_MUX_Rt_Rd  : std_logic_vector(1 downto 0);
	signal sel_MUX_Rt_Imed : std_logic;
	signal sel_MUX_ULA_MEM : std_logic_vector(1 downto 0);
	signal sel_MUX_BEQ    : std_logic;
	signal sel_MUX_PC_JMPeBEQ : std_logic;
	signal habMEM : std_logic;

begin

MUX_PCSrc :  entity work.muxGenerico2x1 generic map (larguraDados => 32)
			port map( entradaA_MUX => proxPC,
						 entradaB_MUX => PCTarget,
						 seletor_MUX => PCSrc,
						 saida_MUX => entradaPC);

PC : entity work.registradorGenerico   generic map (larguraDados => 32)
			port map( DIN => entradaPC, 
						 DOUT => Endereco, 
						 ENABLE => '1', 
						 CLK => clk, 
						 RST => '0');
						 
ROM : entity work.ROMMIPS
			port map( Endereco => Endereco, 
						 Dado => Instrucao);

incrementaPC :  entity work.somaConstante  generic map (larguraDados => 32, constante => 4)
			port map( entrada => Endereco, 
						 saida => proxPC);
		  
somador_PCTarget :  entity work.somadorGenerico  generic map (larguraDados => 32)
			port map( entradaA => Endereco, 
						 entradaB => ImmExt, 
						 saida => PCTarget);
						 
bancoReg : entity work.bancoReg
			port map( clk => clk, 
						 enderecoA => rs1, 
						 enderecoB => rs2, 
						 enderecoC => rd, 
						 dadoEscritaC => saida_MUX_ULA_MEM, 
						 escreveC => RegWrite, 
						 saidaA => entradaA_ULA, 
						 saidaB => saidaB_bancoReg);
						 
ULA_32bits : entity work.ULA32bits
			port map( entradaA => entradaA_ULA,
						 entradaB => saida_MUX_SrcB,
						 op_ULA => ALUControl,
						 flagZero => flagZero,
						 resultado => saida_ULA);
						 
MUX_ALUSrc :  entity work.muxGenerico2x1 generic map (larguraDados => 32)
			port map( entradaA_MUX => saidaB_bancoReg,
						 entradaB_MUX =>  ImmExt,
						 seletor_MUX => ALUSrc,
						 saida_MUX => saida_MUX_SrcB);
		  
RAM : entity work.RAMMIPS
			port map( clk => clk,
						 Endereco => saida_ULA,
						 Dado_in => saidaB_bancoReg,
						 Dado_out => dadoLeituraRAM, 
						 we => MemWrite, 
						 re => habLeituraMEM, 
						 habilita => habMEM);
						 
MUX_ResultSrc :  entity work.muxGenerico4x1 generic map (larguraDados => 32)
			port map( entradaA_MUX => saida_ULA,
						 entradaB_MUX => dadoLeituraRAM,
						 seletor_MUX => ResultSrc,
						 saida_MUX => saida_MUX_ULA_MEM);
						 
extensor : entity work.immediateGen
			port map( instru => Instrucao(31 downto 7),
						 ImmSrc => ImmSrc(1 downto 0),
						 ImmExt => ImmExt(31 downto 0));
			 
UC : entity work.unidadeControle
			port map( opcode => Instrucao(6 downto 0),
						 saida => sinaisControle);

RegWrite 	<= sinaisControle(11);
ResultSrc 	<= sinaisControle(10 downto 9);
MemWrite 	<= sinaisControle(8);
ALUControl 	<= sinaisControle(7 downto 5);
ALUSrc 		<= sinaisControle(4);
ImmSrc 		<= sinaisControle(3 downto 2);
PCSrc 		<= sinaisControle(1);
NOP 			<= sinaisControle(0);
			 

-- ainda nao alterado:			 

					  
decoderULA : entity work.decoderULA
			port map( opcode => opcode, 
						 funct => funct, 
						 tipo_R => tipo_R, 
						 op_ULA => op_ULA);
					  
sel_MUX_BEQ <= (flagZero AND BEQ) OR (not(flagZero) AND BNE);
saidaShift2 <= sinalExtendido(29 downto 0) & "00";
entradaB_MUX_proxInstru <= proxPC(31 downto 28) & Instrucao(25 downto 0) & "00";


			 
dataOUT <= saida_ULA;

end architecture;