-- =============================================================================
-- Entity: GENERIC_FLIP_FLOP
-- Description: Standard D flip-flop with synchronous clear and enable.
--              When clear is '1', output is reset to '0'.
--              When enable is '1', source is loaded into internal state.
--              Destination is continuously driven by internal state.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- -----------------------------------------------------------------------------
-- Entity Declaration
-- -----------------------------------------------------------------------------
entity GENERIC_FLIP_FLOP is
    port (
        -- Clock signal (rising-edge triggered)
        clock  : in  std_logic;

        -- Synchronous clear: when '1', resets output to '0'
        clear  : in  std_logic;

        -- Enable signal: when '1' and clear is '0', state <= source
        enable : in  std_logic;

        -- Input data to be stored
        source : in  std_logic;

        -- Flip-flop output (registered value)
        destination : out std_logic
    );
end entity GENERIC_FLIP_FLOP;

-- -----------------------------------------------------------------------------
-- Architecture Definition
-- -----------------------------------------------------------------------------
architecture RTL of GENERIC_FLIP_FLOP is
    -- Internal signal holding the registered state
    signal state : std_logic;
begin

    -- Synchronous process triggered on rising clock edge
    UPDATE : process(clock)
    begin
        if rising_edge(clock) then
            -- Priority: clear has precedence over enable
            if clear = '1' then
                state <= '0';
            elsif enable = '1' then
                state <= source;
            end if;
        end if;
    end process;

    -- Output continuously assigned to internal state
    destination <= state;

end architecture RTL;
