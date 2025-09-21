library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

    entity andgate is
        Port (
            a : in  STD_LOGIC;
            b : in  STD_LOGIC;
            y : out STD_LOGIC
        );
    end andgate;

    architecture Behavioral of andgate is
    begin
        y <= a and b;
    end Behavioral;