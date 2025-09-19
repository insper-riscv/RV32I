library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity geradorCaracteres is

   generic(
	charRAMAddrWidth: natural := 13; 
	charSize: natural := 8;
	charSizeLog: natural := 3;
	charPerLine: natural := 80	
	);
	
	port(
	wrAddr      :	in    std_logic_vector(charRAMAddrWidth-1 downto 0);
	wrData      :  in    std_logic_vector(7 downto 0);
	wrEnable    :  in    std_logic;
	disp_enable :  in    std_logic;  --display enable ('1' = display time, '0' = blanking time)
	column      :  in    std_logic_vector(9 downto 0);    --horizontal pixel coordinate
	row         :  in    std_logic_vector(9 downto 0);    --vertical pixel coordinate
	wr_clk   	:  in    std_logic;
	rd_clk   	:  in    std_logic;
	red         :  out   std_logic_vector(3 downto 0) := (others => '0');
	green       :  out   std_logic_vector(3 downto 0) := (others => '0');
	blue        :  out	std_logic_vector(3 downto 0) := (others => '0')
	);
	
end entity;



architecture behavior of geradorCaracteres is

  signal ponto     :  std_logic;
  signal selMUX    :  std_logic_vector(charSizeLog-1 downto 0);
  signal charMapAddress    :  std_logic_vector(10 downto 0);
  signal charMapDataOut    :  std_logic_vector(charSize-1 downto 0);
  signal charRAMDataOut    :  std_logic_vector(7 downto 0);
  signal contagemColunas   :  std_logic_vector(6 downto 0);
  signal charRAMAddress    :  std_logic_vector(charRAMAddrWidth-1 downto 0);
  signal colorRAMDataOut   :  std_logic_vector(11 downto 0);

begin

	--Um novo caracter a cada charSize pixels
	contagemColunas <= std_logic_vector(resize(unsigned(column(9 downto charSizeLog)), contagemColunas'length));

	--Calcula o Endereco do Caractere na Memoria RAM 
	charRAMAddress <= std_logic_vector(unsigned(charPerLine * unsigned(row(9 downto charSizeLog))) + unsigned(contagemColunas))(charRAMAddrWidth-1 downto 0);

	caracRAM : entity work.simple_dual_port_ram_dual_clock
		generic map (DATA_WIDTH => 8, ADDR_WIDTH => charRAMAddrWidth)
		port map (
		wclk => wr_clk, rclk => rd_clk, raddr => charRAMAddress, waddr => wrAddr,
		data => wrData, we => wrEnable, q => charRAMDataOut);
		
colorRAM	:	entity work.memoriaROMVGA
		generic map (
		dataWidth => 12,
		addrWidth => 2
		)
		port map (
		Endereco => charRAMDataOut(7 downto 6),
		Dado => colorRAMDataOut
		);

tipoROM	:	if (charPerLine = 80) generate
				caracROM : entity work.ROMcaracteres(size8x8)
				generic map(
				dataWidth => 8
				)
				port map (
				romAddress => charMapAddress,
				dataOut => charMapDataOut
				);
	
				elsif (charPerLine = 40) generate 
				caracROM : entity work.ROMcaracteres(size16x16) generic map(dataWidth => 16)
				port map (
				romAddress => charMapAddress, dataOut => charMapDataOut
				);
				
				else generate -- charPerLine = 20
				caracROM : entity work.ROMcaracteres(size32x32) generic map(dataWidth => 32)	
				port map (
				romAddress => charMapAddress,
				dataOut => charMapDataOut
				);
				end generate;
	
   -- Address
   charMapAddress <= std_logic_vector(resize(unsigned(charRAMDataOut(5 downto 0) & row(charSizeLog-1 downto 0)), charMapAddress'length));
   selMUX <= column(charSizeLog-1 downto 0);

	muxPixel : entity work.muxGenerico 
		generic map (
		inputSize => charSize,
		selSize => charSizeLog,
		invertido => TRUE
		)
		port map (
		input => charMapDataOut,
		sel => selMUX,
		output => ponto
		);
		
   process(rd_clk, disp_enable, ponto)
   begin
      if rising_edge(rd_clk) then
         if(disp_enable = '1') then
            if ponto = '1' then
               red   <= colorRAMDataOut(11 downto 8); -- (others => '1'); 
               green <= colorRAMDataOut(7 downto 4);
               blue  <= colorRAMDataOut(3 downto 0);
            else
               red   <= (others => '0');  -- regBackgroundColor(11 downto 8);
               green <= (others => '0');  -- regBackgroundColor(7 downto 4);
               blue  <= (others => '0');  -- regBackgroundColor(3 downto 0);
            end if;
         else
            red   <= (others => '0');  -- regBlankColor(11 downto 8);
            green <= (others => '0');  -- regBlankColor(7 downto 4);
            blue  <= (others => '0');  -- regBlankColor(3 downto 0);
         end if;
      end if;
   end process;
end architecture;
