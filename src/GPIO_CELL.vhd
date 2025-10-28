-- =============================================================================
-- Entity: GPIO_CELL
-- Description:
--   Single-bit General-Purpose I/O cell. Interfaces a processor with a
--   bidirectional I/O pin, supporting direction control, output operations,
--   and interrupt configuration (masking, edge detection, and W1C clearing).
--   Provides a readback multiplexer for processor access to internal state.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library WORK;

-- -----------------------------------------------------------------------------
-- Entity Declaration
-- -----------------------------------------------------------------------------
entity GPIO_CELL is
  port (
    -- System interface
    clock : in  std_logic; -- System clock
    clear : in  std_logic; -- Global clear (asynchronous or synchronous)

    -- Data bus
    data_in  : in  std_logic; -- Data from processor (1-bit)
    data_out : out std_logic_vector (6 downto 0); -- Data to processor (1-bit)

    -- Control signals
    wr_signals : in std_logic_vector(6 downto 0); -- Write enable signals
    wr_op  : in std_logic_vector(1 downto 0); -- Output mode: LOAD, SET, CLEAR, TOGGLE

    -- Physical GPIO pin (bidirectional)
    gpio_pin : inout std_logic
  );
end entity;

-- -----------------------------------------------------------------------------
-- Architecture Definition
-- -----------------------------------------------------------------------------
architecture RTL of GPIO_CELL is
  
  -- -----------------------------------------------------------------------------
  -- Internal Registers
  -- -----------------------------------------------------------------------------
  signal dir_reg : std_logic; -- Direction register (input/output)
  signal out_reg : std_logic; -- Output register (data to GPIO pin)
  signal pin_input : std_logic; -- Synchronized input from GPIO pin
  signal mux_write : std_logic; -- Mux output for write operations
  signal irq_mask : std_logic; -- Interrupt mask register (global interrupt enable)
  signal irq_rise_mask : std_logic; -- Rising edge interrupt mask register
  signal irq_fall_mask : std_logic; -- Falling edge interrupt mask register
  signal irq_status : std_logic; -- Interrupt status register 
  -----------------------------------------------------------------------------
  -- Helper Signals
  -----------------------------------------------------------------------------
  signal prev_pin_input : std_logic; -- Previous value of GPIO pin (for edge detection)
  signal interrupt_logic : std_logic; -- Interrupt logic (for edge detection)
  signal mux_write_vector : std_logic_vector(0 downto 0); -- Intermediate vector for mux output
