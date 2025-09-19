library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AddressDecoder is
  port (
    signal_in : in  std_logic_vector(31 downto 0); -- endereço vindo da ALU

    -- endereços "roteados" (opcional, úteis se os blocos esperarem o addr)
    keys_out  : out std_logic_vector(31 downto 0);
    VGA_out   : out std_logic_vector(31 downto 0);
    RAM_addr  : out std_logic_vector(31 downto 0);

    -- selects limpos (use estes para gerar enables de leitura/escrita)
    selRAM    : out std_logic;
    selVGA    : out std_logic;
    selKEYS   : out std_logic
  );
end entity;

architecture behaviour of AddressDecoder is
  -- Mapa:
  --   VGA  : 0x8000_0000 .. 0x8000_000F   (4 regs alinhados a 32b)
  --   KEYS : 0x8000_0010                  (1 reg de leitura)
  --   RAM  : demais endereços
  constant VGA_PREFIX_31_4 : std_logic_vector(27 downto 0) := x"8000000"; -- 28 bits
  constant KEYS_ADDR       : std_logic_vector(31 downto 0) := x"80000010";

  signal is_vga  : std_logic;
  signal is_keys : std_logic;
  signal is_ram  : std_logic;
begin
  -- Detecta exatamente 0x8000_0000..0x8000_000F (bits [31:4] iguais a 0x8000000)
  is_vga  <= '1' when (signal_in(31 downto 4) = VGA_PREFIX_31_4) else '0';

  -- KEYS em endereço único 0x8000_0010
  is_keys <= '1' when (signal_in = KEYS_ADDR) else '0';

  -- RAM é o resto
  is_ram  <= not (is_vga or is_keys);

  -- Exporte selects diretamente (não dependa do valor do addr!)
  selVGA  <= is_vga;
  selKEYS <= is_keys;
  selRAM  <= is_ram;

  -- Roteia o endereço para o bloco correspondente (zero nos demais)
  VGA_out  <= signal_in when is_vga  = '1' else (others => '0');
  keys_out <= signal_in when is_keys = '1' else (others => '0');
  RAM_addr <= signal_in when is_ram  = '1' else (others => '0');

  -- Dica: no periférico VGA, use signal_in(3 downto 2) como offset:
  --   "00"=POSCOL, "01"=POSLIN, "10"=DADOIN, "11"=WE
end architecture;
