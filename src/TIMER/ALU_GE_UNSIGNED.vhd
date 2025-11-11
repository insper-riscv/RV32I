-- =============================================================================
--  File:        ALU_GE_UNSIGNED.vhd
--  Description: Unsigned "greater-or-equal" comparator that outputs one bit
--               (ge = '1' when source_1 ≥ source_2). Pure combinational
--               gate logic; no use of built‑in adders or numeric_std.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ============================================================================
--  Entity Declaration
-- ============================================================================
entity ALU_GE_UNSIGNED is
  generic (
    DATA_WIDTH : natural := 32  --! Operand width
  );
  port (
    source_1 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    source_2 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    ge       : out std_logic  --! '1' when source_1 ≥ source_2 (unsigned)
  );
end entity ALU_GE_UNSIGNED;

-- ============================================================================
--  Architecture (combinational – borrow detection via ripple adder)
-- ============================================================================
architecture RTL of ALU_GE_UNSIGNED is
  signal b_inv : std_logic_vector(DATA_WIDTH-1 downto 0);  -- ¬B
  signal c     : std_logic_vector(DATA_WIDTH downto 0);    -- ripple carry/borrow
begin
  -----------------------------------------------------------------------------
  -- Pre-invert B and seed carry(0)=1 to form A + (¬B) + 1 (two's complement)
  -----------------------------------------------------------------------------
  b_inv <= not source_2;
  c(0)  <= '1';
  
  -----------------------------------------------------------------------------
  -- Ripple subtractor: generate/propagate borrow bit-by-bit
  -----------------------------------------------------------------------------
  GEN_RIPPLE: for i in 0 to DATA_WIDTH-1 generate
    c(i+1) <= (source_1(i) and b_inv(i))              -- generate borrow
            or ((source_1(i) xor b_inv(i)) and c(i)); -- propagate borrow
  end generate;

  -----------------------------------------------------------------------------
  -- No borrow means A ≥ B → ge = c(DATA_WIDTH)
  -----------------------------------------------------------------------------
  ge <= c(DATA_WIDTH);
end architecture RTL;
