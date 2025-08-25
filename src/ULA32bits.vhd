library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;    -- Biblioteca IEEE para funções aritméticas

entity ULA32bits is
    generic ( larguraDados : natural := 1 );
    port (
      entradaA, entradaB: in STD_LOGIC_VECTOR(31 downto 0);
      op_ULA: in STD_LOGIC_VECTOR(3 downto 0);
		flagZero: out std_logic;
      resultado: out STD_LOGIC_VECTOR(31 downto 0)
    );
end entity;

architecture comportamento of ULA32bits is

		signal carryOUT0, carryOUT1, carryOUT2, carryOUT3, carryOUT4, carryOUT5, carryOUT6, carryOUT7 : std_logic;
		signal carryOUT8, carryOUT9, carryOUT10, carryOUT11, carryOUT12, carryOUT13, carryOUT14, carryOUT15 : std_logic;
		signal carryOUT16, carryOUT17, carryOUT18, carryOUT19, carryOUT20, carryOUT21, carryOUT22, carryOUT23 : std_logic;
		signal carryOUT24, carryOUT25, carryOUT26, carryOUT27, carryOUT28, carryOUT29, carryOUT30, carryOUT31 : std_logic;
		signal SLT_bit0, overflow : std_logic;
			
    begin

ULA_bit0: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(0), entradaB =>  entradaB(0),
                 SLT => SLT_bit0, carryIN => op_ULA(2), carryOUT => carryOUT0,
                 ultimoBit => '0',
					  saida => resultado(0));

ULA_bit1: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(1), entradaB =>  entradaB(1),
                 SLT => '0', carryIN => carryOUT0, carryOUT => carryOUT1,
                 ultimoBit => '0',	
					  saida => resultado(1));
					  
ULA_bit2: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(2), entradaB =>  entradaB(2),
                 SLT => '0', carryIN => carryOUT1, carryOUT => carryOUT2,
                 ultimoBit => '0',	
					  saida => resultado(2));

ULA_bit3: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(3), entradaB =>  entradaB(3),
                 SLT => '0', carryIN => carryOUT2, carryOUT => carryOUT3,
                 ultimoBit => '0',	
					  saida => resultado(3));			
			
ULA_bit4: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(4), entradaB =>  entradaB(4),
                 SLT => '0', carryIN => carryOUT3, carryOUT => carryOUT4,
                 ultimoBit => '0',	
					  saida => resultado(4));

ULA_bit5: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(5), entradaB =>  entradaB(5),
                 SLT => '0', carryIN => carryOUT4, carryOUT => carryOUT5,
                 ultimoBit => '0',	
					  saida => resultado(5));
					  
ULA_bit6: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(6), entradaB =>  entradaB(6),
                 SLT => '0', carryIN => carryOUT5, carryOUT => carryOUT6,
                 ultimoBit => '0',	
					  saida => resultado(6));

ULA_bit7: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(7), entradaB =>  entradaB(7),
                 SLT => '0', carryIN => carryOUT6, carryOUT => carryOUT7,
                 ultimoBit => '0',	
					  saida => resultado(7));	
				
ULA_bit8: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(8), entradaB =>  entradaB(8),
                 SLT => '0', carryIN => carryOUT7, carryOUT => carryOUT8,
                 ultimoBit => '0',	
					  saida => resultado(8));

ULA_bit9: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(9), entradaB =>  entradaB(9),
                 SLT => '0', carryIN => carryOUT8, carryOUT => carryOUT9,
                 ultimoBit => '0',	
					  saida => resultado(9));
					  
ULA_bit10: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(10), entradaB =>  entradaB(10),
                 SLT => '0', carryIN => carryOUT9, carryOUT => carryOUT10,
                 ultimoBit => '0',	
					  saida => resultado(10));

ULA_bit11: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(11), entradaB =>  entradaB(11),
                 SLT => '0', carryIN => carryOUT10, carryOUT => carryOUT11,
                 ultimoBit => '0',	
					  saida => resultado(11));		
					
ULA_bit12: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(12), entradaB =>  entradaB(12),
                 SLT => '0', carryIN => carryOUT11, carryOUT => carryOUT12,
                 ultimoBit => '0',	
					  saida => resultado(12));

ULA_bit13: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(13), entradaB =>  entradaB(13),
                 SLT => '0', carryIN => carryOUT12, carryOUT => carryOUT13,
                 ultimoBit => '0',	
					  saida => resultado(13));
					  
ULA_bit14: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(14), entradaB =>  entradaB(14),
                 SLT => '0', carryIN => carryOUT13, carryOUT => carryOUT14,
                 ultimoBit => '0',	
					  saida => resultado(14));

