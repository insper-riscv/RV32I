library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.GENERICS.ALL;

entity ULA32bits is

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

architecture RTL of ULA32bits is

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
	 
	 signal carry : std_logic_vector(8 downto 0);

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
		  
	 source_2_auxiliar <= (source_2 AND NOT(flag_subtract)) OR (NOT(source_2) AND flag_subtract);
		  
    -- carry lookahead
		  
	 carry(0)  <= flag_subtract;
    carry_out <= carry(8 downto 1);

    BIT_TO_BIT : for i in 0 to (8 - 1) generate
        carry(i + 1) <= (carry(i) AND half_add(i)) OR source_and(i);
    end generate;
	 
	 --

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
		  
	 destination_1 <=  (
                        (full_add AND (NOT(select_function(0)) AND NOT(select_function(1)))) OR
                        (shift AND (select_function(0) AND NOT(select_function(1))))
                    ) OR (
                        (slt AND (NOT(select_function(0)) AND select_function(1))) OR
                        (sltu AND (select_function(0) AND select_function(1)))
                    );
		  
	 destination_2 <=  (
								(half_add AND (NOT(select_function(0)) AND NOT(select_function(1)))) OR
								(shift AND (select_function(0) AND NOT(select_function(1))))
						  ) OR (
								(source_or AND (NOT(select_function(0)) AND select_function(1))) OR
								(source_and AND (select_function(0) AND select_function(1)))
						  );
		  
	 destination <= (destination_1 AND NOT(select_function(2))) OR (destination_2 AND select_function(2));

end architecture;