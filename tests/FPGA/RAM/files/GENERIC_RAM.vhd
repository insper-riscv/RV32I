library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;

--! Memória de acesso randômico
entity GENERIC_RAM is

    generic (
        --! Largura dos vetores de dados
        DATA_WIDTH        : natural := 8;
        --! Largura do vetor de endereço
        ADDRESS_WIDTH     : natural := 8;
        --! Largura do vetor de endereço mapeado na memória
        ADDRESSABLE_WIDTH : natural := 7
    );

    port (
        --! Sinal de clock
        clock        : in  std_logic;
        --! Habilita a entidade
        enable       : in  std_logic;
        --! Habilita leitura. Caso contrário, destination assume sinal de alta impedância
        enable_read  : in  std_logic;
        --! Habilita escrita
        enable_write : in  std_logic;
        --! Vetor de endereço
        address      : in  std_logic_vector((ADDRESS_WIDTH - 1) downto 0);
        --! Vetor de dados para escrita
        source       : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        --! Vetor de dados endereçado para leitura
        destination  : out std_logic_vector((DATA_WIDTH - 1) downto 0)
    );

end entity;

architecture RTL OF GENERIC_RAM IS

    subtype word_t is std_logic_vector((DATA_WIDTH - 1) downto 0);
    type memory_t is array(0 to (2**ADDRESSABLE_WIDTH - 1)) of word_t;

    signal ram: memory_t;
    signal local_address : integer;

begin

    local_address <= to_integer(unsigned(address((ADDRESSABLE_WIDTH - 1) downto 0)));

    destination <=  ram(local_address) when (
                        enable = '1' AND enable_read = '1'
                    ) else (others => '0');

    WRITE : process(clock)
    begin
        if(rising_edge(clock)) then
            STORE : if(enable = '1' AND enable_write = '1') then
                ram(local_address) <= source ;
            end if;
        end if;
    end process;

end architecture;