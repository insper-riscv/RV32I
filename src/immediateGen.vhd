library ieee;
use ieee.std_logic_1164.all;
use work.rv32i_ctrl_pkg.all;

entity immediateGen is
    port
    (
        instru : in std_logic_vector(31 downto 0);
		ImmSRC : in imm_src_t;
        ImmExt: out std_logic_vector(31 downto 0)
    );
end entity;

architecture comportamento of immediateGen is
begin
							 
  imm_i <= (31 downto 12 => instru(31)) & instru(31 downto 20);
  imm_s <= (31 downto 12 => instru(31)) & instru(31 downto 25) & instru(11 downto 7);
  imm_b <= (31 downto 13 => instru(31)) & instru(31) & instru(7) & instru(30 downto 25) & instru(11 downto 8) & '0';
  imm_u <= instru(31 downto 12) & x"000";
  imm_j <= (31 downto 21 => instru(31)) & instru(31) & instru(19 downto 12) & instru(20) & instru(30 downto 21) & '0';

  with ImmSRC select
    ImmExt <= imm_i when IMM_I,
              imm_s when IMM_S,
              imm_b when IMM_B,
              imm_u when IMM_U,
              imm_j when IMM_J;

end architecture;