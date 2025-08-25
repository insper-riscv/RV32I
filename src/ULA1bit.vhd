library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;    -- Biblioteca IEEE para funções aritméticas

entity ULA1bit is
    generic ( larguraDados : natural := 1 );
    port (
      entradaA, entradaB: in STD_LOGIC;
		carryIN, SLT, ultimoBit: in STD_LOGIC;
      op_ULA: in STD_LOGIC_VECTOR(3 downto 0);
		carryOUT, overflow, SLT_bit0: out STD_LOGIC;
      saida: out STD_LOGIC
    );
end entity;

architecture comportamento of ULA1bit is

		signal inverteA, inverteB : std_logic;
		signal sinalA, sinalB : std_logic;
		signal res_OR, res_AND, res_SomaSub : std_logic;
	
    begin
	 
inverteA <= op_ULA(3);
inverteB <= op_ULA(2);
	 
MUX_A: entity work.muxGenerico2x1_1bit
        port map( entradaA_MUX => entradaA,
                 entradaB_MUX =>  not(entradaA),
                 seletor_MUX => inverteA,
                 saida_MUX => sinalA);
					  
MUX_B: entity work.muxGenerico2x1_1bit
        port map( entradaA_MUX => entradaB,
                 entradaB_MUX =>  not(entradaB),
                 seletor_MUX => inverteB,
                 saida_MUX => sinalB);
	 
somador: entity work.somadorGenerico1bit  generic map (larguraDados => 1)
        port map( entradaA => sinalA, 
						entradaB => sinalB, 
						carryIN => carryIN, 
						saida => res_SomaSub, 
						carryOUT => carryOUT);
		  
res_OR <= sinalA OR sinalB;

res_AND <= sinalA AND sinalB;

MUX_Res: entity work.muxGenerico4x1_1bit generic map (larguraDados => 1)
        port map( entradaA_MUX => res_AND,
                 entradaB_MUX =>  res_OR,
					  entradaC_MUX => res_SomaSub,
					  entradaD_MUX => SLT,
                 seletor_MUX => op_ULA(1 downto 0),
                 saida_MUX => saida);
					  
overflow <= ultimoBit AND (carryIN XOR carryOUT);

SLT_bit0 <= overflow XOR res_SomaSub;
	 
end architecture;