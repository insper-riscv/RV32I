library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA is
  port (
    CLOCK_50 : in  std_logic;
    KEY      : in  std_logic_vector(3 downto 0);

    -- pinos VGA (já mapeados no .qsf)
    VGA_HS   : out std_logic;
    VGA_VS   : out std_logic;
    VGA_R    : out std_logic_vector(3 downto 0);
    VGA_G    : out std_logic_vector(3 downto 0);
    VGA_B    : out std_logic_vector(3 downto 0)
  );
end entity;

architecture behaviour of VGA is
  ----------------------------------------------------------------------------
  -- CPU <-> memória
  ----------------------------------------------------------------------------
  signal alu_out_cpu    : std_logic_vector(31 downto 0);
  signal store_data_cpu : std_logic_vector(31 downto 0);
  signal mask_ram_cpu   : std_logic_vector(3 downto 0);
  signal weRAM_cpu      : std_logic;
  signal reRAM_cpu      : std_logic;
  signal eRAM_cpu       : std_logic;

  -- dados vindos dos "slaves" de leitura
  signal RAM_out        : std_logic_vector(31 downto 0);
  signal KEYS_word      : std_logic_vector(31 downto 0);
  signal data_to_cpu    : std_logic_vector(31 downto 0);

  ----------------------------------------------------------------------------
  -- Address Decoder
  ----------------------------------------------------------------------------
  signal dec_keys_addr  : std_logic_vector(31 downto 0);
  signal dec_vga_addr   : std_logic_vector(31 downto 0);
  signal dec_ram_addr   : std_logic_vector(31 downto 0);
  signal selRAM         : std_logic;
  signal selVGA         : std_logic;
  signal selKEYS        : std_logic;

  -- enables para RAM após gating
  signal weRAM_toRAM    : std_logic;
  signal reRAM_toRAM    : std_logic;
  signal eRAM_toRAM     : std_logic;

  ----------------------------------------------------------------------------
  -- MMIO VGA: regs + pulso de WE (larguras conforme driverVGA)
  -- Mapa (offset em 0x8000_0000):
  -- 00: POSCOL  (W)
  -- 01: POSLIN  (W)
  -- 10: DADOIN  (W) [7:6]=cor, [5:0]=char]
  -- 11: WE      (W) escrever qualquer valor -> pulso de 1 ciclo
  ----------------------------------------------------------------------------
  signal vga_poscol_reg : std_logic_vector(7 downto 0) := (others => '0');
  signal vga_poslin_reg : std_logic_vector(7 downto 0) := (others => '0');
  signal vga_dado_reg   : std_logic_vector(7 downto 0) := (others => '0');
  signal vga_we_strobe  : std_logic := '0';
  signal weVGA          : std_logic;
  signal vga_offset     : std_logic_vector(1 downto 0);

begin
  ----------------------------------------------------------------------------
  -- Address Decoder: decide RAM / VGA / KEYS a partir de alu_out_cpu
  ----------------------------------------------------------------------------
  U_DEC : entity work.AddressDecoder
    port map (
      signal_in => alu_out_cpu,
      keys_out  => dec_keys_addr,
      VGA_out   => dec_vga_addr,
      RAM_addr  => dec_ram_addr,
      selRAM    => selRAM,
      selVGA    => selVGA,
      selKEYS   => selKEYS
    );

  ----------------------------------------------------------------------------
  -- Gating dos enables para a RAM (só ativa quando endereço é de RAM)
  ----------------------------------------------------------------------------
  weRAM_toRAM <= weRAM_cpu and selRAM;
  reRAM_toRAM <= reRAM_cpu and selRAM;
  eRAM_toRAM  <= eRAM_cpu  and selRAM;

  ----------------------------------------------------------------------------
  -- Periférico KEYS (somente leitura) → 0x8000_0010
  ----------------------------------------------------------------------------
  KEYS_word <= (31 downto 4 => '0') & KEY;

  ----------------------------------------------------------------------------
  -- MUX de leitura para a CPU (RAM / KEYS / demais=0)
  ----------------------------------------------------------------------------
  data_to_cpu <= RAM_out   when selRAM  = '1' else
                 KEYS_word when selKEYS = '1' else
                 (others => '0');

  ----------------------------------------------------------------------------
  -- MMIO VGA: escrita nos regs + pulso de 1 ciclo em WE
  ----------------------------------------------------------------------------
  weVGA      <= weRAM_cpu and selVGA;
  vga_offset <= dec_vga_addr(3 downto 2);  -- 00/01/10/11

  process (CLOCK_50)
  begin
    if rising_edge(CLOCK_50) then
      vga_we_strobe <= '0';  -- desarma por padrão

      if weVGA = '1' then
        case vga_offset is
          when "00" => vga_poscol_reg <= store_data_cpu(7 downto 0);
          when "01" => vga_poslin_reg <= store_data_cpu(7 downto 0);
          when "10" => vga_dado_reg   <= store_data_cpu(7 downto 0);
          when "11" => vga_we_strobe  <= '1';  -- pulso de 1 ciclo
          when others => null;
        end case;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------------
  -- RAM (endereçada pelo decodificador; recebe enables "gated")
  ----------------------------------------------------------------------------
  U_RAM : entity work.RAM
    port map (
      clk      => CLOCK_50,
      addr     => dec_ram_addr,
      data_in  => store_data_cpu,
      data_out => RAM_out,
      weRAM    => weRAM_toRAM,
      reRAM    => reRAM_toRAM,
      eRAM     => eRAM_toRAM,
      mask     => mask_ram_cpu
    );

  ----------------------------------------------------------------------------
  -- CPU (lendo do MUX "data_to_cpu")
  ----------------------------------------------------------------------------
  U_CPU : entity work.rv32i
    port map (
      CLK                  => CLOCK_50,
      ExtenderRAM_in       => data_to_cpu,
      ALU_out_cpu          => alu_out_cpu,
      out_StoreManager_cpu => store_data_cpu,
      mask_ram_cpu         => mask_ram_cpu,
      weRAM_cpu            => weRAM_cpu,
      reRAM_cpu            => reRAM_cpu,
      eRAM_cpu             => eRAM_cpu
    );

  ----------------------------------------------------------------------------
  -- driverVGA: larguras conforme o componente fornecido
  ----------------------------------------------------------------------------
  U_VGA_DRV : entity work.driverVGA
    port map (
      CLOCK_50         => CLOCK_50,
      VGA_HS           => VGA_HS,
      VGA_VS           => VGA_VS,
      VGA_R            => VGA_R,
      VGA_G            => VGA_G,
      VGA_B            => VGA_B,
      posLin           => vga_poslin_reg,    -- 8 bits
      posCol           => vga_poscol_reg,    -- 8 bits
      dadoIN           => vga_dado_reg,      -- 8 bits: [7:6]=cor, [5:0]=char
      VideoRAMWREnable => vga_we_strobe
    );

end architecture;
