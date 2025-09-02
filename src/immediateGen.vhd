library ieee;
use ieee.std_logic_1164.all;

entity immediateGen is
    port
    (
        instru : in std_logic_vector(25 downto 0);
		  ImmSRC : in std_logic_vector(1 downto 0);
        ImmExt: out std_logic_vector(31 downto 0)
    );
end entity;

architecture comportamento of immediateGen is
begin

extensorSinal_tipoI : entity work.extendeSinalGenerico   generic map (larguraDadoEntrada => 16, larguraDadoSaida => 32)
			port map( estendeSinal_IN => instru(31 downto 20), 
						 estendeSinal_OUT => sinalExtendidoI);
						 
sinalExtendidoI <= (larguraDadoSaida-1 downto larguraDadoEntrada => estendeSinal_IN(larguraDadoEntrada-1) ) & estendeSinal_IN;
							 
extensorSinal_tipoS : entity work.extendeSinalGenerico   generic map (larguraDadoEntrada => 16, larguraDadoSaida => 32)
			port map( estendeSinal_IN => (instru(31 downto 25) & instru(11 downto 7)), 
						 estendeSinal_OUT => sinalExtendidoS);		 
						 
extensorSinal_tipoB : entity work.extendeSinalGenerico   generic map (larguraDadoEntrada => 16, larguraDadoSaida => 32)
			port map( estendeSinal_IN => (instru(31) & instru(7) & instr(30 downto 25) & instr(11 downto 8) & '0'), 
						 estendeSinal_OUT => sinalExtendidoB);
						 
-- colocar extensor pra U e J
						
					
sinalExtendido	<= sinalExtendidoI when (ImmScr = "00") else
						sinalExtendidoS when (ImmScr = "01") else
						sinalExtendidoB when (ImmScr = "10") else
						-- adicionar pra U e J (ImmScr = "11")

end architecture;