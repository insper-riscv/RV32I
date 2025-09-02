library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.GENERICS.ALL;

entity RV32I_ALU is

    generic (
        DATA_WIDTH : natural := WORK.RV32I.XLEN
    );

    port (
        select_function : in  std_logic_vector(3 downto 0);
        source_1        : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        source_2        : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        overflow        : out std_logic;
        destination     : out std_logic_vector((DATA_WIDTH - 1) downto 0)
    );

end entity;

architecture RTL of RV32I_ALU is

    signal flag_subtract     : std_logic;
    signal source_2_auxiliar : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal source_and        : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal source_or         : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal half_add          : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal full_add          : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal carry_out         : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal slt               : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal sltu              : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal shift             : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal destination_1     : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal destination_2     : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal add_overflow      : std_logic;

begin

    flag_subtract <=    is_equal_dynamic(select_function(3 downto 2), "10") AND
                        NOT(is_equal_dynamic(select_function(1 downto 0), "01"));
                        --WORK.GENERICS.is_equal_dynamic(select_function(3 downto 2), "10") AND
                        --NOT(WORK.GENERICS.is_equal_dynamic(select_function(1 downto 0), "01"));

    source_and <= source_1 AND source_2_auxiliar;
    source_or  <= source_1 OR  source_2;
    half_add   <= source_1 XOR source_2_auxiliar;
    full_add   <= half_add XOR (carry_out((DATA_WIDTH - 2) downto 0) & flag_subtract);

    add_overflow <= carry_out(DATA_WIDTH - 1) XOR carry_out(DATA_WIDTH - 2);
    overflow     <= add_overflow;

    slt <=  (0 => add_overflow XOR full_add(DATA_WIDTH - 1), others => '0');
    sltu <= (0 => NOT(carry_out(DATA_WIDTH - 1)),            others => '0');

    MUX_SOURCE_2 : entity WORK.GENERIC_MUX_2X1
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            selector    => flag_subtract,
            source_1    => source_2,
            source_2    => NOT(source_2),
            destination => source_2_auxiliar
        );

    CARRY_LOOKAHEAD : entity WORK.GENERIC_CARRY_LOOKAHEAD
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map(
            carry_in        => flag_subtract,
            carry_generate  => source_and,
            carry_propagate => half_add,
            carry_out       => carry_out
        );

    SHIFTER : entity WORK.RV32I_ALU_SHIFTER
        generic map (
            DATA_WIDTH  => WORK.RV32I.XLEN
        )
        port map (
            select_function => select_function,
            shamt           => source_2(4 downto 0),
            source          => source_1,
            destination     => shift
        );

    MUX_DESTINATION_1 : entity WORK.GENERIC_MUX_4X1
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            selector    => select_function(1 downto 0),
            source_1    => full_add,
            source_2    => shift,
            source_3    => slt,
            source_4    => sltu,
            destination => destination_1
        );

    MUX_DESTINATION_2 : entity WORK.GENERIC_MUX_4X1
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            selector    => select_function(1 downto 0),
            source_1    => half_add,
            source_2    => shift,
            source_3    => source_or,
            source_4    => source_and,
            destination => destination_2
        );

    MUX_DESTINATION_3 : entity WORK.GENERIC_MUX_2X1
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            selector    => select_function(2),
            source_1    => destination_1,
            source_2    => destination_2,
            destination => destination
        );

end architecture;