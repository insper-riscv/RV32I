library ieee;
use ieee.std_logic_1164.all;

entity genericMux3x1 is
  -- Total number of bits for the inputs and outputs
  generic ( dataWidth : natural := 32);
  port (
    inputA_MUX, inputB_MUX, inputC_MUX : in std_logic_vector((dataWidth-1) downto 0);
    selector_MUX : in std_logic_vector(1 downto 0);  -- 2-bit selector
    output_MUX : out std_logic_vector((dataWidth-1) downto 0)
  );
end entity;

architecture behavior of genericMux3x1 is
begin
  with selector_MUX select
    output_MUX <= inputA_MUX when "00",
                  inputB_MUX when "01",
                  inputC_MUX when "10",
                  (others => '0') when others; -- default case
end architecture;
