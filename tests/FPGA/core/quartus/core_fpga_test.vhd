library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_consts.all;

entity core_fpga_test is
	port (
		CLOCK_50 : in std_logic;
		FPGA_RESET_N : in std_logic := '1';
		LEDR : out std_logic_vector(9 downto 0) := (others => '0')
  	);
end entity;

architecture behaviour of core_fpga_test is

	-- IF stage: barramento unico compartilhado por BOOT_ROM e FLASH
	-- (ver rv32im_pipeline_core.vhd is_boot_rom_if/is_boot_rom_d)
	signal if_addr : std_logic_vector(31 downto 0);
	signal if_rden : std_logic;
	signal boot_rom_data : std_logic_vector(31 downto 0);
	signal flash_data : std_logic_vector(31 downto 0);

	-- Estagio MEM: segunda porta da FLASH, so' para o copy-loop de
	-- .data em boot_rom.S (ver rv32im_pipeline_core.vhd flash_addr2 --
	-- confirmado em hardware real que sem isso .data nunca era
	-- copiado: bss/computo funcionavam, .data inicializado ficava
	-- zerado, ja que o `lw` do copy-loop nao alcancava FLASH).
	signal flash_addr2 : std_logic_vector(31 downto 0);
	signal flash_rden2 : std_logic;
	signal flash_data2 : std_logic_vector(31 downto 0);

	-- RAM's In-System Memory Content Editor (JTAG) addresses it as a
	-- 0-based array relative to memory.ram_base (see
	-- riscv_tools.mailbox.word_offset's own docstring: "relative=True
	-- ... What mem_edit's JTAG primitives expect"), NOT the CPU's raw
	-- absolute address. Every previous memory-map round got this for
	-- free by accident (ram_base was always chosen as a power-of-two
	-- exactly matching RAM's own address width, so truncating the raw
	-- address to that width happened to equal subtracting ram_base) --
	-- broke silently the first time that stopped being true (ram_base
	-- = 0x11000 in that round, not aligned to RAM's 16-bit width), confirmed on
	-- real hardware: a debug LED wired directly to the mailbox write
	-- (ram_addr = mailbox_addr) lit up correctly, proving the CORE
	-- writes the right byte address -- but JTAG reads (computed
	-- RAM-relative, per mem_edit's own convention) always came back
	-- 0, since RAM's OWN address port was indexing by the untranslated
	-- raw address instead. GHDL sim never hit this: its own testbench
	-- (test_c_program.py) snoops the raw ram_addr bus directly rather
	-- than reading back RAM's internal array by JTAG-style 0-based
	-- index, so this class of bug is invisible to it by construction.
	constant RAM_BASE_WORD : unsigned(19 downto 0) := to_unsigned(16#00008000# / 4, 20);
	signal ram_word_addr : unsigned(15 downto 0);

	signal ram_addr : std_logic_vector(31 downto 0);
	signal ram_wdata : std_logic_vector(31 downto 0);
	signal ram_rdata : std_logic_vector(31 downto 0);
	signal ram_en : std_logic;
	signal ram_wren : std_logic;
	signal ram_rden : std_logic;
	signal ram_byteena : std_logic_vector(3 downto 0);

	signal pll_clk_if     : std_logic;
	signal pll_clk_idexmem: std_logic;
	signal pll_locked     : std_logic;

	-- Mantém core em reset até o PLL estar travado, ou enquanto o
	-- botão físico de reset (FPGA_RESET_N, ativo em nível baixo) for
	-- pressionado o que permite reiniciar o core sem reconfigurar a FPGA
	-- (ex: depois de carregar um novo conteúdo de ROM via JTAG).
	signal core_reset : std_logic;

begin

	-- rst era amarrado em '0' antes -- nunca pulsado. gui_pll_auto_reset
	-- esta' "Off" nesta IP (ver pll.vhd), ou seja o PLL NAO tenta
	-- re-travar sozinho se perder o lock por qualquer motivo (ruido de
	-- alimentacao, etc.) -- fica preso ate a FPGA inteira ser
	-- reconfigurada, mesmo que o resto do sistema (JTAG TAP, que e' um
	-- bloco fixo independente desta logica) continue respondendo
	-- normalmente. Ligar ao botao fisico de reset da' um caminho de
	-- recuperacao mais barato que desligar a placa inteira -- se essa
	-- for mesmo a causa da instabilidade intermitente de JTAG vista em
	-- HARDWARE_PROGRAMMING.md/docs/DATA_HARVARD_BUG.md, apertar o botao
	-- deve bastar em vez de precisar de power-cycle completo.
	pll_inst : entity work.pll
    port map (
      refclk   => CLOCK_50,
      rst      => not FPGA_RESET_N,
      outclk_0 => pll_clk_if,
      outclk_1 => pll_clk_idexmem,
      outclk_2 => open,
      locked   => pll_locked
    );

	core_reset <= (not pll_locked) or (not FPGA_RESET_N);

	-- Status LEDs -- ver README.md/docs para o mapa completo. Baratos
	-- o bastante pra deixar permanentes (nao so' debug de bring-up):
	-- dao um jeito de ver, so' olhando a placa, se o problema e' antes
	-- (PLL/reset) ou depois (logica do core/software) do reset, sem
	-- precisar de uma sessao JTAG.
	LEDR(1) <= pll_locked;       -- '1' travado (deveria ficar sempre aceso)
	LEDR(2) <= FPGA_RESET_N;     -- '1' botao de reset fisico solto
	LEDR(3) <= not core_reset;   -- '1' core fora de reset, rodando

	CORE : entity work.rv32im_pipeline_core
		port map (
			clk          => pll_clk_idexmem,
			reset        => core_reset,

			if_addr       => if_addr,
			if_rden       => if_rden,
			boot_rom_data => boot_rom_data,
			flash_data    => flash_data,

			flash_addr2 => flash_addr2,
			flash_rden2 => flash_rden2,
			flash_data2 => flash_data2,

			ram_addr    => ram_addr,
			ram_wdata   => ram_wdata,
			ram_rdata   => ram_rdata,
			ram_en      => ram_en,
			ram_wren    => ram_wren,
			ram_rden    => ram_rden,
			ram_byteena => ram_byteena
	);

	-- BOOT_ROM: fixa, gravada uma unica vez (nunca reescrita via JTAG
	-- por teste -- ver config.yaml quartus.boot_rom_mif_target). So'
	-- precisa de porta unica agora -- nada mais le dado direto dela
	-- (ver rv32im_pipeline_core.vhd, estagio MEM so' fala com RAM).
	BOOT_ROM : entity work.boot_rom1port
    port map (
      address => if_addr(10 downto 2),
      clock   => pll_clk_if,
      rden    => if_rden,
      wren    => '0',
      data    => (others => '0'),
      q       => boot_rom_data
    );

	-- FLASH: "firmware" desse teste, reescrita por teste via JTAG (ver
	-- config.yaml quartus.rom_mif_target/rom_mem_instances) -- mesmo
	-- papel que a antiga ROM tinha. Porta 1 (esta), so' busca de
	-- instrucao. BOOT_ROM continua so' single-port -- nunca tem .data
	-- proprio, nunca precisa ser lido como dado (ver FLASH_MEM abaixo
	-- pra FLASH).
	FLASH : entity work.flash1port
    port map (
      address => if_addr(14 downto 2),
      clock   => pll_clk_if,
      rden    => if_rden,
      wren    => '0',
      data    => (others => '0'),
      q       => flash_data
    );

	-- RAM-relative word address (see RAM_BASE_WORD's own comment above)
	ram_word_addr <= resize(unsigned(ram_addr(21 downto 2)) - RAM_BASE_WORD, 16);

	RAM : entity work.ram1port
	 port map (
		address => std_logic_vector(ram_word_addr),
		byteena => ram_byteena,
		clock   => pll_clk_idexmem,
		data    => ram_wdata,
		rden    => ram_rden and ram_en,
		wren    => ram_wren and ram_en,
		q       => ram_rdata
	 );

	-- FLASH_MEM: segunda copia fisica da FLASH, so' para leitura de
	-- dado pelo estagio MEM (mesmo clock que a RAM, ja' que e' o MEM
	-- stage que consome as duas). Nao e' uma "porta B" da mesma IP --
	-- ver o comentario em ips/FLASH_MEM1PORT/flash_mem1port.vhd para
	-- o porque (ENABLE_RUNTIME_MOD nao compila em DUAL_PORT nesta
	-- edicao do Quartus). Instanciada DEPOIS de RAM de proposito, para
	-- nao mudar o indice de instancia JTAG que RAM ja' tem (2) -- ver
	-- config.yaml quartus.ram_mem_instance/mailbox_mem_instance.
	FLASH_MEM : entity work.flash_mem1port
    port map (
      address => flash_addr2(14 downto 2),
      clock   => pll_clk_idexmem,
      rden    => flash_rden2,
      wren    => '0',
      data    => (others => '0'),
      q       => flash_data2
    );

	 blink : entity work.Blinky
	 port map (
		clk => CLOCK_50,
		led => LEDR(0)
	 );

end architecture;
