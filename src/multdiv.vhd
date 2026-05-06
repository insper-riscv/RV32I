--------------------------------------------------------------------------------
-- multdiv.vhd
-- Unidade da extensão M para o pipeline RV32IM 5 estágios.
--
-- Diferenças em relação à versão antiga (LPM combinacional):
--   * Booth multiplier (~33 ciclos) e non-restoring divider (~34 ciclos)
--   * busy/done são sinais REAIS (não mais '0'/'1' fixos)
--   * Correção MULHU/MULHSU pós-multiplicação
--
-- Interface PRESERVADA (compatível com o pipeline_core já existente):
--   clk, opCode, valorA, valorB, saida, rst, start, busy, done
--
-- Quando start='1', os operandos valorA/valorB e opCode devem estar válidos
-- nesse mesmo ciclo. busy='1' enquanto a unidade está processando. done='1'
-- por 1 ciclo quando o resultado fica válido em saida (e permanece estável
-- até o próximo start).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multdiv is
  generic (
    DATA_WIDTH  : natural :=  8;
    ADDR_WIDTH  : natural :=  8
  );
  port (
    SW      : in  std_logic_vector(9 downto 0) := (others => '0');
    clk     : in  std_logic;
    opCode  : in  std_logic_vector(2 downto 0);
    valorA  : in  std_logic_vector(31 downto 0);
    valorB  : in  std_logic_vector(31 downto 0);

    LEDR    : out std_logic_vector(9 downto 0);
    saida   : out std_logic_vector(31 downto 0);

    rst     : in  std_logic := '0';
    start   : in  std_logic := '0';
    busy    : out std_logic;
    done    : out std_logic
  );
end entity;

architecture arch_name of multdiv is

  -- Resultados das unidades
  signal resultadoMult : std_logic_vector(65 downto 0);
  signal resMult       : std_logic_vector(31 downto 0);

  signal restoDiv   : std_logic_vector(31 downto 0);
  signal resultDiv  : std_logic_vector(31 downto 0);
  signal restoDivU  : std_logic_vector(31 downto 0);
  signal resultDivU : std_logic_vector(31 downto 0);

  -- Decoder
  signal palavra   : std_logic_vector(4 downto 0);
  signal signedAB  : std_logic_vector(1 downto 0);
  signal operacao  : std_logic_vector(1 downto 0);
  signal maisMenos : std_logic;

  signal outA : std_logic_vector(32 downto 0);
  signal outB : std_logic_vector(32 downto 0);

  -- Seleção de unidade ativa
  signal isMult     : std_logic;
  signal isUnsigned : std_logic;

  -- busy/done por unidade
  signal mult_busy : std_logic;
  signal mult_done : std_logic;
  signal div_busy  : std_logic;
  signal div_done  : std_logic;
  signal divu_busy : std_logic;
  signal divu_done : std_logic;

  -- Correção MULHU/MULHSU
  signal high_signed    : unsigned(31 downto 0);
  signal corrA          : unsigned(31 downto 0);
  signal corrB          : unsigned(31 downto 0);
  signal high_corrected : unsigned(31 downto 0);

  -- saida_capt: registra resultado final no done; mantém estável até próximo done
  signal saida_capt : std_logic_vector(31 downto 0) := (others => '0');
  signal done_int   : std_logic;

