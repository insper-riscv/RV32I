library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_consts.all;

entity ExtenderRAM is 
  port(
    signalIn  : in  std_logic_vector(31 downto 0);
    opExRAM   : in  std_logic_vector(2 downto 0);
    EA        : in  std_logic_vector(1 downto 0);
    signalOut : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behaviour of ExtenderRAM is
begin

process(signalIn, opExRAM, EA)
  variable byteVal  : std_logic_vector(7 downto 0);
  variable halfVal  : std_logic_vector(15 downto 0);
begin
  case opExRAM is
    when OPEXRAM_LW =>
      signalOut <= signalIn;

    when OPEXRAM_LH =>
      if EA(1) = '0' then
        halfVal := signalIn(15 downto 0);
      else
        halfVal := signalIn(31 downto 16);
      end if;
      signalOut <= (31 downto 16 => halfVal(15)) & halfVal;

    when OPEXRAM_LHU =>
      if EA(1) = '0' then
        halfVal := signalIn(15 downto 0);
      else
        halfVal := signalIn(31 downto 16);
      end if;
      signalOut <= (31 downto 16 => '0') & halfVal;

    when OPEXRAM_LB =>
      case EA is
        when "00" => byteVal := signalIn(7 downto 0);
        when "01" => byteVal := signalIn(15 downto 8);
        when "10" => byteVal := signalIn(23 downto 16);
        when others => byteVal := signalIn(31 downto 24);
      end case;
      signalOut <= (31 downto 8 => byteVal(7)) & byteVal;

    when OPEXRAM_LBU =>
      case EA is
        when "00" => byteVal := signalIn(7 downto 0);
        when "01" => byteVal := signalIn(15 downto 8);
        when "10" => byteVal := signalIn(23 downto 16);
        when others => byteVal := signalIn(31 downto 24);
      end case;
      signalOut <= (31 downto 8 => '0') & byteVal;

    when others =>
      signalOut <= (others => '0');
  end case;
end process;

end architecture;
