LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity driverVGA IS

   generic (
		charPerLine			:	natural	:=	20;
		charRAMAddrWidth	:	natural	:=	9; 
		charSize				:	natural	:=	32;
		charSizeLog			:	natural	:=	5
   );
	
	port(
		CLOCK_50				:	IN		std_logic;								--clock 50 MHz
		VGA_HS				:	out	std_logic;								--horiztonal sync pulse
		VGA_VS				:	out	std_logic;								--vertical sync pulse
		VGA_R					:	out	std_logic_vector(3 DOWNTO 0);
		VGA_G					:	out	std_logic_vector(3 DOWNTO 0);
		VGA_B					:	out	std_logic_vector(3 DOWNTO 0);
		posLin				:	IN		std_logic_vector(7 DOWNTO 0); 
		posCol				:	IN		std_logic_vector(7 DOWNTO 0);
		dadoIN				:  IN		std_logic_vector(7 DOWNTO 0); 
		VideoRAMWREnable	:	IN		std_logic
	); 
	
end entity;



architecture arc OF driverVGA IS

	signal pixel_clk			:	std_logic;
	signal videoMemData		:	std_logic_vector(7 DOWNTO 0);
	signal VideoMemAddress	:	std_logic_vector(charRAMAddrWidth-1 DOWNTO 0);
	signal calcPosLin			:	std_logic_vector(8 DOWNTO 0);
	signal contador			:	integer range 0 to 299 := 0;

begin

	-- Usar para pixelCLK = 25 MHz
	clkDiv:process(CLOCK_50)
	begin
		if(rising_edge(CLOCK_50))then
			pixel_clk <= not pixel_clk;
		end if;
	end process;


interface: entity work.interfaceVGA
	generic map (
		charRAMAddrWidth => charRAMAddrWidth,
		charSize => charSize, 
		charSizeLog => charSizeLog,
		charPerLine => charPerLine
		)					
	port map (
		pixel_clk => pixel_clk,
		reset_n => '1',
		VGA_HS => VGA_HS,
		VGA_VS => VGA_VS,
		VGA_R => VGA_R,
		VGA_G => VGA_G,
		VGA_B => VGA_B,
		VideoMemAddress => VideoMemAddress,
		VideoMemData => dadoIN,
		WE => VideoRAMWREnable,
		CLOCK_50 => CLOCK_50
		);
				
		
CalcMemAddr :  entity work.calcMemAddr  
	port map(
		posLIN => "0" & posLIN,
		posCOL =>  "0" & posCOL,
		MemAddrVALUE => VideoMemAddress
		);
	
end architecture;
