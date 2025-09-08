library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_ctrl_pkg.all;

entity ALU is

  generic (DATA_WIDTH:natural:=32);

    port (
        select_function : in  std_logic_vector(3 downto 0);
        dA        : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        dB        : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        -- overflow        : out std_logic;
        destination     : out std_logic_vector((DATA_WIDTH - 1) downto 0)
    );

end entity;

architecture RTL of ALU is

  signal op                       : alu_op_t;
  signal beff                     : std_logic_vector(DATA_WIDTH-1 downto 0); -- b efetivo (positivo se for soma, negativo se for subtração)
  signal cin                      : unsigned(0 downto 0); -- "0" para adição, mas "1" para subtração, pois representa o "+1" necessário para o complemento de 2 (not(b)+1)
  signal addsub_ext               : unsigned(DATA_WIDTH downto 0); -- reultado final com bit extra pra capturar o carry out
  signal addsub_res               : std_logic_vector(DATA_WIDTH-1 downto 0); -- resultado final da soma/subtração sem o bit extra de carry out
  signal and_res, or_res, xor_res : std_logic_vector(DATA_WIDTH-1 downto 0); -- resultados finais de cada operação
  signal sll_res, srl_res, sra_res: std_logic_vector(DATA_WIDTH-1 downto 0);
  signal slt_res, sltu_res        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal shamt_u5                 : unsigned(4 downto 0);

begin

  op <= decode_alu_ctrl(select_function);

  beff <= (not dB) when (op = ALU_SUB) else dB;
  cin <= "1" when op = ALU_SUB' else "0";
  addsub_res <= std_logic_vector(unsigned(dA) + unsigned(beff) + cin); -- faz soma da entrada A com entrada B efetiva (negativada se a operação for subtração) e com cin (para complemento de 2 do B)

  and_res <= dA and dB;
  or_res <= dA or dB;
  xor_res <= dA xor dB;

  shamt_u5 <= unsigned(dB(4 downto 0)); -- calcula shift amount pras operacoes de tipo R e I que precisam de shift
  sll_res <= std_logic_vector(shift_left(unsigned(dA), to_integer(shamt_u5)));
  srl_res <= std_logic_vector(shift_right(unsigned(dA), to_integer(shamt_u5)));
  sra_res <= std_logic_vector(shift_right(signed(dA), to_integer(shamt_u5)));

  slt_res <= (others => '0');
  slt_res(0) <= '1' when signed(dA) <  signed(dB) else '0';
  sltu_res <= (others => '0');
  sltu_res(0) <= '1' when unsigned(dA) < unsigned(dB) else '0';

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
      when others => destination <= (others => '0');
    end case;
  end process;

end architecture;