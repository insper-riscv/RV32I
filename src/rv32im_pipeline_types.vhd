library ieee;
use ieee.std_logic_1164.all;

package rv32im_pipeline_types is

  -- Common widths for RV32IM pipeline signals.
  subtype word_t    is std_logic_vector(31 downto 0);
  subtype reg_t     is std_logic_vector(4 downto 0);
  subtype opalu_t   is std_logic_vector(4 downto 0);
  subtype opeximm_t is std_logic_vector(2 downto 0);
  subtype opexram_t is std_logic_vector(2 downto 0);
  subtype wbsel_t   is std_logic_vector(1 downto 0);
  subtype mask4_t   is std_logic_vector(3 downto 0);

end package rv32im_pipeline_types;
