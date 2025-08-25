library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;          -- Biblioteca IEEE para funções aritméticas

entity somadorGenerico1bit is
    generic
    (
        larguraDados : natural := 1
    );
    port
    (
        entradaA, entradaB, carryIN: in STD_LOGIC;
        saida, carryOUT:  out STD_LOGIC
    );
end entity;

architecture comportamento of somadorGenerico1bit is
    begin
        saida <= (entradaA XOR entradaB) XOR carryIN;
		  carryOUT <= (entradaA AND entradaB) OR ((entradaA XOR entradaB) AND carryIN);
end architecture;