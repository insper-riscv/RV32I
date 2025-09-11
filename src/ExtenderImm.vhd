library ieee;
use ieee.std_logic_1164.all;
use work.rv32i_ctrl_pkg.all;

entity ExtenderImm is
    port
    (
        Inst    : in std_logic_vector(19 downto 0);
		opExImm : in op_ex_imm_t;
        ImmExt  : out std_logic_vector(31 downto 0)
    );
end entity;

architecture comportamento of ExtenderImm is

	signal imm_i, imm_i_shamt, imm_s, imm_u, imm_jal, imm_jalr : std_logic_vector(31 downto 0);

begin

  imm_i       <= (31 downto 11 => Inst(11)) & Inst(11 downto 0);
  imm_i_shamt <= (31 downto 5 => '0') & Inst(4 downto 0);
  imm_s       <= (31 downto 12 => Inst(31)) & Inst(31 downto 25) & Inst(11 downto 7);
  imm_u       <= Inst & (11 downto 0 => '0');
  imm_jal     <= (31 downto 20 => Inst(31)) & Inst(19 downto 12) & Inst(20) & Inst(30 downto 21) & '0';
  imm_jalr    <= (31 downto 12 => Inst(31)) & Inst(31 downto 20);

  with opExImm select
    ImmExt <= imm_i when IMM_I,
              imm_i_shamt when IMM_I_shamt,
              imm_s when IMM_S,
              imm_u when IMM_U,
              imm_jal when IMM_JAL,
              imm_jalr when IMM_JALR,
              (others=>'0') when others;

end architecture;