library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_gen_3way is
  port (
    clk_in : in  std_logic;  -- clock de base (entrada)
    reset  : in  std_logic;  -- reset ASSÍNCRONO ativo em '1'
    clk0   : out std_logic;  -- pulse 0 
    clk1   : out std_logic;  -- pulse 1
    clk2   : out std_logic   -- pulse 2
  );
end entity clk_gen_3way;

architecture rtl of clk_gen_3way is
  signal cnt : unsigned(1 downto 0) := (others => '0');
begin

  -- Contador mod-3 atualizado na borda de descida; reset assíncrono
  process(clk_in, reset)
    variable next_cnt : unsigned(1 downto 0);
  begin
    if reset = '1' then
      cnt <= (others => '0');
    elsif falling_edge(clk_in) then
      if cnt = to_unsigned(2, cnt'length) then
        next_cnt := (others => '0');
      else
        next_cnt := cnt + 1;
      end if;
      cnt <= next_cnt;
    end if;
  end process;

  -- Saídas: ativas apenas durante a fase baixa de clk_in e quando cnt corresponde
  clk0 <= '0' when reset = '1' else
        '1' when (clk_in = '1' and cnt = to_unsigned(0, cnt'length)) else '0';

  clk1 <= '0' when reset = '1' else
        '1' when (clk_in = '1' and cnt = to_unsigned(1, cnt'length)) else '0';

  clk2 <= '0' when reset = '1' else
        '1' when (clk_in = '1' and cnt = to_unsigned(2, cnt'length)) else '0';

end architecture rtl;