ULA_bit15: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(15), entradaB =>  entradaB(15),
                 SLT => '0', carryIN => carryOUT14, carryOUT => carryOUT15,
                 ultimoBit => '0',	
					  saida => resultado(15));			
			
ULA_bit16: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(16), entradaB =>  entradaB(16),
                 SLT => '0', carryIN => carryOUT15, carryOUT => carryOUT16,
                 ultimoBit => '0',	
					  saida => resultado(16));

ULA_bit17: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(17), entradaB =>  entradaB(17),
                 SLT => '0', carryIN => carryOUT16, carryOUT => carryOUT17,
                 ultimoBit => '0',	
					  saida => resultado(17));
					  
ULA_bit18: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(18), entradaB =>  entradaB(18),
                 SLT => '0', carryIN => carryOUT17, carryOUT => carryOUT18,
                 ultimoBit => '0',	
					  saida => resultado(18));

ULA_bit19: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(19), entradaB =>  entradaB(19),
                 SLT => '0', carryIN => carryOUT18, carryOUT => carryOUT19,
                 ultimoBit => '0',	
					  saida => resultado(19));	
				
ULA_bit20: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(20), entradaB =>  entradaB(20),
                 SLT => '0', carryIN => carryOUT19, carryOUT => carryOUT20,
                 ultimoBit => '0',	
					  saida => resultado(20));

ULA_bit21: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(21), entradaB =>  entradaB(21),
                 SLT => '0', carryIN => carryOUT20, carryOUT => carryOUT21,
                 ultimoBit => '0',	
					  saida => resultado(21));
					  
ULA_bit22: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(22), entradaB =>  entradaB(22),
                 SLT => '0', carryIN => carryOUT21, carryOUT => carryOUT22,
                 ultimoBit => '0',	
					  saida => resultado(22));

ULA_bit23: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(23), entradaB =>  entradaB(23),
                 SLT => '0', carryIN => carryOUT22, carryOUT => carryOUT23,
                 ultimoBit => '0',	
					  saida => resultado(23));	
					
ULA_bit24: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(24), entradaB =>  entradaB(24),
                 SLT => '0', carryIN => carryOUT23, carryOUT => carryOUT24,
                 ultimoBit => '0',	
					  saida => resultado(24));

ULA_bit25: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(25), entradaB =>  entradaB(25),
                 SLT => '0', carryIN => carryOUT24, carryOUT => carryOUT25,
                 ultimoBit => '0',	
					  saida => resultado(25));
					  
ULA_bit26: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(26), entradaB =>  entradaB(26),
                 SLT => '0', carryIN => carryOUT25, carryOUT => carryOUT26,
                 ultimoBit => '0',	
					  saida => resultado(26));

ULA_bit27: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(27), entradaB =>  entradaB(27),
                 SLT => '0', carryIN => carryOUT26, carryOUT => carryOUT27,
                 ultimoBit => '0',	
					  saida => resultado(27));			
			
ULA_bit28: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(28), entradaB =>  entradaB(28),
                 SLT => '0', carryIN => carryOUT27, carryOUT => carryOUT28,
                 ultimoBit => '0',	
					  saida => resultado(28));

ULA_bit29: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(29), entradaB =>  entradaB(29),
                 SLT => '0', carryIN => carryOUT28, carryOUT => carryOUT29,
                 ultimoBit => '0',	
					  saida => resultado(29));
					  
ULA_bit30: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(30), entradaB =>  entradaB(30),
                 SLT => '0', carryIN => carryOUT29, carryOUT => carryOUT30,
                 ultimoBit => '0',	
					  saida => resultado(30));

ULA_bit31: entity work.ULA1bit
        port map( op_ULA => op_ULA, entradaA => entradaA(31), entradaB =>  entradaB(31),
                 SLT => '0', carryIN => carryOUT30, carryOUT => carryOUT31,
                 ultimoBit => '1', overflow => overflow, SLT_bit0 => SLT_bit0,
					  saida => resultado(31));
					
flagZero <= not(resultado(0) OR	resultado(1) OR resultado(2) OR resultado(3) OR resultado(4) OR resultado(5) OR resultado(6) OR resultado(7) OR resultado(8) OR resultado(9) OR resultado(10) OR resultado(11) OR resultado(12) OR	resultado(13) OR resultado(14) OR resultado(15) OR resultado(16) OR	resultado(17) OR resultado(18) OR resultado(19) OR resultado(20) OR resultado(21) OR resultado(22) OR resultado(23) OR resultado(24) OR resultado(25) OR resultado(26) OR resultado(27) OR resultado(28) OR	resultado(29) OR resultado(30) OR resultado(31));

end architecture;