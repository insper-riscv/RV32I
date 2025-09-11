library ieee;
use ieee.std_logic_1164.all;
use work.rv32i_ctrl_pkg.all;

entity ExtenderRAM is
    port
    (
        RAM_out : in std_logic_vector(31 downto 0);
		opExRAM : in op_ex_ram_t;
        RAMExt  : out std_logic_vector(31 downto 0)
    );
end entity;

architecture comportamento of ExtenderRAM is

	signal ram_lb, ram_lbu, ram_lh, ram_lhu, ram_lw : std_logic_vector(31 downto 0);

begin

  ram_lb  <= (31 downto 8  => RAM_out(7))  & RAM_out(7 downto 0);
  ram_lbu <= (31 downto 8  => '0')         & RAM_out(7 downto 0);
  ram_lh  <= (31 downto 16 => RAM_out(15)) & RAM_out(15 downto 0);
  ram_lhu <= (31 downto 16 => '0')         & RAM_out(15 downto 0);
  ram_lw  <= RAM_out;

  with opExRAM select
    RAMExt <= ram_lb  when RAM_LB,
              ram_lbu when RAM_LBU,
              ram_lh  when RAM_LH,
              ram_lhu when RAM_LHU,
              ram_lw  when RAM_LW,
              (others=>'0') when others;

end architecture;