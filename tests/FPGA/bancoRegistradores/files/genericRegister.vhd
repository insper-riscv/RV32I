library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity genericRegister is
    generic (
        --! Largura dos vetores de dados
        data_width : natural := 8
    );
    port (
        --! Sinal de clock
        clock       : in  std_logic;
        --! Sinal de clear (sincrono)
        clear       : in  std_logic := '1';
        --! Habilita a entidade
        enable      : in  std_logic := 'X';
        --! Vetor de dados para escrita
        source      : in  std_logic_vector((data_width - 1) downto 0) := (others => 'X');
        --! Vetor de dados registrados
        destination : out std_logic_vector((data_width - 1) downto 0) := (others => '0')
    );
end entity;

architecture RTL of genericRegister is
begin
    --! Durante a borda de subida de `clock`, caso `enable` esteja habilitado,
    --! atribui `source` a `destination` se `clear` não estiver habilitado, caso
    --! contrário atribui vetor baixo a `destination`.
    UPDATE : process(clock)
    begin
        if clear = '1' then
                destination <= (others => '0');
        elsif rising_edge(clock) then
            if enable = '1' then
                destination <= source;
            end if;
        end if;
    end process;
end architecture;
