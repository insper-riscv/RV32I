library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_ctrl_pkg.all;

entity ALU is

  generic (DATA_WIDTH:natural:=32);

    port (
        op          : in  alu_op_t;
        dA          : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        dB          : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        destination : out std_logic_vector((DATA_WIDTH - 1) downto 0)
    );

end entity;

architecture RTL of ALU is

  signal addsub_res               : std_logic_vector(DATA_WIDTH-1 downto 0); -- resultado final da soma/subtração
  signal and_res, or_res, xor_res : std_logic_vector(DATA_WIDTH-1 downto 0); -- resultados finais de cada operação
  signal sll_res, srl_res, sra_res: std_logic_vector(DATA_WIDTH-1 downto 0);
  signal slt_res, sltu_res        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal shamt_u5                 : unsigned(4 downto 0);

begin

  addsub_res <= std_logic_vector(signed(dA) - signed(dB)) when op = ALU_SUB else std_logic_vector(signed(dA) + signed(dB));
  and_res <= dA and dB;
  or_res <= dA or dB;
  xor_res <= dA xor dB;

  shamt_u5 <= unsigned(dB(4 downto 0)); -- calcula shift amount pras operacoes de tipo R e I que precisam de shift
  sll_res <= std_logic_vector(shift_left(unsigned(dA), to_integer(shamt_u5)));
  srl_res <= std_logic_vector(shift_right(unsigned(dA), to_integer(shamt_u5)));
  sra_res <= std_logic_vector(shift_right(signed(dA), to_integer(shamt_u5)));

  slt_res  <= (0 => '1', others => '0') when signed(dA)   < signed(dB)   else (others => '0');
  sltu_res <= (0 => '1', others => '0') when unsigned(dA) < unsigned(dB) else (others => '0');
  
  process(all)
  begin
    case op is
      when ALU_ADD => destination <= addsub_res;
      when ALU_SUB => destination <= addsub_res;
      when ALU_AND => destination <= and_res;
      when ALU_OR => destination <= or_res;
      when ALU_XOR => destination <= xor_res;
      when ALU_SLT => destination <= slt_res;
      when ALU_SLTU => destination <= sltu_res;
      when ALU_SLL => destination <= sll_res;
      when ALU_SRL => destination <= srl_res;
      when ALU_SRA => destination <= sra_res;
      when ALU_PASS_A => destination <= dA;
      when ALU_PASS_B => destination <= dB;
      when ALU_ILLEGAL => destination <= (others => '0');
      when others => destination <= (others => '0');
    end case;
  end process;

end architecture;