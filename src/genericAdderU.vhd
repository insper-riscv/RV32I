library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;          -- IEEE library for arithmetic functions

entity genericAdderU is
    generic
    (
        dataWidth : natural := 32
    );
    port
    (
        inputA, inputB : in STD_LOGIC_VECTOR((dataWidth-1) downto 0);
        output : out STD_LOGIC_VECTOR((dataWidth-1) downto 0)
    );
end entity;

architecture behavior of genericAdderU is
begin
    output <= std_logic_vector(
                  signed(inputA) + signed(resize(unsigned(inputB), dataWidth))
              );
end architecture;
