-- Projeto: Relógio Digital
-- Disciplina: Design de Computadores
-- Instituição: Insper – Instituto de Ensino e Pesquisa
-- Semestre: 2024/2
-- Autores: Lucas Lima e Luiz Eduardo Pini
-- Descrição: Este projeto implementa um relógio digital em VHDL utilizando um driver VGA para exibir o horário, 
-- com funcionalidades de ajuste de hora, alarme e aceleração de tempo. Utiliza arquitetura registrador-memória e 
-- é controlado por um processador personalizado.

library ieee;
use ieee.std_logic_1164.all;

entity testeBancoReg is
  generic ( 
        simulacao : boolean := FALSE -- para gravar na placa, altere de TRUE para FALSE
  );
  port   (
    CLOCK_50 : in std_logic;
	 LEDR  : out std_logic_vector(9 downto 0);
	 HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);
	 KEY: in std_logic_vector(3 downto 0);
    SW: in std_logic_vector(9 downto 0);
	 FPGA_RESET_N : in std_logic
  );
end entity;


architecture arquitetura of testeBancoReg is

  signal CLK : std_logic;
  signal entradaDecoder0 : std_logic_vector(31 downto 0);
  signal entradaDecoder1 : std_logic_vector(31 downto 0);
  signal entradaDecoder2 : std_logic_vector(3 downto 0);
  signal entradaDecoder3 : std_logic_vector(3 downto 0);
  signal entradaDecoder4 : std_logic_vector(3 downto 0);
  
  signal dadoC : std_logic_vector(2 downto 0);
  signal endA, endB, endC : std_logic_vector(3 downto 0);

  
begin

edgeDetectorKey : entity work.edgeDetector
			port map (clk => CLOCK_50, entrada => NOT(FPGA_RESET_N), saida => CLK);
			

endA <= "00" & SW(1 downto 0);
endB <= "00" & SW(3 downto 2);
endC <= "00" & SW(5 downto 4);
dadoC <= SW(8 downto 6);				

DecoderDisplay0 :  entity work.conversorHex7Seg
        port map(dadoHex => entradaDecoder0(3 downto 0),
                 saida7seg => HEX2);

DecoderDisplay1 :  entity work.conversorHex7Seg
		  port map(dadoHex => entradaDecoder1(3 downto 0),
					  saida7seg => HEX3);
				
DecoderDisplay2 :  entity work.conversorHex7Seg
		  port map(dadoHex => "0" & dadoC,
					  saida7seg => HEX4);
					  
DecoderDisplay3 :  entity work.conversorHex7Seg
		  port map(dadoHex => endA,
					  saida7seg => HEX0);
					  
DecoderDisplay4 :  entity work.conversorHex7Seg
		  port map(dadoHex => endB,
					  saida7seg => HEX1);
					  
DecoderDisplay5 :  entity work.conversorHex7Seg
		  port map(dadoHex => endC,
					  saida7seg => HEX5);
					  
LEDR(0) <= SW(9);
LEDR(1) <= not(KEY(0));
LEDR(2) <= not(FPGA_RESET_N);
LEDR(3) <= CLOCK_50;
			
bancoRegistradores0 : entity work.bancoRegistradores 
	port map (
		clk            => CLK,
		clear 			=> not(KEY(0)),
	  enderecoA       =>  "0" & endA,
	  enderecoB       =>  "0" & endB,
	  enderecoC       =>  "0" & endC,
	  dadoEscritaC    =>  "00000000000000000000000000000" & dadoC,
	  escreveC        => SW(9),
	  saidaA          => entradaDecoder0,
	  saidaB          => entradaDecoder1
	);

	  
end architecture;