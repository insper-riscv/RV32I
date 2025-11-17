library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_consts.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use std.env.all;

entity rv32i3stage_core_sim_test is
	generic (
	  ROM_FILE 		 : string := "default.hex";
	  SIG_BEGIN_ADDR : natural := 16#00000000#;
	  SIG_END_ADDR   : natural := 16#00000000#;
	  SIG_FILE       : string := "signature.out";
	  SIG_INIT_FILE  : string := ""
  	);
	-- port (
    	-- CLK   : in  std_logic;
		-- reset : in std_logic := '0'   
  	-- );
end entity;

architecture behaviour of rv32i3stage_core_sim_test is

	signal CLK   : std_logic := '0';
  	signal reset : std_logic := '1';

	signal CLK_IF, CLK_IDEXMEM : std_logic;

	signal rom_addr : std_logic_vector(31 downto 0);
	signal rom_rden : std_logic;
	signal rom_data : std_logic_vector(31 downto 0);

	signal core_ram_addr  : std_logic_vector(31 downto 0);
	signal core_ram_wdata : std_logic_vector(31 downto 0);
	signal core_ram_rdata : std_logic_vector(31 downto 0);
	signal core_ram_en    : std_logic;
	signal core_ram_wren  : std_logic;
	signal core_ram_rden  : std_logic;
	signal core_ram_byteena : std_logic_vector(3 downto 0);

	signal ram_addr    : std_logic_vector(31 downto 0);
	signal ram_wdata   : std_logic_vector(31 downto 0);
	signal ram_rdata   : std_logic_vector(31 downto 0);
	signal ram_en      : std_logic;
	signal ram_wren    : std_logic;
	signal ram_rden    : std_logic;
	signal ram_byteena : std_logic_vector(3 downto 0);

	signal dump_mode : std_logic := '0';
	signal dump_addr : std_logic_vector(31 downto 0) := (others=>'0');
	signal dump_rden : std_logic := '0';

	constant TOHOST_ADDR : std_logic_vector(31 downto 0) := x"20000000";
  	signal finished : std_logic := '0';
	signal wd_count   : natural := 0;
    constant MAX_CYCLES : natural := 100000;

