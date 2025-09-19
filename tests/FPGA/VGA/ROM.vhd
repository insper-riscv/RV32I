library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM IS
   generic (
          dataWidth: natural := 32;
          addrWidth: natural := 32;
          memoryAddrWidth:  natural := 6 );   
   port (
          addr : in  std_logic_vector (addrWidth-1 downto 0);
          data : out std_logic_vector (dataWidth-1 downto 0) );
end entity;

architecture rtl OF ROM IS
  type blocoMemoria IS ARRAY(0 TO 2**memoryAddrWidth - 1) OF std_logic_vector(dataWidth-1 downto 0);

constant ROMDATA : blocoMemoria := (
  -- _start
  0  => x"002002B7",  -- lui   t0,0x2          ; t0 = 8192
  1  => x"00028293",  -- addi  t0,t0,0
  2  => x"00200337",  -- lui   t1,0x2          ; t1 = 8193
  3  => x"00130313",  -- addi  t1,t1,1
  4  => x"002003B7",  -- lui   t2,0x2          ; t2 = 8194
  5  => x"00238393",  -- addi  t2,t2,2
  6  => x"00200E13",  -- addi  t3,x0,10        ; posCol value
  7  => x"00200E93",  -- addi  t4,x0,10        ; posLin value
  8  => x"00200F13",  -- addi  t5,x0,2         ; dadoIN value
  9  => x"01C28023",  -- sb    t3,0(t0)        ; *8192 = 10
  10 => x"01D30023",  -- sb    t4,0(t1)        ; *8193 = 10
  11 => x"01E38023",  -- sb    t5,0(t2)        ; *8194 = 2
  12 => x"FF5FF06F",  -- jal   x0, -12         ; loop back to instr 9

  13 to 63 => x"00000000"
);

  -- (Para Quartus) mantenha o atributo; GHDL ignora.
  signal memROM : blocoMemoria := ROMDATA;
  -- attribute ram_init_file : string;
  -- attribute ram_init_file of memROM : signal is "initROM.mif";

  signal localAddress : std_logic_vector(memoryAddrWidth-1 downto 0);
begin
  localAddress <= addr(memoryAddrWidth+1 downto 2);
  data <= memROM(to_integer(unsigned(localAddress)));
end architecture;