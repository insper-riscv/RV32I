library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity extendSigned is
  generic   (
    DATA_WIDTH  : natural :=  8;
    ADDR_WIDTH  : natural :=  8
  );

  port   (
    -- Input ports
	 entradaA : in std_logic_vector(31 downto 0);
	 entradaB : in std_logic_vector(31 downto 0);
	 controle : in std_logic_vector(1 downto 0);

    -- Output ports
    saidaA   : out std_logic_vector(32 downto 0);
	 saidaB   : out std_logic_vector(32 downto 0)
  );
end entity;


architecture arch_name of extendSigned is

  

begin

  -- Para instanciar, a atribuição de sinais (e generics) segue a ordem: (nomeSinalArquivoDefinicaoComponente => nomeSinalNesteArquivo)
  
  -- signed = controle <= '11'
  -- unsigned = controle <= '00'
  -- signed e unsigned <= '10'
  
  saidaA <= entradaA(31) & entradaA when controle = "11" else
            entradaA(31) & entradaA when controle = "10" else
            '0' & entradaA when controle = "00";
				
  saidaB <= entradaB(31) & entradaB when controle = "11" else
            '0' & entradaB when controle = "10" else
            '0' & entradaB when controle = "00";

end architecture;