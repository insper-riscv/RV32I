library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity multdiv is
  generic   (
    DATA_WIDTH  : natural :=  8;
    ADDR_WIDTH  : natural :=  8
  );
  port   (
    -- Input ports (Mantidos)
    SW      : in  std_logic_vector(9 downto 0) := (others => '0');
    clk     : in  std_logic;
    opCode  : in std_logic_vector(2 downto 0); 
    valorA  : in std_logic_vector(31 downto 0);
    valorB  : in std_logic_vector(31 downto 0);
    -- Output ports (Mantidos)
    LEDR    :  out  std_logic_vector(9 downto 0);
    saida   :  out  std_logic_vector(31 downto 0);
    
    -- NOVAS PORTAS (Para integração com o Core)
    rst     : in  std_logic := '0';
    start   : in  std_logic := '0';
    busy    : out std_logic;
    done    : out std_logic
  );
end entity;
architecture arch_name of multdiv is
  -- Mult
  signal resultadoMult : std_logic_vector(65 downto 0);
  signal resultadoMultMenos : std_logic_vector(63 downto 0);
  signal resMult : std_logic_vector(31 downto 0);
  
  -- Div
  signal restoDiv : std_logic_vector(31 downto 0);
  signal resultDiv : std_logic_vector(31 downto 0);

  -- DivU
  signal restoDivU  : std_logic_vector(31 downto 0);
  signal resultDivU : std_logic_vector(31 downto 0);
  signal isUnsigned : std_logic;
  
  -- Decoder
  signal palavra  : std_logic_vector(4 downto 0);
  signal signedAB : std_logic_vector(1 downto 0);
  signal operacao : std_logic_vector(1 downto 0);
  signal maisMenos : std_logic; 
  
  signal outA : std_logic_vector(32 downto 0);
  signal outB : std_logic_vector(32 downto 0);
begin
  -- Acatando a diretriz do orientador (Sem Stall para o lpm combinacional)
  busy <= '0';
  done <= '1';

  -- DIVU=101, REMU=111
  isUnsigned <= '1' when (opCode = "101" or opCode = "111") else '0';
  
  MUL: entity work.mult
      port map(
        dataa => outA,
        datab => outB,
        result => resultadoMult
        );
        
  DIV: entity work.div
      port map(
        denom => valorB,
        numer => valorA,
        quotient => resultDiv,
        remain => restoDiv
        );

  DIVU_inst: entity work.divu
      port map(
        denom => valorB,
        numer => valorA,
        quotient => resultDivU,
        remain => restoDivU
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
        saidaA => outA,
        saidaB => outB
        );
        
  resultadoMultMenos <= resultadoMult(63 downto 0);
  resMult <= resultadoMult(63 downto 32) when maisMenos = '1' else
             resultadoMult(31 downto 0) when maisMenos = '0';
                
  -- Corrigido: Removidas repetições e adicionado caso "others" para evitar Latch
  saida <= resMult when operacao = "10" else
           resultDivU when (operacao = "00" and isUnsigned = '1') else
           resultDiv  when operacao = "00" else
           restoDivU  when (operacao = "01" and isUnsigned = '1') else
           restoDiv   when operacao = "01" else
           (others => '0');
        
  signedAB <= palavra(4 downto 3);
  operacao <= palavra(2 downto 1);
  maisMenos <= palavra(0);
  
  LEDR(7 downto 0) <= resultDiv(31 downto 24) when SW(9) = '1' else
                      resultDiv(23 downto 16) when SW(8) = '1' else
                      resultDiv(15 downto 8)  when SW(7) = '1' else
                      resultDiv(7 downto 0)   when SW(6) = '1' else
                      (others => '0');
end architecture;