begin
	CLK <= not CLK after 5 ns;
	process
	begin
		wait for 100 ns;
		reset <= '0';
		wait;
	end process;

	assert (SIG_END_ADDR >= SIG_BEGIN_ADDR)
	report "SIG_END_ADDR < SIG_BEGIN_ADDR" severity failure;
	assert (SIG_BEGIN_ADDR mod 4 = 0 and SIG_END_ADDR mod 4 = 0)
	report "Signature range not word-aligned" severity failure;

	sig_debug : process
	begin
		report "TB SIG_BEGIN_ADDR = " & integer'image(SIG_BEGIN_ADDR) severity note;
		report "TB SIG_END_ADDR   = " & integer'image(SIG_END_ADDR)   severity note;
		report "TB SIG_INIT_FILE  = " & SIG_INIT_FILE                 severity note;
		wait;  -- stop this process forever
	end process;

	CORE : entity work.rv32i3stage_core	
		port map (
			-- clock e reset
			clk  		=> CLK,
			clk_if_signal  	=> CLK_IF,
			clk_idexmem_signal	=> CLK_IDEXMEM,
			reset 		=> reset,

			----------------------------------------------------------------------
			-- Interface com a ROM (somente leitura)
			----------------------------------------------------------------------
			rom_addr => rom_addr,	-- endereço de instrução
			rom_rden => rom_rden,	-- enable de leitura
			rom_data => rom_data,	-- dados lidos da ROM

			----------------------------------------------------------------------
			-- Interface com a RAM (leitura e escrita)
			----------------------------------------------------------------------
			ram_addr    => core_ram_addr, 	-- endereço de palavra
			ram_wdata   => core_ram_wdata, 	-- dados a escrever (saida do store manager)
			ram_rdata   => core_ram_rdata, 	-- dados lidos
			ram_en      => core_ram_en, 		-- enable ram	
			ram_wren    => core_ram_wren,    -- write enable
			ram_rden    => core_ram_rden,    -- read enable
			ram_byteena => core_ram_byteena 	-- máscara de bytes
	);

	ROM : entity work.ROM_simulation
		generic map (ROM_FILE => ROM_FILE)  
		port map (
			addr 	=> rom_addr(31 downto 2),--word addressable
			clk 	=> CLK_IF,
			re 		=> rom_rden,
			data	=> rom_data
	);

	ram_addr    <= dump_addr when dump_mode='1' else core_ram_addr;
	ram_wdata   <= core_ram_wdata; -- TB never writes
	ram_rden    <= dump_rden                when dump_mode='1' else core_ram_rden;
	ram_wren    <= '0'                      when dump_mode='1' else core_ram_wren;
	ram_en      <= '1'                      when dump_mode='1' else core_ram_en;
	ram_byteena <= (others => '1')          when dump_mode='1' else core_ram_byteena;
	core_ram_rdata <= ram_rdata;

	RAM : entity work.RAM_simulation
		generic map (
			RAM_BASE_ADDR  => 16#20000000#,  -- same as link.ld RAM ORIGIN
			SIG_BEGIN_ADDR => SIG_BEGIN_ADDR,
			SIG_INIT_FILE  => SIG_INIT_FILE
		)
		port map(
			addr 		=> ram_addr(31 downto 2), -- word addressable
			mask 		=> ram_byteena,
			clk		 	=> CLK_IDEXMEM,
			data_in 	=> ram_wdata,
			reRAM 		=> ram_rden and ram_en,
			weRAM 		=> ram_wren and ram_en,
			eRAM 		=> ram_en,
			data_out 	=> ram_rdata
	);

	process(CLK_IDEXMEM)
    begin
        if rising_edge(CLK_IDEXMEM) then
            if finished = '0' then
                -- 1) Caso ideal: teste escreve em 'tohost'
                if (core_ram_wren = '1' and core_ram_en = '1' and core_ram_addr = TOHOST_ADDR) then
					report "TOHOST write detected, finishing test" severity note;
                    finished <= '1';

                -- 2) Fallback: limite de ciclos (watchdog interno)
                elsif wd_count = MAX_CYCLES then
                    report "Internal WATCHDOG reached MAX_CYCLES, forcing signature dump"
                      severity warning;
                    finished <= '1';
                else
                    wd_count <= wd_count + 1;
                end if;
            end if;
        end if;
    end process;

	monitor_sig_store : process(CLK_IDEXMEM)
	begin
	if rising_edge(CLK_IDEXMEM) then
		-- detect stores from the core into begin_signature
		if core_ram_wren = '1' and core_ram_en = '1' and
		core_ram_addr = std_logic_vector(to_unsigned(SIG_BEGIN_ADDR, 32)) then
		report "STORE to begin_signature: data=" &
				to_hstring(core_ram_wdata)
			severity note;
		end if;
	end if;
	end process;


	---------------------------------------------------------------------------
	-- Signature dump FSM (handles synchronous RAM read)
	---------------------------------------------------------------------------
	dump_proc: process(CLK_IDEXMEM)
		file sf : text;
		variable L          : line;
		variable addr_next  : natural := 0;
		variable prev_valid : boolean := false;
		type state_t is (IDLE, SETUP, READ, FLUSH, DONE);
		variable st : state_t := IDLE;
	begin
		if rising_edge(CLK_IDEXMEM) then
			case st is

				when IDLE =>
					if finished = '1' then
						-- Switch RAM mux to dump_mode and open file
						dump_mode   <= '1';
						file_open(sf, SIG_FILE, write_mode);

						addr_next   := SIG_BEGIN_ADDR;
						dump_rden   <= '0';
						prev_valid  := false;
						st          := SETUP;
					end if;

				when SETUP =>
					-- First READ: issue address = begin_signature,
					-- but don't write yet (data will be valid next cycle)
					if addr_next < SIG_END_ADDR then
						dump_addr <= std_logic_vector(to_unsigned(addr_next, 32));
						dump_rden <= '1';
						addr_next := addr_next + 4;
						prev_valid := false;
						st := READ;
					else
						dump_rden <= '0';
						file_close(sf);
						st := DONE;
					end if;

				when READ =>
					-- Data for the *previous* address is now in ram_rdata
					if prev_valid then
						hwrite(L, ram_rdata);
						writeline(sf, L);
					end if;

					if addr_next < SIG_END_ADDR then
						-- Issue next address
						dump_addr <= std_logic_vector(to_unsigned(addr_next, 32));
						dump_rden <= '1';
						addr_next := addr_next + 4;
						prev_valid := true;
					else
						-- No more addresses to issue; one last word pending
						dump_rden  <= '0';
						st         := FLUSH;
					end if;

				when FLUSH =>
					-- Write the final pending word
					if prev_valid then
						hwrite(L, ram_rdata);
						writeline(sf, L);
						prev_valid := false;
					end if;
					file_close(sf);
					st := DONE;

				when DONE =>
					stop;  -- end simulation cleanly

			end case;
		end if;
	end process;

end architecture;