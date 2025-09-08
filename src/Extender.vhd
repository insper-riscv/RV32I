library ieee;
use ieee.std_logic_1164.all;
use work.rv32i_ctrl_pkg.all;

entity Extender is
    port
    (
        Inst   : in std_logic_vector(31 downto 0);
		selImm : in imm_src_t;
        ImmExt : out std_logic_vector(31 downto 0)
    );
end entity;

architecture comportamento of Extender is

	signal imm_i, imm_s, imm_b, imm_u, imm_j : std_logic_vector(31 downto 0);

begin

  imm_i <= (31 downto 12 => Inst(31)) & Inst(31 downto 20);
  imm_s <= (31 downto 12 => Inst(31)) & Inst(31 downto 25) & Inst(11 downto 7);
  imm_b <= (31 downto 13 => Inst(31)) & Inst(31) & Inst(7) & Inst(30 downto 25) & Inst(11 downto 8) & '0';
  imm_u <= Inst(31 downto 12) & x"000";
  imm_j <= (31 downto 21 => Inst(31)) & Inst(31) & Inst(19 downto 12) & Inst(20) & Inst(30 downto 21) & '0';

  with selImm select
    ImmExt <= imm_i when IMM_I,
              imm_s when IMM_S,
              imm_b when IMM_B,
              imm_u when IMM_U,
              imm_j when IMM_J;

end architecture;