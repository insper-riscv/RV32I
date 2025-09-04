library ieee;
use ieee.std_logic_1164.all;

entity testeRAM is
  generic ( 
        simulacao : boolean := FALSE -- para gravar na placa, altere de TRUE para FALSE
  );
  port   (
    CLOCK_50 : in std_logic;
	 LEDR  : out std_logic_vector(9 downto 0);
	 HEX0, HEX2, HEX4 : out std_logic_vector(6 downto 0);
	 KEY: in std_logic_vector(3 downto 0);
    SW: in std_logic_vector(9 downto 0);
	 FPGA_RESET_N : in std_logic
  );
end entity;


architecture arquitetura of testeRAM is

  signal CLK : std_logic;
  
  signal addr : std_logic_vector(3 downto 0);
  signal data_in : std_logic_vector(3 downto 0);
  signal write_enable, read_enable, enable : std_logic;
  
  signal data_out : std_logic_vector(31 downto 0);

begin

  addr <= SW(3 downto 0);
  data_in <= SW(7 downto 4);
  write_enable <= SW(8);
  read_enable <= SW(9);
  enable <= KEY(3);
  
  LEDR(0) <= enable;
  LEDR(8) <= write_enable;
  LEDR(9) <= read_enable;

edgeDetectorKey : entity work.edgeDetector
			port map (clk => CLOCK_50, entrada => NOT(KEY(0)), saida => CLK);
					
LEDR(4) <= CLK;
LEDR(3) <= NOT(KEY(0));
				
				
DecoderDisplay0 :  entity work.conversorHex7Seg
        port map(dadoHex => addr,
                 saida7seg => HEX0);
				
DecoderDisplay2 :  entity work.conversorHex7Seg
		  port map(dadoHex => data_in,
					  saida7seg => HEX2);
					  
DecoderDisplay4 :  entity work.conversorHex7Seg
		  port map(dadoHex => data_out(3 downto 0),
					  saida7seg => HEX4);
			

		
			
RAM : entity work.RAM_RISCV 
	port map (
	  clock        => CLK,
	  addr 		   => "0000000000000000000000000000" & addr,
	  data_in      => "0000000000000000000000000000" & data_in,
	  data_out     => data_out,
	  we           => write_enable,
	  re           => read_enable,
	  enable       => enable
	);

	  
end architecture;