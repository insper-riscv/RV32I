--------------------------------------------------------------------------------
-- div.vhd
-- Wrapper para divisão SIGNED (DIV/REM) usando non_restoring_divider_rv32.
-- 34 ciclos. Interface com handshake clk/rst/start/busy/done.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity div is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        start    : in  std_logic;
        numer    : in  std_logic_vector(31 downto 0);
        denom    : in  std_logic_vector(31 downto 0);
        quotient : out std_logic_vector(31 downto 0);
        remain   : out std_logic_vector(31 downto 0);
        done     : out std_logic;
        busy     : out std_logic
    );
end entity div;

architecture rtl of div is
begin

    NR_DIV : entity work.non_restoring_divider_rv32
        port map (
            clk         => clk,
            rst         => rst,
            start       => start,
            is_unsigned => '0',     -- signed: DIV / REM
            dividend    => numer,
            divisor     => denom,
            quotient    => quotient,
            remainder   => remain,
            done        => done,
            busy        => busy,
            div_by_zero => open,
            overflow    => open
        );

end architecture rtl;
