-- =============================================================================
-- Entity: GENERIC_SYNCHRONIZER_1BIT
-- Description: N‑stage synchronizer for a single asynchronous bit.
--              Each stage is a GENERIC_FLIP_FLOP.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity GENERIC_SYNCHRONIZER_1BIT is
    generic (
        N : natural := 2           -- number of synchronizing stages (≥ 2)
    );
    port (
        clock    : in  std_logic;  -- destination clock domain
        async_in : in  std_logic;  -- asynchronous input bit
        sync_out : out std_logic   -- synchronized output bit
    );
end entity GENERIC_SYNCHRONIZER_1BIT;

-- -----------------------------------------------------------------------------
-- Architecture
-- -----------------------------------------------------------------------------
architecture RTL of GENERIC_SYNCHRONIZER_1BIT is

    -- Pipeline of N + 1 single‑bit stages (stage 0 holds the async input)
    type sync_array_t is array (0 to N) of std_logic;
    signal sync_stages : sync_array_t;

begin
    ---------------------------------------------------------------------------
    -- Stage‑0 : tie the raw asynchronous signal to the pipeline
    ---------------------------------------------------------------------------
    sync_stages(0) <= async_in;

    ---------------------------------------------------------------------------
    -- Stages 1 .. N : instantiate a flip‑flop for each stage
    ---------------------------------------------------------------------------
    GEN_STAGE : for i in 1 to N generate
        ff : entity work.GENERIC_FLIP_FLOP
            port map (
                clock       => clock,
                clear       => '0',            -- no reset
                enable      => '1',            -- always enabled
                source      => sync_stages(i-1),
                destination => sync_stages(i)
            );
    end generate GEN_STAGE;

    ---------------------------------------------------------------------------
    -- Output : last stage of the pipeline
    ---------------------------------------------------------------------------
    sync_out <= sync_stages(N);

end architecture RTL;
