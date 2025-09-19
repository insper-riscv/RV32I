library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM IS
   generic (
          dataWidth: natural := 32;
          addrWidth: natural := 32;
          memoryAddrWidth:  natural := 7 );   
   port (
          addr : in  std_logic_vector (addrWidth-1 downto 0);
          data : out std_logic_vector (dataWidth-1 downto 0) );
end entity;

architecture rtl OF ROM IS
  type blocoMemoria IS ARRAY(0 TO 2**memoryAddrWidth - 1) OF std_logic_vector(dataWidth-1 downto 0);

  constant ROMDATA : blocoMemoria := (
  -- _start
  0  => x"00020117",  -- auipc sp,0x20
  1  => x"00010113",  -- mv sp,sp
  2  => x"11800293",  -- li t0,280
  3  => x"00010317",  -- auipc t1,0x10
  4  => x"FF430313",  -- addi t1,t1,-12
  5  => x"00010397",  -- auipc t2,0x10
  6  => x"FEC38393",  -- addi t2,t2,-20
  7  => x"00737C63",  -- bgeu t1,t2,0x34
  8  => x"0002AE03",  -- lw t3,0(t0)
  9  => x"01C32023",  -- sw t3,0(t1)
  10  => x"00428293",  -- addi t0,t0,4
  11  => x"00430313",  -- addi t1,t1,4
  12  => x"FEDFF06F",  -- j 0x1c
  13 => x"00010317",  -- auipc t1,0x10
  14 => x"FCC30313",  -- addi t1,t1,-52
  15  => x"00010397",  -- auipc t2,0x10
  16 => x"FC438393",  -- addi t2,t2,-60
  17 => x"00737863",  -- bgeu t1,t2,0x54
  18 => x"00032023",  -- sw zero,0(t1)
  19 => x"00430313",  -- addi t1,t1,4
  20 => x"FF5FF06F",  -- j 0x44
  21 => x"008000EF",  -- jal 0x5c

  -- hang
  22 => x"0000006F",  -- j 0x58

  -- main
  23 => x"800005B7",  -- lui a1,0x80000
  24 => x"80000637",  -- lui a2,0x80000
  25 => x"800006B7",  -- lui a3,0x80000
  26 => x"00458593",  -- addi a1,a1,4
  27 => x"00860613",  -- addi a2,a2,8
  28 => x"00C68693",  -- addi a3,a3,12
  29 => x"00000713",  -- li a4,0
  30 => x"80000337",  -- lui t1,0x80000
  31 => x"08000893",  -- li a7,128
  32 => x"00100813",  -- li a6,1
  33 => x"01400513",  -- li a0,20
  34 => x"01900E13",  -- li t3,25
  35 => x"00000793",  -- li a5,0
  36 => x"00F32023",  -- sw a5,0(t1)
  37 => x"00E5A023",  -- sw a4,0(a1)
  38 => x"01162023",  -- sw a7,0(a2)
  39 => x"0106A023",  -- sw a6,0(a3)
  40 => x"00178793",  -- addi a5,a5,1
  41 => x"FEA796E3",  -- bne a5,a0,0x90
  42 => x"00170713",  -- addi a4,a4,1
  43 => x"FFC710E3",  -- bne a4,t3,0x8c
  44 => x"80000537",  -- lui a0,0x80000
  45 => x"800005B7",  -- lui a1,0x80000
  46 => x"80000637",  -- lui a2,0x80000
  47 => x"00450513",  -- addi a0,a0,4
  48 => x"00858593",  -- addi a1,a1,8
  49 => x"00C60613",  -- addi a2,a2,12
  50 => x"00000693",  -- li a3,0
  51 => x"80000E37",  -- lui t3,0x80000
  52 => x"00200313",  -- li t1,2
  53 => x"00100893",  -- li a7,1
  54 => x"01400813",  -- li a6,20
  55 => x"01900E93",  -- li t4,25
  56 => x"00000713",  -- li a4,0
  57 => x"00E6C7B3",  -- xor a5,a3,a4
  58 => x"0017F793",  -- andi a5,a5,1
  59 => x"00EE2023",  -- sw a4,0(t3)
  60 => x"40F307B3",  -- sub a5,t1,a5
  61 => x"00D52023",  -- sw a3,0(a0)
  62 => x"0C07E793",  -- ori a5,a5,192
  63 => x"00F5A023",  -- sw a5,0(a1)
  64 => x"01162023",  -- sw a7,0(a2)
  65 => x"00170713",  -- addi a4,a4,1
  66 => x"FD071EE3",  -- bne a4,a6,0xe4
  67 => x"00168693",  -- addi a3,a3,1
  68 => x"FDD698E3",  -- bne a3,t4,0xe0
  69 => x"0000006F",  -- j 0x114

  70 to 127 => x"00000000"  -- restante zerado
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