library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity ROMcaracteres is
  generic (dataWidth: natural := 8);
  port (
    romAddress  : in  std_logic_vector(10 downto 0);
    dataOut     : out std_logic_vector(dataWidth-1 downto 0) 
  );
end entity;

architecture size8x8 of ROMcaracteres is
  type t_rom is array (0 to 2**11-1) of std_logic_vector (0 to 7);
  signal charRom : t_rom;
  attribute ram_init_file : string;
  attribute ram_init_file of charRom:
  signal is "charMapROM_8x8_2k.mif";
begin
  dataOut <= std_logic_vector(charRom(to_integer(unsigned(romAddress))));
end architecture;

architecture size16x16 of ROMcaracteres is
  type t_rom is array (0 to 2**11-1) of std_logic_vector (0 to 15);
  signal charRom : t_rom;
  attribute ram_init_file : string;
  attribute ram_init_file of charRom:
  signal is "charMapROM_16x16_1K-RelogioDesComp.mif";
begin
  dataOut <= std_logic_vector(charRom(to_integer(unsigned(romAddress))));
end architecture;

architecture size32x32 of ROMcaracteres is
  type t_rom is array (0 to 2**11-1) of std_logic_vector (0 to 31);
  signal charRom : t_rom;
  attribute ram_init_file : string;
  attribute ram_init_file of charRom:
  signal is "charMapROM_32x32_2K";
begin
  dataOut <= std_logic_vector(charRom(to_integer(unsigned(romAddress))));
end architecture;