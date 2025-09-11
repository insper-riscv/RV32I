library ieee;
use ieee.std_logic_1164.all;
use work.rv32i_ctrl_pkg.all;

entity Extender is
    port
    (
        signal_in : in std_logic_vector(31 downto 0);
		opExImm : in op_ex_imm_t;
		opExRAM : in op_ex_ram_t;
        signalExt : out std_logic_vector(31 downto 0)
    );
end entity;

architecture comportamento of Extender is

	signal imm_i, imm_i_shamt, imm_s, , imm_u, imm_jal, imm_jalr : std_logic_vector(31 downto 0);

begin

  imm_i       <= (31 downto 12 => Inst(31)) & Inst(31 downto 20);
  imm_i_shamt <= 
  imm_s       <= (31 downto 12 => Inst(31)) & Inst(31 downto 25) & Inst(11 downto 7);
  imm_u       <= Inst(31 downto 12) & (11 downto 0 => '0');
  imm_jal     <= (31 downto 21 => Inst(31)) & Inst(31) & Inst(19 downto 12) & Inst(20) & Inst(30 downto 21) & '0';
  imm_jalr    <=

  with opExImm select
    ImmExt <= imm_i when IMM_I,
              imm_s when IMM_S,
              
              imm_u when IMM_U,
              imm_j when IMM_J,
              (others=>'0') when others;

end architecture;