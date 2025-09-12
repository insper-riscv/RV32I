library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Blinky is
  port (
    clk  : in  std_logic;       -- 50 MHz
    led  : out std_logic
  );
end entity;

architecture rtl of Blinky is
  constant HALF_PERIOD : natural := 25000000;  -- 0.5 s at 50 MHz
  signal cnt   : unsigned(25 downto 0) := (others => '0');  -- 26 bits > 25e6
  signal led_r : std_logic := '0';
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if cnt = to_unsigned(HALF_PERIOD-1, cnt'length) then
        cnt   <= (others => '0');
        led_r <= not led_r;  -- toggle every 0.5 s → 1 Hz blink
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;

  led <= led_r;
end architecture;
