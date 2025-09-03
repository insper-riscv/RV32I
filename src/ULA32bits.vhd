library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RV32I_ALU is
  generic(DATA_WIDTH:natural:=32);
  port(
    select_function:in std_logic_vector(3 downto 0);
    source_1,source_2:in std_logic_vector(DATA_WIDTH-1 downto 0);
    overflow:out std_logic;
    destination:out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity;

architecture RTL of RV32I_ALU is
  signal flag_subtract:std_logic;
  signal s2_eff,pg,pp,sum,logic_and,logic_or,half_add:std_logic_vector(DATA_WIDTH-1 downto 0);
  signal carry:std_logic_vector(DATA_WIDTH downto 0);
  signal add_overflow:std_logic;
  signal slt,sltu,shift_out,dst_grp0,dst_grp1:std_logic_vector(DATA_WIDTH-1 downto 0);

  function sll_vec(a:std_logic_vector;sh:natural)return std_logic_vector is
    variable r:std_logic_vector(a'range);
  begin
    r:=std_logic_vector(shift_left(unsigned(a),sh)); return r;
  end;
  function srl_vec(a:std_logic_vector;sh:natural)return std_logic_vector is
    variable r:std_logic_vector(a'range);
  begin
    r:=std_logic_vector(shift_right(unsigned(a),sh)); return r;
  end;
  function sra_vec(a:std_logic_vector;sh:natural)return std_logic_vector is
    variable r:std_logic_vector(a'range);
  begin
    r:=std_logic_vector(shift_right(signed(a),sh)); return r;
  end;
begin
  flag_subtract <= (select_function(3 downto 2)="10") and not(select_function(1 downto 0)="01");
  s2_eff        <= source_2 when flag_subtract='0' else not source_2;

  logic_and <= source_1 and s2_eff;
  logic_or  <= source_1 or  source_2;
  half_add  <= source_1 xor s2_eff;

  carry(0) <= flag_subtract;
  gen_carry:for i in 0 to DATA_WIDTH-1 generate
    carry(i+1) <= (carry(i) and half_add(i)) or logic_and(i);
  end generate;
  sum <= half_add xor carry(DATA_WIDTH-1 downto 0);

  add_overflow <= carry(DATA_WIDTH) xor carry(DATA_WIDTH-1);

  slt  <= (0 => (add_overflow xor sum(DATA_WIDTH-1)), others => '0');
  sltu <= (0 => not carry(DATA_WIDTH),                 others => '0');

  process(all)
    variable shamt:natural;
  begin
    shamt := to_integer(unsigned(source_2(4 downto 0)));
    if select_function(2)='1' then
      shift_out <= sll_vec(source_1,shamt);
    else
      if select_function(3)='1' then
        shift_out <= sra_vec(source_1,shamt);
      else
        shift_out <= srl_vec(source_1,shamt);
      end if;
    end if;
  end process;

  with select_function(1 downto 0) select
    dst_grp0 <=
      sum       when "00",
      shift_out when "01",
      slt       when "10",
      sltu      when others;

  with select_function(1 downto 0) select
    dst_grp1 <=
      (source_1 xor source_2) when "00",
      shift_out               when "01",
      logic_or                when "10",
      (source_1 and source_2) when others;

  destination <= dst_grp0 when select_function(2)='0' else dst_grp1;

  overflow <= add_overflow when (select_function(2)='0' and select_function(1 downto 0)="00") else '0';
end architecture;