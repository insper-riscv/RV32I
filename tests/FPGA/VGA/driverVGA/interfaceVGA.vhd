library ieee;
use ieee.std_logic_1164.all;

entity interfaceVGA is
  generic (charPerLine: natural := 20;
			  charRAMAddrWidth: natural := 9; 
			  charSize: natural := 32;
			  charSizeLog: natural := 5
  );
  port(
	 CLOCK_50 : in std_logic;
    pixel_clk    :  in    std_logic;     --clock 25 MHz
    reset_n      :  in    std_logic;
	 WE           :  in    std_logic;
	 VideoMemAddress : in std_logic_vector(charRAMAddrWidth-1 DOWNTO 0);
	 VideoMemData    : in std_logic_vector(7 DOWNTO 0); 
    VGA_HS    : out std_logic;            --horiztonal sync pulse
    VGA_VS    : out std_logic;            --vertical sync pulse
    VGA_R     : out std_logic_vector(3 DOWNTO 0);
    VGA_G     : out std_logic_vector(3 DOWNTO 0);
    VGA_B     : out std_logic_vector(3 DOWNTO 0)
  );
end entity;

architecture behavior of interfaceVGA is
  signal disp_enable : std_logic;
  signal column    : std_logic_vector(9 downto 0);
  signal row       : std_logic_vector(9 downto 0);

begin
  ctrl: entity work.controladorVGA
  port map (
    pixel_clk => pixel_clk, reset_n => reset_n, HSync => VGA_HS, VSync => VGA_VS,
    disp_enable => disp_enable, column => column, row => row);
	 
  charGen: entity work.geradorCaracteres 
		generic map(charRAMAddrWidth => charRAMAddrWidth, charSize => charSize, charSizeLog => charSizeLog, charPerLine => charPerLine)
		port map(wrAddr => VideoMemAddress, wrData => VideoMemData, wrEnable => WE, disp_enable => disp_enable, column => column, row => row, 
					red => VGA_R, green => VGA_G, blue => VGA_B, rd_clk => pixel_clk, wr_clk => CLOCK_50);

  --COLOCAR O PIPELINE FINAL AQUI, COM: HS VC RGB
--  process(pixel_clk)
--  begin
--    if rising_edge(pixel_clk) then
--      HSync <= h_sync;
--      VSync <= v_sync;
--    end if;
--  end process;
end architecture;
