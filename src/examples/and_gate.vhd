-- This file is public domain, it can be freely copied without restrictions.
-- SPDX-License-Identifier: CC0-1.0

library ieee;
use ieee.std_logic_1164.all;

entity and_gate is
    port (
        source_a, source_b: in std_logic;
        ouput : out std_logic
    );
end entity;

architecture rtl of and_gate is

begin
    ouput <= source_a and source_b;  
end architecture;
