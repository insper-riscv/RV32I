-- =============================================================================
-- Entity: GENERIC_REGISTER
-- Description:
--   Parameterizable D-type register with synchronous clear and enable inputs.
--   - On rising edge of the clock:
--       • If 'clear' is asserted, the register is reset to a uniform value:
--           CLEAR_VALUE = '0' → state <= (others => '0')
--           CLEAR_VALUE = '1' → state <= (others => '1')
--       • Else if 'enable' is asserted, the input data ('source') is loaded.
--   - The current state is continuously driven to the output ('destination').
--   - The register width and clear behavior are configurable via generics.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- -----------------------------------------------------------------------------
-- Entity Declaration
-- -----------------------------------------------------------------------------
entity GENERIC_REGISTER is
  generic (
    DATA_WIDTH  : natural := 32;        --! Width of the register
    CLEAR_VALUE : std_logic := '0'      --! Bit value to assign on clear
  );
  port (
    clock       : in  std_logic;                            --! Clock input
    clear       : in  std_logic;                            --! Synchronous clear
    enable      : in  std_logic;                            --! Load strobe
    source      : in  std_logic_vector(DATA_WIDTH-1 downto 0); --! Input data
    destination : out std_logic_vector(DATA_WIDTH-1 downto 0) --! Output data
  );
end entity GENERIC_REGISTER;

-- -----------------------------------------------------------------------------
-- Architecture Definition
-- -----------------------------------------------------------------------------
architecture RTL of GENERIC_REGISTER is
  signal state : std_logic_vector(DATA_WIDTH-1 downto 0); -- Internal register state
begin

  -- ===========================================================================
  -- Synchronous logic: clear has priority over enable
  -- ===========================================================================
  process (clock)
  begin
    if rising_edge(clock) then
      if clear = '1' then
        state <= (others => CLEAR_VALUE);  -- Clear register with uniform value
      elsif enable = '1' then
        state <= source;                   -- Load input value
      end if;
    end if;
  end process;

  -- ===========================================================================
  -- Output assignment
  -- ===========================================================================
  destination <= state;

end architecture RTL;
