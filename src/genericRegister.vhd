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
        --! Sinal de clear (assíncrono)
        clear       : in  std_logic := '1';
        --! Habilita a escrita
        enable      : in  std_logic := '0';
        --! Vetor de dados para escrita
        source      : in  std_logic_vector((data_width - 1) downto 0) := (others => '0');
        --! Vetor de dados registrados
        destination : out std_logic_vector((data_width - 1) downto 0) := (others => '0')
    );
end entity;

architecture RTL of genericRegister is
begin
    --! Durante a borda de subida de `clock`, caso `enable` esteja habilitado,
    --! atribui `source` a `destination`. Caso `clear` seja ativado (assíncrono),
    --! zera imediatamente a saída.
    UPDATE : process(clock, clear)
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
