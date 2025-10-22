library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FlipFlop is
    port (
        clock       : in  std_logic;
        clear       : in  std_logic := '1';
        enable      : in  std_logic := '0';
        source      : in  std_logic := '0';
        destination : out std_logic := '0'
    );
end entity;

architecture RTL of FlipFlop is
begin
    process(clock, clear)
    begin
        if clear = '1' then
            destination <= '0';
        elsif rising_edge(clock) then
            if enable = '1' then
                destination <= source;
            end if;
        end if;
    end process;
end architecture;