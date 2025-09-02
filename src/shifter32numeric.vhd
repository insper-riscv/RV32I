library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shifter32 is
  port (
    A     : in  std_logic_vector(31 downto 0);
    shamt : in  std_logic_vector(4 downto 0);
    mode  : in  std_logic_vector(1 downto 0); -- "00"=SLL, "01"=SRL, "10"=SRA
    Y     : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of shifter32 is
  signal n : integer range 0 to 31;
begin
  n <= to_integer(unsigned(shamt));
  process(A, mode, n)
  begin
    case mode is
      when "00" => Y <= std_logic_vector(shift_left (unsigned(A), n)); -- SLL
      when "01" => Y <= std_logic_vector(shift_right(unsigned(A), n)); -- SRL
      when others => Y <= std_logic_vector(shift_right(signed(A), n)); -- "10": SRA
    end case;
  end process;
end architecture;
