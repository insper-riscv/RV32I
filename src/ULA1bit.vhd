library ieee;
use ieee.std_logic_1164.all;

entity ULA1bit is
  port (
    entradaA   : in  std_logic;
    entradaB   : in  std_logic;
    carryIN    : in  std_logic;
    SLT        : in  std_logic;   -- valor que vai pro bit 0 em SLT/SLTU
    ultimoBit  : in  std_logic;   -- '1' apenas no MSB (bit 31)
    op_ULA     : in  std_logic_vector(3 downto 0); -- [3]=invA [2]=invB [1:0]=00 AND,01 OR,10 ADD,11 SLT
    carryOUT   : out std_logic;
    overflow   : out std_logic;   -- só válido no MSB (quando ultimoBit='1')
    SLT_bit0   : out std_logic;   -- (signed) overflow xor soma_msb (sai do MSB)
    saida      : out std_logic
  );
end entity;

architecture comportamento of ULA1bit is
  signal sinalA, sinalB : std_logic;
  signal res_AND, res_OR, res_SUM : std_logic;
begin
  -- inversões
  sinalA <= (not entradaA) when op_ULA(3)='1' else entradaA;
  sinalB <= (not entradaB) when op_ULA(2)='1' else entradaB;

  -- soma/sub (full adder 1 bit)
  res_SUM  <= (sinalA xor sinalB) xor carryIN;
  carryOUT <= (sinalA and sinalB) or (sinalA and carryIN) or (sinalB and carryIN);

  -- lógicas
  res_AND <= sinalA and sinalB;
  res_OR  <= sinalA or  sinalB;

  -- seletor final (2 bits)
  with op_ULA(1 downto 0) select
    saida <= res_AND when "00",
             res_OR  when "01",
             res_SUM when "10",
             SLT     when others; -- "11"

  -- overflow só interessa no MSB (deixe amarrado/ignorável nos demais)
  overflow  <= ultimoBit and (carryIN xor carryOUT);
  SLT_bit0  <= overflow xor res_SUM; -- (ASSINADO) A<B? olhando MSB da subtração
end architecture;