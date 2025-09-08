library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ULA32bits is

  generic (DATA_WIDTH:natural:=32);

    port (
        select_function : in  std_logic_vector(3 downto 0);
        source_1        : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        source_2        : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        overflow        : out std_logic;
        destination     : out std_logic_vector((DATA_WIDTH - 1) downto 0)
    );

end entity;

architecture RTL of ULA32bits is

  type alu_op_t is (ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR, ALU_SLT, ALU_SLTU, ALU_SLL, ALU_SRL, ALU_SRA, ALU_ILLEGAL); -- todas instruções aceitas pela ULA

  function decode_alu_ctrl(s:std_logic_vector(3 downto 0)) return alu_op_t is
  begin
    case s is
      when "0000"=>return ALU_ADD;
      when "0001"=>return ALU_SUB;
      when "0010"=>return ALU_AND;
      when "0011"=>return ALU_OR;
      when "0100"=>return ALU_XOR;
      when "0101"=>return ALU_SLT;
      when "0110"=>return ALU_SLTU;
      when "1000"=>return ALU_SLL;
      when "1001"=>return ALU_SRL;
      when "1010"=>return ALU_SRA;
      when others=>return ALU_ILLEGAL;
    end case;
  end function;

  signal op                       : alu_op_t;
  signal sub_op                   : std_logic; -- "1" quando op for sub
  signal beff                     : std_logic_vector(DATA_WIDTH-1 downto 0); -- b efetivo (positivo se for soma, negativo se for subtração)
  signal cin                      : unsigned(0 downto 0); -- "0" para adição, mas "1" para subtração, pois representa o "+1" necessário para o complemento de 2 (not(b)+1)
  signal addsubb_ext              : unsigned(DATA_WIDTH downto 0); -- reultado final com bit extra pra capturar o carry out
  signal addsub_res               : std_logic_vector(DATA_WIDTH-1 downto 0); -- resultado final da soma/subtração sem o bit extra de carry out
  signal and_res, or_res, xor_res : std_logic_vector(DATA_WIDTH-1 downto 0); -- resultados finais de cada operação
  signal sll_res,srl_res,sra_res  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal slt_res, sltu_res        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal shamt_u5                 : unsigned(4 downto 0);
  signal ov_add, ov_sub           : std_logic; -- overflow de cada operação

begin

  op <= decode_alu_ctrl(select_function);
  sub_op <= '1' when (op = ALU_SUB) else '0';
  beff <= (not source_2) when (sub_op = '1') else source_2;
  cin <= "1" when sub_op='1' else "0";
  addsubb_ext <= unsigned('0' & source_1) + unsigned('0' & beff) + cin; -- faz soma da entrada A (com bit extra para overflow) com entrada B efetiva (negativada se a operação for subtração e com bit extra para overflow) e com cin (para complemento de 2 do B)
  addsub_res <= std_logic_vector(addsubb_ext(DATA_WIDTH-1 downto 0)); -- resultado da operação sem overflow

  ov_add<= (not (source_1(DATA_WIDTH-1) xor source_2(DATA_WIDTH-1))) and (source_1(DATA_WIDTH-1) xor addsub_res(DATA_WIDTH-1)); -- ov acontece se a e b tiverem mesmo sinal e resultado muda de sinal
  ov_sub<= ((source_1(DATA_WIDTH-1) xor source_2(DATA_WIDTH-1))) and (source_1(DATA_WIDTH-1) xor addsub_res(DATA_WIDTH-1)); -- ov acontece se a e b tiverem sinais diferentes e resultado muda de sinal em relacao a A
  overflow <= ov_add when (op = ALU_ADD) else ov_sub when (op = ALU_SUB) else '0';

  and_res <= source_1 and source_2;
  or_res <= source_1 or source_2;
  xor_res <= source_1 xor source_2;
  shamt_u5 <= unsigned(source_2(4 downto 0)); -- calcula shift amount pras operacoes de tipo R e I que precisam de shift
  sll_res <= std_logic_vector(shift_left(unsigned(source_1), to_integer(shamt_u5)));
  srl_res <= std_logic_vector(shift_right(unsigned(source_1), to_integer(shamt_u5)));
  sra_res <= std_logic_vector(shift_right(signed(source_1), to_integer(shamt_u5)));
  slt_res <= (others => '0');
  sltu_res <= (others => '0');
  slt_res(0) <= '1' when signed(source_1) <  signed(source_2) else '0';
  sltu_res(0) <= '1' when unsigned(source_1) < unsigned(source_2) else '0';

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