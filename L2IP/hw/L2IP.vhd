library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_consts.all;

entity L2IP is
  port   (
    CLOCK_50 : in std_logic;
	 --CLK : in std_logic
	 HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);
	 LEDR : out std_logic_vector(9 downto 0);
	 SW : in std_logic_vector(9 downto 0);
	 FPGA_RESET_N : in std_logic
  );
end entity;

architecture behaviour of L2IP is

  -- add necessary signals here
  signal CLK : std_logic;
  
  signal MuxPc4ALU_out : std_logic_vector(31 downto 0);
  signal PC_out : std_logic_vector(31 downto 0);
  signal PC_out0 : std_logic_vector(31 downto 0);
  
  signal ROM_out : std_logic_vector(31 downto 0);
  