begin

  -----------------------------------------------------------------------------
  -- Direction Register: Controls GPIO pin direction (input/output).
  -- 0 = input, 1 = output
  -----------------------------------------------------------------------------
  U_REG_DIR : entity WORK.GENERIC_FLIP_FLOP
    port map (
        clock       => clock,
        clear       => clear,
        enable      => wr_signals(0), -- Enable write to direction register
        source      => data_in, -- Data to be written to direction register
        destination => dir_reg  -- Direction of GPIO pin (input/output)
    );

  -----------------------------------------------------------------------------
  -- Multiplexer for Write Operations.
  -- When selector 00 = LOAD, 01 = SET, 10 = CLEAR, 11 = TOGGLE
  -----------------------------------------------------------------------------
  U_MUX_WRITE : entity WORK.GENERIC_MUX_4X1
    generic map (
      DATA_WIDTH => 1
    )
    port map (
      selector    => wr_op,
      source_1 => (0 => data_in),     -- Load
      source_2    => std_logic_vector'("1"),         -- Set
      source_3    => std_logic_vector'("0"),         -- Clear
      source_4 => (0 => not out_reg), -- Toggle
      destination => mux_write_vector                -- intermediate 1-bit vector
    );

  -- Unpack result from mux (mux_write is std_logic)
  mux_write <= mux_write_vector(0); -- Unpack 1-bit vector to std_logic

  
  -----------------------------------------------------------------------------
  -- Output Register: Holds the value to be sent to the GPIO pin.
  -- Enabled on load operations and when the bit is selected (data in = 1) for SET/CLEAR/TOGGLE.
  -----------------------------------------------------------------------------
  U_REG_OUT : entity WORK.GENERIC_FLIP_FLOP
    port map (
        clock       => clock,
        clear       => clear,
        enable      => wr_signals(1) OR (wr_signals(2) AND data_in), -- Load or Set/Clear/Toggle
        source      => mux_write, -- Data to be written to output register
        destination => out_reg -- Data to be sent to GPIO pin
    );

  -----------------------------------------------------------------------------
  -- Tristate Buffer: Connects output register to GPIO pin based on direction.
  -- If dir_reg = '1', buffer is enabled and out_reg is sent to gpio_pin.
  -- If dir_reg = '0', buffer is disabled and gpio_pin is in high-impedance state.
  -----------------------------------------------------------------------------
  U_GPIO_BUFFER : entity WORK.TRISTATE_BUFFER_1BIT
    port map (
          data_in  => out_reg, -- Output register value
          enable   => dir_reg, -- Direction control (input/output). Enable buffer if dir_reg is '1' (output)
          data_out => gpio_pin -- GPIO pin output
    );

  -----------------------------------------------------------------------------
  -- Synchronizer: Synchronizes the asynchronous GPIO pin input to the clock domain.
  -- This is necessary to avoid metastability issues when reading the GPIO pin.
  -----------------------------------------------------------------------------      
  U_SYNC : entity WORK.GENERIC_SYNCHRONIZER_1BIT
    generic map (N => 2) -- Number of stages in the synchronizer
    port map (
        clock       => clock,
        async_in  => gpio_pin, -- Asynchronous input from GPIO pin
        sync_out  => pin_input -- Synchronized output to processor
    );

  -----------------------------------------------------------------------------
  -- Previous Pin Input Register: Holds the previous value of the GPIO pin.
  -- This is used for edge detection in the interrupt logic.
  -----------------------------------------------------------------------------
  U_REG_PREV : entity WORK.GENERIC_FLIP_FLOP
    port map (
        clock       => clock,
        clear       => '0', -- No reset
        enable      => '1', -- Always enabled
        source      => pin_input, -- Synchronized input from GPIO pin
        destination => prev_pin_input -- Previous pin value
    );

  -----------------------------------------------------------------------------
  -- Interrupt Mask Register: Controls wether interrupts are enabled or disabled for this GPIO cell.
  -- If irq_mask = '1', interrupts are enabled. If irq_mask = '0', interrupts are disabled.
  -----------------------------------------------------------------------------
  U_IRQ_MASK : entity WORK.GENERIC_FLIP_FLOP
    port map (
        clock       => clock,
        clear       => clear,
        enable      => wr_signals(3), -- Enable write to interrupt mask register
        source      => data_in, -- Data to be written to interrupt mask register
        destination => irq_mask -- Interrupt mask register
    );
  
  -----------------------------------------------------------------------------
  -- Interrupt Rising Edge Mask Register: Controls rising edge interrupt detection.
  -- If irq_rise_mask = '1', rising edge interrupts are enabled. If irq_rise_mask = '0', they are disabled.
  -----------------------------------------------------------------------------
  U_IRQ_RISE : entity WORK.GENERIC_FLIP_FLOP
    port map (
        clock       => clock,
        clear       => clear,
        enable      => wr_signals(4), -- Enable write to rising edge mask register
        source      => data_in, -- Data to be written to rising edge mask register
        destination => irq_rise_mask -- Rising edge interrupt mask register
    );
  
  --------------------------------------------------------------------------
  -- Interrupt Falling Edge Mask Register: Controls falling edge interrupt detection.
  -- If irq_fall_mask = '1', falling edge interrupts are enabled. If irq_fall_mask = '0', they are disabled.
  --------------------------------------------------------------------------
  U_IRQ_FALL : entity WORK.GENERIC_FLIP_FLOP
    port map (
        clock       => clock,
        clear       => clear,
        enable      => wr_signals(5), -- Enable write to falling edge mask register
        source      => data_in, -- Data to be written to falling edge mask register
        destination => irq_fall_mask -- Falling edge interrupt mask register
    );
  
  -----------------------------------------------------------------------------
  -- Interrupt Logic: Detects rising and falling edges on the GPIO pin.
  -- Generates an interrupt signal if the corresponding mask is set.
  -- Rising edge: pin_input goes from 0 to 1 (prev_pin_input = 0, pin_input = 1)
  -- Falling edge: pin_input goes from 1 to 0 (prev_pin_input = 1, pin_input = 0)
  -----------------------------------------------------------------------------
  interrupt_logic <= (irq_rise_mask AND (pin_input AND NOT prev_pin_input)) OR
                     (irq_fall_mask AND (NOT pin_input AND prev_pin_input)); -- Edge detection logic

  ----------------------------------------------------------------------------
  -- Interrupt Status Register: Holds the interrupt status for this GPIO cell.
  -- If irq_status = '1', an interrupt has occurred. If irq_status = '0', no interrupt.
  -- The status is cleared when the processor writes a '1' to the register (W1C).
  -- The interrupt status is set if the interrupt logic is high and the mask is enabled.
  ----------------------------------------------------------------------------
  U_IRQ_STATUS : entity WORK.GENERIC_FLIP_FLOP
    port map (
        clock       => clock,
        clear       => clear or (wr_signals(6)), -- Clear on Read
        enable      => interrupt_logic AND irq_mask, -- Set interrupt status if interrupt logic is high and mask is enabled
        source      => '1', -- Set interrupt status to '1' on edge detection
        destination => irq_status -- Interrupt status register
    );
  

  data_out(0) <= dir_reg; -- Read direction register
  data_out(1) <= out_reg; -- Read output register
  data_out(2) <= pin_input; -- Read GPIO pin input
  data_out(3) <= irq_mask; -- Read interrupt mask register
  data_out(4) <= irq_rise_mask; -- Read rising edge mask register
  data_out(5) <= irq_fall_mask; -- Read falling edge mask register
  data_out(6) <= irq_status; -- Read interrupt status register
end architecture;
