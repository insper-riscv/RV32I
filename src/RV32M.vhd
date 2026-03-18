library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lpm;
use lpm.lpm_components.all;

entity RV32M is
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    rst      : in  std_logic;
    rst      : in  std_logic;
    start    : in  std_logic;                      -- Pode manter conectado ao Core, mas não será usado na lógica combinacional
    funct3   : in  std_logic_vector(2 downto 0);
    rs1      : in  std_logic_vector(31 downto 0);
    rs2      : in  std_logic_vector(31 downto 0);

    result   : out std_logic_vector(31 downto 0);
    busy     : out std_logic;                      -- Travado em '0' (Combinacional)
    done     : out std_logic                       -- Travado em '1'
  );
end entity;

architecture rtl of RV32M is

  -- Sinais da sua lógica de Extensão de Sinal (33 bits)
  signal outA : std_logic_vector(32 downto 0);
  signal outB : std_logic_vector(32 downto 0);

  -- Sinais do Multiplicador
  signal resultadoMult : std_logic_vector(65 downto 0);

  -- Sinais do Divisor
  signal resultDiv : std_logic_vector(31 downto 0);
  signal restoDiv  : std_logic_vector(31 downto 0);

begin

  -- Diretriz do orientador: Sem Stall
  busy <= '0';
  done <= '1';

  -- =========================================================
  -- 1. EXTENSÃO DE SINAL (Sua lógica do extendSigned)
  -- =========================================================
  process(funct3, rs1, rs2)
  begin
    if funct3 = "011" then -- MULHU (Unsigned x Unsigned)
      outA <= '0' & rs1;
      outB <= '0' & rs2;
    elsif funct3 = "010" then -- MULHSU (Signed x Unsigned)
      outA <= rs1(31) & rs1;
      outB <= '0' & rs2;
    else -- MUL e MULH (Ambos Signed)
      outA <= rs1(31) & rs1;
      outB <= rs2(31) & rs2;
    end if;
  end process;

  -- =========================================================
  -- 2. MULTIPLICADOR (LPM de 33 bits)
  -- =========================================================
  MUL: lpm_mult
    generic map(
      LPM_WIDTHA         => 33,
      LPM_WIDTHB         => 33,
      LPM_WIDTHP         => 66,
      LPM_REPRESENTATION => "SIGNED",
      LPM_HINT           => "DEDICATED_MULTIPLIER_CIRCUITRY=YES"
    )
    port map(
      dataa  => outA,
      datab  => outB,
      result => resultadoMult
    );

  -- =========================================================
  -- 3. DIVISOR (Inferência Direta para Unsigned e Signed)
  -- =========================================================
  process(rs1, rs2, funct3)
  begin
    -- Proteção contra travamento por Divisão por Zero
    if rs2 = x"00000000" then
      resultDiv <= x"FFFFFFFF";
      restoDiv  <= rs1;
    else
      if funct3 = "101" or funct3 = "111" then -- DIVU, REMU (Unsigned)
        resultDiv <= std_logic_vector(unsigned(rs1) / unsigned(rs2));
        restoDiv  <= std_logic_vector(unsigned(rs1) rem unsigned(rs2));
      else -- DIV, REM (Signed)
        -- Proteção RISC-V contra overflow de complemento de 2
        if rs1 = x"80000000" and rs2 = x"FFFFFFFF" then
          resultDiv <= x"80000000";
          restoDiv  <= x"00000000";
        else
          resultDiv <= std_logic_vector(signed(rs1) / signed(rs2));
          restoDiv  <= std_logic_vector(signed(rs1) rem signed(rs2));
        end if;
      end if;
    end if;
  end process;

  -- =========================================================
  -- 4. DECODIFICADOR DE SAÍDA (Seu decoderM)
  -- =========================================================
  process(funct3, resultadoMult, resultDiv, restoDiv)
  begin
    case funct3 is
      when "000" => result <= resultadoMult(31 downto 0);  -- MUL
      when "001" => result <= resultadoMult(63 downto 32); -- MULH
      when "010" => result <= resultadoMult(63 downto 32); -- MULHSU
      when "011" => result <= resultadoMult(63 downto 32); -- MULHU
      when "100" => result <= resultDiv;                   -- DIV
      when "101" => result <= resultDiv;                   -- DIVU
      when "110" => result <= restoDiv;                    -- REM
      when "111" => result <= restoDiv;                    -- REMU
      when others => result <= (others => '0');
    end case;
  end process;

end architecture;