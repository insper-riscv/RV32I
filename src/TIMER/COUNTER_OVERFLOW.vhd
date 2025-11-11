-- =============================================================================
-- Entity: COUNTER_OVERFLOW
-- Description:
--   Pure-combinational “overflow unit” for an unsigned timer / counter.
--   Asserts overflow = '1' when the counter reaches or exceeds the top value.
--   The overflow flag is a combinational pulse that is cleared on the next read.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- -----------------------------------------------------------------------------
-- Entity Declaration
-- -----------------------------------------------------------------------------
entity COUNTER_OVERFLOW is
  generic (
    --! Data width of the counter (in bits)
    DATA_WIDTH : natural := 32
  );
  port (
    -- -------------------------------------------------------------------------
    -- Counter interface
    -- -------------------------------------------------------------------------
    counter_value : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Present count
    top_value     : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Terminal count

    -- -------------------------------------------------------------------------
    -- Overflow flag (combinational pulse)
    -- -------------------------------------------------------------------------
    overflow      : out std_logic -- overflow flag (active high)
  );
end entity COUNTER_OVERFLOW;

-- -----------------------------------------------------------------------------
-- Architecture Definition
-- -----------------------------------------------------------------------------
architecture RTL of COUNTER_OVERFLOW is

  -- Internal comparator signal
  signal cnt_ge_top : std_logic; -- counter_value ≥ top_value

begin
  -----------------------------------------------------------------------------
  -- GREATER-OR-EQUAL COMPARATOR
  -----------------------------------------------------------------------------
  U_GE_COUNTER_TOP : entity WORK.ALU_GE_UNSIGNED
    generic map ( DATA_WIDTH => DATA_WIDTH )
    port map (
      source_1 => counter_value,   -- A
      source_2 => top_value,       -- B
      ge       => cnt_ge_top       -- A ≥ B
    );

  -----------------------------------------------------------------------------
  -- OVERFLOW FLAG = counter ≥ top
  -----------------------------------------------------------------------------
  overflow <= cnt_ge_top;

end architecture RTL;

