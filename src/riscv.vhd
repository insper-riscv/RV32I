PC : entity work.registradorGenerico   generic map (larguraDados => 32)
			port map( DIN => saida_MUX_JR, 
						 DOUT => Endereco, 
						 ENABLE => '1', 
						 CLK => clk, 
						 RST => '0');