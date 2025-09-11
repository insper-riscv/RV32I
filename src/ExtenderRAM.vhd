library ieee;
use ieee.std_logic_1164.all;
use work.rv32i_ctrl_consts.all;

entity ExtenderRAM is 
  port(
    signalIn  : in std_logic_vector(31 downto 0);
	 opExRAM   : in std_logic_vector(2 downto 0);
	 signalOut : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behaviour of ExtenderRAM is

  -- add necessary signals here
  
begin

process(signalIn, opExRAM)
begin

  if    (opExRAM = OPEXRAM_LW) then signalOut <= signalIn;                                                  -- LW: out = in[31:0]
  elsif (opExRAM = OPEXRAM_LH) then signalOut <= (31 downto 16 => signalIn(15)) & signalIn(15 downto 0);    -- LH: out = sext(in[15:0])
  elsif (opExRAM = OPEXRAM_LHU) then signalOut <= (31 downto 16 => '0') & signalIn(15 downto 0);            -- LHU: out = zext(in[15:0])
  elsif (opExRAM = OPEXRAM_LB) then signalOut <= (31 downto 8 => signalIn(7)) & signalIn(7 downto 0);		   -- LB: out = sext(in[7:0])							  
  elsif (opExRAM = OPEXRAM_LBU) then signalOut <= (31 downto 8 => '0') & signalIn(7 downto 0);              -- LBU: out = zext(in[7:0])
  
  else signalOut <= "00000000000000000000000000000000"; -- ERROR
  end if;

end process;


end architecture;