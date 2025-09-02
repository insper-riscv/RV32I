library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library WORK;

entity registradorGenerico is

    generic (
        DATA_WIDTH : natural := 8
    );

    port (
        clock       : in  std_logic;
        clear       : in  std_logic := '1';
        enable      : in  std_logic := 'X';
        --! Vetor de dados para escrita
        source      : in  std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => 'X');
        --! Vetor de dados regisrados
        destination : out std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0')
    );

end entity;

architecture RTL of registradorGenerico is

    -- No signals

begin

    --! Durante a borda de subida de `clock`, caso `enable` esteja habilitado,
    --! atribui `source` a `destination` se `clear` nãoestiver habilitado, caso
    --! contrário atribui vetor booleano baixo a `destination`.
    UPDATE : process(clock)
    begin
        if (rising_edge(clock)) then
            if (enable = '1') then
                if (clear = '1') then
                    destination <= (others => '0');
                else
                    destination <= source;
                end if;
            end if;
        end if;
    end process;

end architecture;