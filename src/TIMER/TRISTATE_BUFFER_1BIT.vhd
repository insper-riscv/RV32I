-- =============================================================================
-- Entity: TRISTATE_BUFFER_1BIT
-- Description: 1-bit tri-state buffer. Drives the output with the input value
--              when enabled, or sets it to high-impedance ('Z') when disabled.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library WORK;

-- -----------------------------------------------------------------------------
-- Entity Declaration
-- -----------------------------------------------------------------------------
entity TRISTATE_BUFFER_1BIT is
    port (
        -- Data input to be driven onto the shared bus
        data_in  : in  std_logic;
        -- Enable signal: when '1', drives data_in onto data_out; when '0', output is 'Z'
        enable   : in  std_logic;
        -- Shared bidirectional bus line (output)
        data_out : out std_logic
    );
end TRISTATE_BUFFER_1BIT;

-- -----------------------------------------------------------------------------
-- Architecture Definition
-- -----------------------------------------------------------------------------
architecture RTL of TRISTATE_BUFFER_1BIT is
begin

    -- Tri-state logic: drive data_out when enabled, otherwise high-impedance
    data_out <= data_in when enable = '1' else 'Z';

end architecture;
