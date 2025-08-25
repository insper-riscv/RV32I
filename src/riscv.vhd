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

MUX_entradaPC :  entity work.muxGenerico2x1 generic map (larguraDados => 32)
			port map( entradaA_MUX => proxPC,
						 entradaB_MUX => PCTarget,
						 seletor_MUX => sel_MUX_entradaPC,
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
						 entradaB => sinalExtendido, 
						 saida => PCTarget);
						 
bancoReg : entity work.bancoReg
			port map( clk => clk, 
						 enderecoA => rs1, 
						 enderecoB => rs2, 
						 enderecoC => rd, 
						 dadoEscritaC => saida_MUX_ULA_MEM, 
						 escreveC => hab_escritaC, 
						 saidaA => entradaA_ULA, 
						 saidaB => saidaB_bancoReg);
						 
ULA_32bits : entity work.ULA32bits
			port map( entradaA => entradaA_ULA,
						 entradaB => saida_MUX_SrcB,
						 op_ULA => op_ULA,
						 flagZero => flagZero,
						 resultado => saida_ULA);
						 
MUX_SrcB :  entity work.muxGenerico2x1 generic map (larguraDados => 32)
			port map( entradaA_MUX => saidaB_bancoReg,
						 entradaB_MUX =>  sinalExtendido,
						 seletor_MUX => sel_MUX_SrcB,
						 saida_MUX => saida_MUX_SrcB);
		  
RAM : entity work.RAMMIPS
			port map( clk => clk,
						 Endereco => saida_ULA,
						 Dado_in => saidaB_bancoReg,
						 Dado_out => dadoLeituraRAM, 
						 we => habEscritaMEM, 
						 re => habLeituraMEM, 
						 habilita => habMEM);
						 
MUX_ULA_MEM :  entity work.muxGenerico4x1 generic map (larguraDados => 32)
			port map( entradaA_MUX => saida_ULA,
						 entradaB_MUX => dadoLeituraRAM,
--						 entradaC_MUX => entradaMUX_BEQ,
--						 entradaD_MUX => "00000000000000000000000000000000",
						 seletor_MUX => sel_MUX_ULA_MEM,
						 saida_MUX => saida_MUX_ULA_MEM);
						 
extensorSinal : entity work.estendeSinalGenerico   generic map (larguraDadoEntrada => 16, larguraDadoSaida => 32)
			port map( estendeSinal_IN => Instrucao(31 downto 7), 
						 estendeSinal_OUT => sinalExtendido);
			 
UC : entity work.unidadeControle
			port map( opcode => Instrucao(31 downto 7),
						 saida => sinaisControle);
			 

			 
			 
			 
			 
			 
			 
			 
			 
MUX_BEQ :  entity work.muxGenerico2x1 generic map (larguraDados => 32)
			port map( entradaA_MUX => proxPC,
						 entradaB_MUX =>  entradaMUX_BEQ,
						 seletor_MUX => sel_MUX_BEQ,
						 saida_MUX => entradaA_MUX_proxInstru);
					  

					  
decoderULA : entity work.decoderULA
			port map( opcode => opcode, 
						 funct => funct, 
						 tipo_R => tipo_R, 
						 op_ULA => op_ULA);
					  
sel_MUX_BEQ <= (flagZero AND BEQ) OR (not(flagZero) AND BNE);
saidaShift2 <= sinalExtendido(29 downto 0) & "00";
entradaB_MUX_proxInstru <= proxPC(31 downto 28) & Instrucao(25 downto 0) & "00";

BNE <= sinaisControle(11);
sel_MUX_PC_JMPeBEQ <= sinaisControle(10);
sel_MUX_Rt_Rd <= sinaisControle(9 downto 8);
hab_escritaC <= sinaisControle(7);
sel_MUX_Rt_Imed <= sinaisControle(6);
tipo_R <= sinaisControle(5);
sel_MUX_ULA_MEM <= sinaisControle(4 downto 3);
BEQ <= sinaisControle(2);
habLeituraMEM <= sinaisControle(1);		 
habEscritaMEM <= sinaisControle(0);
			 
dataOUT <= saida_ULA;

end architecture;