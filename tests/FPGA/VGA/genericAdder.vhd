library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;          -- IEEE library for arithmetic functions

entity genericAdder is
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

architecture behavior of genericAdder is
begin
    output <= STD_LOGIC_VECTOR(unsigned(inputA) + unsigned(inputB));
end architecture;
