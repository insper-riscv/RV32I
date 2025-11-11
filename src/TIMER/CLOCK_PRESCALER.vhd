-- =============================================================================
-- Entity: CLOCK_PRESCALER
-- Description:
--   Generates a 1-cycle tick when the internal counter reaches a configurable
--   prescaler value. The counter resets after each tick. Fully modular structure.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;

entity CLOCK_PRESCALER is
  generic (
    DATA_WIDTH : integer := 32 -- Width of the counter
  );
  port (
    clock        : in  std_logic;                                -- System clock
    clear        : in  std_logic;                                -- Asynchronous clear
    prescaler_in : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- Prescaler value (from register)
    tick         : out std_logic                                 -- One-cycle tick when counter matches prescaler
  );
end entity;

architecture RTL of CLOCK_PRESCALER is
  signal counter       : std_logic_vector(DATA_WIDTH-1 downto 0); -- Prescaler counter
  signal next_counter  : std_logic_vector(DATA_WIDTH-1 downto 0); -- Incremented counter
  signal comp_result   : std_logic;                               -- Comparison result (counter >= prescaler)
  signal tick_out      : std_logic;                               -- 1-cycle pulse

begin

  ---------------------------------------------------------------------------
  -- Compare counter >= prescaler_in
  ---------------------------------------------------------------------------
  U_GE : entity WORK.ALU_GE_UNSIGNED
    generic map (DATA_WIDTH => DATA_WIDTH)
    port map (
      source_1 => counter,
      source_2 => prescaler_in,
      ge       => comp_result
    );

  ---------------------------------------------------------------------------
  -- next_counter = counter + 1
  ---------------------------------------------------------------------------
  U_ADDER : entity WORK.GENERIC_ADDER
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      DEFAULT_SOURCE_2 => 1
    )
    port map (
      source_1    => counter,
      destination => next_counter
    );

  ---------------------------------------------------------------------------
  -- Counter Register
  -- Clears to 0 when tick fires
  ---------------------------------------------------------------------------
  U_COUNTER : entity WORK.GENERIC_REGISTER
    generic map (DATA_WIDTH => DATA_WIDTH)
    port map (
      clock       => clock,
      clear       => clear or comp_result, -- Reset when tick is fired
      enable      => '1',               -- Controlled by start_signal
      source      => next_counter,
      destination => counter
    );

  ---------------------------------------------------------------------------
  -- Tick Flip-Flop (1-cycle pulse)
  ---------------------------------------------------------------------------
  U_TICK_FF : entity WORK.FlipFlop
    port map (
      clock       => clock,
      clear       => clear,
      enable      => '1',         -- Same gating
      source      => comp_result,
      destination => tick_out
    );

  tick <= tick_out; -- Output pulse

end architecture;

