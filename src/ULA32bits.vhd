library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ULA32bits is
  port (
    entradaA  : in  std_logic_vector(31 downto 0);
    entradaB  : in  std_logic_vector(31 downto 0);
    op_ALU    : in  std_logic_vector(3 downto 0); 
    flagZero  : out std_logic;
    resultado : out std_logic_vector(31 downto 0)
  );
end entity;

architecture comportamento of ULA32bits is
  constant OP_ADD  : std_logic_vector(3 downto 0) := "0000";
  constant OP_SUB  : std_logic_vector(3 downto 0) := "0001";
  constant OP_AND  : std_logic_vector(3 downto 0) := "0010";
  constant OP_OR   : std_logic_vector(3 downto 0) := "0011";
  constant OP_XOR  : std_logic_vector(3 downto 0) := "0100";
  constant OP_SLL  : std_logic_vector(3 downto 0) := "0101";
  constant OP_SRL  : std_logic_vector(3 downto 0) := "0110";
  constant OP_SRA  : std_logic_vector(3 downto 0) := "0111";
  constant OP_SLT  : std_logic_vector(3 downto 0) := "1000";
  constant OP_SLTU : std_logic_vector(3 downto 0) := "1001";
  constant OP_PASSB: std_logic_vector(3 downto 0) := "1010"; -- opcional (LUI)

  signal c                  : std_logic_vector(31 downto 0);
  signal res_core           : std_logic_vector(31 downto 0);
  signal overflow_msb       : std_logic;
  signal slt_signed_bit0    : std_logic;
  signal slt_input_bit0     : std_logic;

  signal invB               : std_logic;
  signal sel2               : std_logic_vector(1 downto 0);
  signal op_slice           : std_logic_vector(3 downto 0);
  signal carry0             : std_logic;

  signal res_xor, res_shift, res_final : std_logic_vector(31 downto 0);
  signal shamt : integer range 0 to 31;
begin
  -- tradução op_ALU -> sinais do slice
  invB   <= '1' when (op_ALU = OP_SUB or op_ALU = OP_SLT or op_ALU = OP_SLTU) else '0';
  carry0 <= '1' when (op_ALU = OP_SUB or op_ALU = OP_SLT or op_ALU = OP_SLTU) else '0';

  sel2 <= "00" when op_ALU = OP_AND else
          "01" when op_ALU = OP_OR  else
          "10" when (op_ALU = OP_ADD or op_ALU = OP_SUB) else
          "11"; -- SLT/SLTU

  op_slice <= '0' & invB & sel2; -- invA='0' fixo

  -- XOR fora do slice
  res_xor <= entradaA xor entradaB;

  -- shifts (usando numeric_std; shamt = B[4:0])
  shamt <= to_integer(unsigned(entradaB(4 downto 0)));
  process(entradaA, op_ALU, shamt)
  begin
    case op_ALU is
      when OP_SLL => res_shift <= std_logic_vector(shift_left (unsigned(entradaA), shamt));
      when OP_SRL => res_shift <= std_logic_vector(shift_right(unsigned(entradaA), shamt));
      when OP_SRA => res_shift <= std_logic_vector(shift_right(signed(entradaA),   shamt));
      when others => res_shift <= (others => '0');
    end case;
  end process;

  -- bit 0
  b0: entity work.ULA1bit
    port map (
      entradaA  => entradaA(0),
      entradaB  => entradaB(0),
      carryIN   => carry0,
      SLT       => slt_input_bit0,
      ultimoBit => '0',
      op_ULA    => op_slice,
      carryOUT  => c(0),
      overflow  => open,
      SLT_bit0  => open,
      saida     => res_core(0)
    );

  -- bits 1..30
  gen_bits: for i in 1 to 30 generate
    bi: entity work.ULA1bit
      port map (
        entradaA  => entradaA(i),
        entradaB  => entradaB(i),
        carryIN   => c(i-1),
        SLT       => '0',
        ultimoBit => '0',
        op_ULA    => op_slice,
        carryOUT  => c(i),
        overflow  => open,
        SLT_bit0  => open,
        saida     => res_core(i)
      );
  end generate;

  -- bit 31 (MSB)
  b31: entity work.ULA1bit
    port map (
      entradaA  => entradaA(31),
      entradaB  => entradaB(31),
      carryIN   => c(30),
      SLT       => '0',
      ultimoBit => '1',
      op_ULA    => op_slice,
      carryOUT  => c(31),
      overflow  => overflow_msb,
      SLT_bit0  => slt_signed_bit0,
      saida     => res_core(31)
    );

  -- SLT (signed) vs SLTU (unsigned)
  slt_input_bit0 <= slt_signed_bit0 when op_ALU = OP_SLT
                    else (not c(31)) when op_ALU = OP_SLTU
                    else '0';

  -- mux final do resultado
  process(op_ALU, res_core, res_xor, res_shift, entradaB)
  begin
    case op_ALU is
      when OP_AND  | OP_OR  | OP_ADD | OP_SUB | OP_SLT | OP_SLTU =>
        res_final <= res_core;
      when OP_XOR  =>
        res_final <= res_xor;
      when OP_SLL  | OP_SRL | OP_SRA =>
        res_final <= res_shift;
      when OP_PASSB =>
        res_final <= entradaB; -- opcional (LUI)
      when others =>
        res_final <= res_core;
    end case;
  end process;

  resultado <= res_final;
  flagZero  <= '1' when res_final = (others => '0') else '0';
end architecture;
