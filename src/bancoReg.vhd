library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bancoReg is
  port (
    clk           : in  std_logic;
    clear         : in  std_logic := '0';  -- pode ligar em '0' se não usar reset
    escreveC      : in  std_logic := '0';  -- enable de escrita
    enderecoA     : in  std_logic_vector(4 downto 0);
    enderecoB     : in  std_logic_vector(4 downto 0);
    enderecoC     : in  std_logic_vector(4 downto 0);
    dadoEscritaC  : in  std_logic_vector(31 downto 0);
    saidaA        : out std_logic_vector(31 downto 0);
    saidaB        : out std_logic_vector(31 downto 0)
  );
end entity;

architecture RTL of bancoReg is
  -- x0 é sempre zero; aqui guardamos apenas x1..x31
  type reg_array_t is array (1 to 31) of std_logic_vector(31 downto 0);
  signal registers : reg_array_t := (others => (others => '0'));

  -- habilitação individual de escrita para cada registrador x1..x31
  signal we : std_logic_vector(1 to 31);

  signal decode_source_1 : std_logic_vector(31 downto 0);
  signal decode_source_2 : std_logic_vector(31 downto 0);
begin
  ---------------------------------------------------------------------------
  -- Gera os enables como atribuições concorrentes (VHDL-93 OK)
  ---------------------------------------------------------------------------
  GEN_WE : for i in 1 to 31 generate
  begin
    we(i) <= '1' when (escreveC = '1' and enderecoC = std_logic_vector(to_unsigned(i, 5))) else '0';
  end generate;

  ---------------------------------------------------------------------------
  -- Write enable por registrador (x0 não é gravável)
  ---------------------------------------------------------------------------
  GEN_REGISTERS : for i in 1 to 31 generate
    register_I : entity work.genericRegister
      generic map (
        DATA_WIDTH => 32
      )
      port map (
        clock       => clk,
        clear       => clear,
        enable      => we(i),          -- <<< usa o sinal intermediário
        source      => dadoEscritaC,
        destination => registers(i)
      );
  end generate;

  process(enderecoA, registers)
  begin
    case to_integer(unsigned(enderecoA)) is
      when 0  => decode_source_1 <= (others => '0');
      when 1  => decode_source_1 <= registers(1);
      when 2  => decode_source_1 <= registers(2);
      when 3  => decode_source_1 <= registers(3);
      when 4  => decode_source_1 <= registers(4);
      when 5  => decode_source_1 <= registers(5);
      when 6  => decode_source_1 <= registers(6);
      when 7  => decode_source_1 <= registers(7);
      when 8  => decode_source_1 <= registers(8);
      when 9  => decode_source_1 <= registers(9);
      when 10 => decode_source_1 <= registers(10);
      when 11 => decode_source_1 <= registers(11);
      when 12 => decode_source_1 <= registers(12);
      when 13 => decode_source_1 <= registers(13);
      when 14 => decode_source_1 <= registers(14);
      when 15 => decode_source_1 <= registers(15);
      when 16 => decode_source_1 <= registers(16);
      when 17 => decode_source_1 <= registers(17);
      when 18 => decode_source_1 <= registers(18);
      when 19 => decode_source_1 <= registers(19);
      when 20 => decode_source_1 <= registers(20);
      when 21 => decode_source_1 <= registers(21);
      when 22 => decode_source_1 <= registers(22);
      when 23 => decode_source_1 <= registers(23);
      when 24 => decode_source_1 <= registers(24);
      when 25 => decode_source_1 <= registers(25);
      when 26 => decode_source_1 <= registers(26);
      when 27 => decode_source_1 <= registers(27);
      when 28 => decode_source_1 <= registers(28);
      when 29 => decode_source_1 <= registers(29);
      when 30 => decode_source_1 <= registers(30);
      when 31 => decode_source_1 <= registers(31);
      when others => decode_source_1 <= (others => '0');
    end case;
  end process;

  process(enderecoB, registers)
  begin
    case to_integer(unsigned(enderecoB)) is
      when 0  => decode_source_2 <= (others => '0');
      when 1  => decode_source_2 <= registers(1);
      when 2  => decode_source_2 <= registers(2);
      when 3  => decode_source_2 <= registers(3);
      when 4  => decode_source_2 <= registers(4);
      when 5  => decode_source_2 <= registers(5);
      when 6  => decode_source_2 <= registers(6);
      when 7  => decode_source_2 <= registers(7);
      when 8  => decode_source_2 <= registers(8);
      when 9  => decode_source_2 <= registers(9);
      when 10 => decode_source_2 <= registers(10);
      when 11 => decode_source_2 <= registers(11);
      when 12 => decode_source_2 <= registers(12);
      when 13 => decode_source_2 <= registers(13);
      when 14 => decode_source_2 <= registers(14);
      when 15 => decode_source_2 <= registers(15);
      when 16 => decode_source_2 <= registers(16);
      when 17 => decode_source_2 <= registers(17);
      when 18 => decode_source_2 <= registers(18);
      when 19 => decode_source_2 <= registers(19);
      when 20 => decode_source_2 <= registers(20);
      when 21 => decode_source_2 <= registers(21);
      when 22 => decode_source_2 <= registers(22);
      when 23 => decode_source_2 <= registers(23);
      when 24 => decode_source_2 <= registers(24);
      when 25 => decode_source_2 <= registers(25);
      when 26 => decode_source_2 <= registers(26);
      when 27 => decode_source_2 <= registers(27);
      when 28 => decode_source_2 <= registers(28);
      when 29 => decode_source_2 <= registers(29);
      when 30 => decode_source_2 <= registers(30);
      when 31 => decode_source_2 <= registers(31);
      when others => decode_source_2 <= (others => '0');
    end case;
  end process;

  saidaA <= decode_source_1;
  saidaB <= decode_source_2;
end architecture;

