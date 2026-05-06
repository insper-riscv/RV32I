--------------------------------------------------------------------------------
-- mult.vhd
-- Wrapper que substitui o lpm_mult pelo booth_multiplier_rv32 (33 ciclos).
--
-- Mantém a interface combinacional original (dataa/datab/result) e adiciona
-- handshake sequencial (clk/rst/start/busy/done) para que multdiv stalle
-- corretamente o pipeline.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mult is
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        start  : in  std_logic;
        dataa  : in  std_logic_vector(32 downto 0);
        datab  : in  std_logic_vector(32 downto 0);
        result : out std_logic_vector(65 downto 0);
        done   : out std_logic;
        busy   : out std_logic
    );
end entity mult;

architecture rtl of mult is
    signal result_lo : std_logic_vector(31 downto 0);
    signal result_hi : std_logic_vector(31 downto 0);
begin

    BOOTH : entity work.booth_multiplier_rv32
        port map (
            clk          => clk,
            rst          => rst,
            start        => start,
            multiplicand => dataa(31 downto 0),
            multiplier   => datab(31 downto 0),
            result_lo    => result_lo,
            result_hi    => result_hi,
            done         => done,
            busy         => busy
        );

    -- {2'b00, hi, lo}: multdiv lê result(63:32) para MULH, result(31:0) para MUL
    result <= "00" & result_hi & result_lo;

end architecture rtl;
