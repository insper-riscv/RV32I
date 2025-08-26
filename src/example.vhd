-- This file is public domain, it can be freely copied without restrictions.
-- SPDX-License-Identifier: CC0-1.0

library ieee;
use ieee.std_logic_1164.all;

entity my_design is
    port (
        clk : in std_logic
    );
end entity;

architecture rtl of my_design is
    signal my_signal_1 : std_logic;
    signal my_signal_2 : std_logic;
begin
    -- Atribuições constantes
    my_signal_1 <= 'X';  -- 'X' = unknown (equivalente a 1'bx)
    my_signal_2 <= '0';
end architecture;
