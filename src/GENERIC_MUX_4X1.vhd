-- =============================================================================
-- Entity: GENERIC_MUX_4X1
-- Description: 4-to-1 multiplexer with parameterizable data width.
--              Selects one of four input vectors based on a 2-bit selector.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library WORK;

-- -----------------------------------------------------------------------------
-- Entity Declaration
-- -----------------------------------------------------------------------------
entity GENERIC_MUX_4X1 is
    generic (
        -- Width of the data vectors
        DATA_WIDTH : natural := 8
    );
    port (
        -- Selector input (2 bits)
        selector     : in  std_logic_vector(1 downto 0);
        -- Input vector 1
        source_1     : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        -- Input vector 2
        source_2     : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        -- Input vector 3
        source_3     : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        -- Input vector 4
        source_4     : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        -- Output selected vector
        destination  : out std_logic_vector((DATA_WIDTH - 1) downto 0)
    );
end entity;

-- -----------------------------------------------------------------------------
-- Architecture Definition
-- -----------------------------------------------------------------------------
architecture RTL of GENERIC_MUX_4X1 is

    -- Helper signals to expand selector bits across DATA_WIDTH
    signal selector_0 : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal selector_1 : std_logic_vector((DATA_WIDTH - 1) downto 0);

begin

    -- Replicate selector bits for bitwise operations
    selector_0 <= (others => selector(0));
    selector_1 <= (others => selector(1));

    -- Multiplexer logic using bitwise operations
    destination <=  (
                        (source_1 AND (NOT(selector_0) AND NOT(selector_1))) OR
                        (source_2 AND (selector_0 AND NOT(selector_1)))
                    ) OR (
                        (source_3 AND (NOT(selector_0) AND selector_1)) OR
                        (source_4 AND (selector_0 AND selector_1))
                    );

end architecture;
