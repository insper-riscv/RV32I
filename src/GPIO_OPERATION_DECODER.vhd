-- =============================================================================
-- Entity: GPIO_OPERATION_DECODER
-- Description:
--   Decodes read/write operations for a memory‑mapped GPIO peripheral.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- -----------------------------------------------------------------------------
-- Entity Declaration
-- -----------------------------------------------------------------------------
entity GPIO_OPERATION_DECODER is
  port (
    -- Bus interface
    address : in  std_logic_vector(3 downto 0);
    write   : in  std_logic;
    read    : in  std_logic;

    -- Vector of write enables (see bit map below)
    wr_en   : out std_logic_vector(6 downto 0);

    -- GPIO OUTPUT operation selector (LOAD / SET / CLEAR / TOGGLE)
    wr_op   : out std_logic_vector(1 downto 0);

    -- Read selector for multiplexer
    rd_sel  : out std_logic_vector(2 downto 0)
  );
end entity GPIO_OPERATION_DECODER;

-- -----------------------------------------------------------------------------
-- Architecture Definition
-- -----------------------------------------------------------------------------
architecture RTL of GPIO_OPERATION_DECODER is

  -- ===========================================================================
  -- WRITE‑ENABLE VECTOR BIT MAP  (wr_en)
  -- ===========================================================================
  --   Bit : Purpose
  --   ----+------------------------------------------------------------
  --    0  | WR_DIR        – Direction register
  --    1  | WR_LOAD_OUT   – OUTPUT register (LOAD whole word)
  --    2  | WR_BIT_OUT    – OUTPUT register (SET / CLEAR / TOGGLE bits)
  --    3  | WR_IRQ_MASK   – Global interrupt‑enable mask
  --    4  | WR_RISE_MASK  – Rising‑edge interrupt mask
  --    5  | WR_FALL_MASK  – Falling‑edge interrupt mask
  --    6  | IRQ_STATUS_CLR    – Reset interrupt status on IRQ Register read
  -- ===========================================================================
  constant WR_DIR_I       : integer := 0;
  constant WR_LOAD_OUT_I  : integer := 1;
  constant WR_BIT_OUT_I   : integer := 2;
  constant WR_IRQ_MASK_I  : integer := 3;
  constant WR_RISE_MASK_I : integer := 4;
  constant WR_FALL_MASK_I : integer := 5;
  constant IRQ_CLR_I   : integer := 6;

  -- ===========================================================================
  -- Direction Register
  -- ===========================================================================
  constant ADDR_DIR       : std_logic_vector(3 downto 0) := "0000";
  -- ===========================================================================
  -- Output Register
  -- ===========================================================================
  constant ADDR_OUT_LOAD  : std_logic_vector(3 downto 0) := "0001";
  constant ADDR_OUT_SET   : std_logic_vector(3 downto 0) := "0010";
  constant ADDR_OUT_CLR   : std_logic_vector(3 downto 0) := "0011";
  constant ADDR_OUT_TGL   : std_logic_vector(3 downto 0) := "0100";
  -- ===========================================================================
  -- IRQ MASK Register
  -- ===========================================================================
  constant ADDR_IRQ_MASK  : std_logic_vector(3 downto 0) := "0101";
  -- ===========================================================================
  -- IRQ Rising Edge Register
  -- ===========================================================================
  constant ADDR_RISE_MASK : std_logic_vector(3 downto 0) := "0110";
  -- ===========================================================================
  -- IRQ Falling Edge Register
  -- ===========================================================================
  constant ADDR_FALL_MASK : std_logic_vector(3 downto 0) := "0111";
  -- ===========================================================================
  -- IRQ Status Register
  -- ===========================================================================
  constant ADDR_IRQ_STAT  : std_logic_vector(3 downto 0) := "1000";
  -- ===========================================================================
  -- Read Synchronized Pins 
  -- ===========================================================================
  constant ADDR_PINS      : std_logic_vector(3 downto 0) := "1001";

begin

  -- -----------------------------------------------------------------------------
  -- WRITE DECODING :
  -- -----------------------------------------------------------------------------
  wr_en(WR_DIR_I)       <= write when address = ADDR_DIR       else '0';

  wr_en(WR_LOAD_OUT_I)  <= write when address = ADDR_OUT_LOAD  else '0';

  wr_en(WR_BIT_OUT_I)   <= write when address = ADDR_OUT_SET or
                                      address = ADDR_OUT_CLR or
                                      address = ADDR_OUT_TGL  else '0';

  wr_en(WR_IRQ_MASK_I)  <= write when address = ADDR_IRQ_MASK  else '0';
  wr_en(WR_RISE_MASK_I) <= write when address = ADDR_RISE_MASK else '0';
  wr_en(WR_FALL_MASK_I) <= write when address = ADDR_FALL_MASK else '0';
  wr_en(IRQ_CLR_I)   <= read when address = ADDR_IRQ_STAT   else '0';

  -- -----------------------------------------------------------------------------
  -- GPIO OUTPUT OPERATION: multiplexer selector (wr_op)
  -- -----------------------------------------------------------------------------
  with address select
    wr_op <= "00" when ADDR_OUT_LOAD,  -- LOAD
             "01" when ADDR_OUT_SET,   -- SET
             "10" when ADDR_OUT_CLR,   -- CLEAR
             "11" when ADDR_OUT_TGL,   -- TOGGLE
             "00" when others;            -- default (LOAD)

  -- -----------------------------------------------------------------------------
  -- GPIO READ OPERATION: multiplexer selector (rd_sel)
  -- -----------------------------------------------------------------------------
  with address select
    rd_sel <= "000" when ADDR_DIR,
              "001" when ADDR_OUT_LOAD,
              "001" when ADDR_OUT_SET,
              "001" when ADDR_OUT_CLR,
              "001" when ADDR_OUT_TGL,
              "010" when ADDR_PINS,
              "011" when ADDR_IRQ_STAT,
              "100" when ADDR_IRQ_MASK,
              "101" when ADDR_RISE_MASK,
              "110" when ADDR_FALL_MASK,
              "111" when others;

end architecture RTL;
