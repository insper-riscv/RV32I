-- =============================================================================
-- Entity: GPIO
-- Description:
--   Top-level General-Purpose I/O module interfacing the processor with a 
--   set of bidirectional I/O pins. It integrates multiple GPIO_CELL instances,
--   a decoder for memory-mapped operations, and a multiplexer for data readback.
--   Supports direction control, output operations, and interrupt configuration.
--   Internal logic is based on DATA_WIDTH.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library WORK;

-- -----------------------------------------------------------------------------
-- Entity Declaration
-- -----------------------------------------------------------------------------
entity GPIO is
    generic (
        --! Data width of processor bus
        DATA_WIDTH : natural := 32
    );
    port (
        --! Clock Signal
        clock       : in  std_logic;

        --! Global Reset
        clear       : in  std_logic; 

        --! Data input from processor
        data_in     : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);

        --! Address accessed by the processor
        address     : in  STD_LOGIC_VECTOR(3 downto 0);

        --! Write enable signal
        write       : in  std_logic; 

        --! Read enable signal
        read        : in  std_logic; 

        --! Data output to processor (adjusted to DATA_WIDTH)
        data_out    : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);

        --! Interrupt request signal (active high)
        irq         : out std_logic;

        --! Bidirectional GPIO pins
        gpio_pins   : inout std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end GPIO;

-- -----------------------------------------------------------------------------
-- Architecture Definition
-- -----------------------------------------------------------------------------
architecture RTL of GPIO is

    -----------------------------------------------------------------------------
    -- Internal Control Signals
    -----------------------------------------------------------------------------
    signal wr_en   : std_logic_vector(6 downto 0); -- Write enable signals
    signal wr_op   : std_logic_vector(1 downto 0); -- Write operation
    signal rd_sel  : std_logic_vector(2 downto 0); -- Readback selector

    -----------------------------------------------------------------------------
    -- Internal Register Banks (based on DATA_WIDTH)
    -----------------------------------------------------------------------------
    signal dir_reg         : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal out_reg         : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal pins_input      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal irq_mask        : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal irq_rise_mask   : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal irq_fall_mask   : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal irq_status      : std_logic_vector(DATA_WIDTH-1 downto 0);

    -----------------------------------------------------------------------------
    -- Internal Signal for GPIO_CELL Data Output
    -----------------------------------------------------------------------------
    type dout_array_t is array (0 to DATA_WIDTH - 1) of std_logic_vector(6 downto 0);
    signal dout_array : dout_array_t;

    -----------------------------------------------------------------------------
    -- Internal Signal for Readback Multiplexer
    -----------------------------------------------------------------------------
    signal selected_read : std_logic_vector(DATA_WIDTH-1 downto 0); -- Readback data
    constant ZERO_VECTOR : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0'); -- Zero vector for unused readback
begin

    -----------------------------------------------------------------------------
    -- GPIO Operation Decoder
    -----------------------------------------------------------------------------
    U_GPIO_OPERATION_DECODER : entity work.GPIO_OPERATION_DECODER
        port map (
            address => address,
            write   => write,
            read    => read,
            wr_en   => wr_en,
            wr_op   => wr_op,
            rd_sel  => rd_sel
        );

    -----------------------------------------------------------------------------
    -- GPIO_CELL Array Instantiation
    -----------------------------------------------------------------------------
    GEN_CELLS : for i in 0 to DATA_WIDTH - 1 generate
    begin
        GPIO_CELL_I : entity work.GPIO_CELL
            port map (
                clock      => clock,
                clear      => clear,
                data_in    => data_in(i),
                data_out   => dout_array(i),
                wr_signals => wr_en,
                wr_op      => wr_op,
                gpio_pin   => gpio_pins(i)
            );

        dir_reg(i)        <= dout_array(i)(0);
        out_reg(i)        <= dout_array(i)(1);
        pins_input(i)     <= dout_array(i)(2);
        irq_mask(i)       <= dout_array(i)(3);
        irq_rise_mask(i)  <= dout_array(i)(4);
        irq_fall_mask(i)  <= dout_array(i)(5);
        irq_status(i)     <= dout_array(i)(6);
    end generate;

    -----------------------------------------------------------------------------
    -- Readback Multiplexer
    -----------------------------------------------------------------------------
    READ_MUX : entity work.GENERIC_MUX_8X1
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            selector    => rd_sel,
            source_1    => dir_reg,
            source_2    => out_reg,
            source_3    => pins_input,
            source_4    => irq_mask,
            source_5    => irq_rise_mask,
            source_6    => irq_fall_mask,
            source_7    => irq_status,
            source_8    => ZERO_VECTOR,
            destination => selected_read
        );
    data_out <= selected_read;
    -----------------------------------------------------------------------------
    -- Interrupt Generation Logic. 
    -- IRQ is asserted if any of the interrupt status bits are set (Reduce Or Operation).
    -----------------------------------------------------------------------------
    irq <= '1' when irq_status /= ZERO_VECTOR else '0';

end architecture;