library IEEE;
use ieee.std_logic_1164.all;

entity conversorHex7Seg is
    port
    (
        -- Input ports
        dadoHex : in  std_logic_vector(7 downto 0);
        apaga   : in  std_logic := '0';
        negativo : in  std_logic := '0';
        overFlow : in  std_logic := '0';
        -- Output ports
        saida7seg : out std_logic_vector(6 downto 0)  -- := (others => '1')
    );
end entity;

architecture comportamento of conversorHex7Seg is
   --
   --       0
   --      ---
   --     |   |
   --    5|   |1
   --     | 6 |
   --      ---
   --     |   |
   --    4|   |2
   --     |   |
   --      ---
   --       3
   --
    signal rascSaida7seg: std_logic_vector(6 downto 0);
begin
    rascSaida7seg <=    "1000000" when dadoHex="00000000" else ---0
                            "1111001" when dadoHex="00000001" else ---1
                            "0100100" when dadoHex="00000010" else ---2
                            "0110000" when dadoHex="00000011" else ---3
                            "0011001" when dadoHex="00000100" else ---4
                            "0010010" when dadoHex="00000101" else ---5
                            "0000010" when dadoHex="00000110" else ---6
                            "1111000" when dadoHex="00000111" else ---7
                            "0000000" when dadoHex="00001000" else ---8
                            "0010000" when dadoHex="00001001" else ---9
                            "0001000" when dadoHex="00001010" else ---A
                            "0000011" when dadoHex="00001011" else ---B
                            "1000110" when dadoHex="00001100" else ---C
                            "0100001" when dadoHex="00001101" else ---D
                            "0000110" when dadoHex="00001110" else ---E
                            "0001110" when dadoHex="00001111" else ---F
									 "0001001" when dadoHex="01101000" else ---h
									 "0000110" when dadoHex="01100101" else ---e
									 "1000111" when dadoHex="01101100" else ---l
									 "1000000" when dadoHex="01101111" else ---o
									 "1010101" when dadoHex="01110111" else ---w
									 "1001110" when dadoHex="01110010" else ---r
									 "1001110" when dadoHex="01100100" else ---d
                            "1111111"; -- Apaga todos segmentos.

    saida7seg <=     "1100010" when (overFlow='1') else
                            "1111111" when (apaga='1' and negativo='0') else
                            "0111111" when (apaga='0' and negativo='1') else
                            rascSaida7seg;
end architecture;