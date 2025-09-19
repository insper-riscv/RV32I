library ieee;
use ieee.std_logic_1164.all;

entity genericMux2x1 is
  -- Total number of bits for the inputs and outputs
  generic ( dataWidth : natural := 32);
  port (
    inputA_MUX, inputB_MUX : in std_logic_vector((dataWidth-1) downto 0);
    selector_MUX : in std_logic;
    output_MUX : out std_logic_vector((dataWidth-1) downto 0)
  );
end entity;

architecture behavior of genericMux2x1 is
  begin
    output_MUX <= inputB_MUX when (selector_MUX = '1') else inputA_MUX;
end architecture;