begin

  -- Decode de qual unidade é ativa
  -- MUL/MULH/MULHSU/MULHU (000,001,010,011) -> opCode(2)='0'
  -- DIV/DIVU/REM/REMU     (100,101,110,111) -> opCode(2)='1'
  isMult     <= '1' when opCode(2) = '0' else '0';
  isUnsigned <= '1' when (opCode = "101" or opCode = "111") else '0';

  ----------------------------------------------------------------------------
  -- Roteia busy/done da unidade ativa
  ----------------------------------------------------------------------------
  busy <= mult_busy when isMult = '1' else
          divu_busy when isUnsigned = '1' else
          div_busy;

  done_int <= mult_done when isMult = '1' else
              divu_done when isUnsigned = '1' else
              div_done;

  done <= done_int;

  ----------------------------------------------------------------------------
  -- Instâncias das unidades
  ----------------------------------------------------------------------------
  MUL: entity work.mult
      port map(
        clk    => clk,
        rst    => rst,
        start  => start and isMult,
        dataa  => outA,
        datab  => outB,
        result => resultadoMult,
        done   => mult_done,
        busy   => mult_busy
        );

  DIV: entity work.div
      port map(
        clk      => clk,
        rst      => rst,
        start    => start and (not isMult) and (not isUnsigned),
        numer    => valorA,
        denom    => valorB,
        quotient => resultDiv,
        remain   => restoDiv,
        done     => div_done,
        busy     => div_busy
        );

  DIVU_inst: entity work.divu
      port map(
        clk      => clk,
        rst      => rst,
        start    => start and (not isMult) and isUnsigned,
        numer    => valorA,
        denom    => valorB,
        quotient => resultDivU,
        remain   => restoDivU,
        done     => divu_done,
        busy     => divu_busy
        );

  DECODER: entity work.decoderM
      port map(
        instru => opCode,
        palavraControle => palavra
        );

  EXTENDER: entity work.extendSigned
      port map(
        entradaA => valorA,
        entradaB => valorB,
        controle => signedAB,
        saidaA   => outA,
        saidaB   => outB
        );

  signedAB  <= palavra(4 downto 3);
  operacao  <= palavra(2 downto 1);
  maisMenos <= palavra(0);

  ----------------------------------------------------------------------------
  -- Correção MULHU/MULHSU
  --
  -- Booth opera 32x32 SIGNED. Para obter MULHU/MULHSU corretos:
  --
  --   high_unsigned(A,B) = high_signed(A,B) + (A[31] ? B : 0) + (B[31] ? A : 0)
  --   high_mulhsu(A,B)   = high_signed(A,B) +                   (B[31] ? A : 0)
  --
  -- signedAB(1) = '1' se A é signed; signedAB(0) = '1' se B é signed.
  --   * MUL    (000): signedAB="11", maisMenos='0' -> usa low 32 bits direto
  --   * MULH   (001): signedAB="11", maisMenos='1' -> sem correção
  --   * MULHSU (010): signedAB="10", maisMenos='1' -> só corrB
  --   * MULHU  (011): signedAB="00", maisMenos='1' -> corrA + corrB
  ----------------------------------------------------------------------------
  high_signed <= unsigned(resultadoMult(63 downto 32));

  corrA <= unsigned(valorB) when (valorA(31) = '1' and signedAB(1) = '0')
           else (others => '0');

  corrB <= unsigned(valorA) when (valorB(31) = '1' and signedAB(0) = '0')
           else (others => '0');

  high_corrected <= high_signed + corrA + corrB;

  resMult <= resultadoMult(31 downto 0) when maisMenos = '0' else
             std_logic_vector(high_corrected);

  ----------------------------------------------------------------------------
  -- Resultado combinacional (multiplexado pela operação)
  ----------------------------------------------------------------------------
  saida <= saida_capt;

  -- Captura resultado quando done pulsa (resultado fica estável depois)
  process(clk, rst)
  begin
    if rst = '1' then
      saida_capt <= (others => '0');
    elsif rising_edge(clk) then
      if done_int = '1' then
        if operacao = "10" then
          saida_capt <= resMult;
        elsif operacao = "00" and isUnsigned = '1' then
          saida_capt <= resultDivU;
        elsif operacao = "00" then
          saida_capt <= resultDiv;
        elsif operacao = "01" and isUnsigned = '1' then
          saida_capt <= restoDivU;
        elsif operacao = "01" then
          saida_capt <= restoDiv;
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------------
  -- LEDR (debug)
  ----------------------------------------------------------------------------
  LEDR(7 downto 0) <= resultDiv(31 downto 24) when SW(9) = '1' else
                      resultDiv(23 downto 16) when SW(8) = '1' else
                      resultDiv(15 downto 8)  when SW(7) = '1' else
                      resultDiv(7 downto 0)   when SW(6) = '1' else
                      (others => '0');
  LEDR(9 downto 8) <= (others => '0');

end architecture;
