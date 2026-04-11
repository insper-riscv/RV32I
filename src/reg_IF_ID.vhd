-- =============================================================================
-- reg_IF_ID.vhd
-- Registrador de pipeline IF/ID do RV32IM 5 estagios
--
-- Captura, a cada borda de subida, os sinais produzidos pelo estagio IF
-- e os disponibiliza ao estagio ID no ciclo seguinte.
--
-- Comportamento dos controles (prioridade decrescente):
--   1. reset = '1'          -> todos os campos zerados, valid = '0' (NOP)
--   2. flush = '1'          -> injeta bolha: valid = '0', controles zerados
--                              (PC e instr tambem zerados para limpeza total)
--   3. ifid_write_en = '0'  -> stall: registrador congela (hold)
--   4. normal               -> captura entradas normalmente, valid = '1'
--
-- Bolha (bubble): campo ifid_valid = '0' sinaliza que o conteudo
-- nao deve ser executado. Os estagios downstream devem ignorar
-- instrucoes com valid = '0' e nao escrever em registradores/memoria.
--
-- Compatibilidade com o contrato (RV32IM_PIPELINE_PASSO0_CONTRATO.md):
--   - ifid_write_en  alias IFID_write
--   - ifid_valid
--   - ifid_pc
--   - ifid_pc4
--   - ifid_instr
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use work.rv32im_pipeline_types.all;

entity reg_IF_ID is
  port (
    clk             : in  std_logic;
    reset           : in  std_logic;

    -- Controle de stall: '1' = captura normal, '0' = congela (stall)
    -- Alias: IFID_write
    ifid_write_en   : in  std_logic;

    -- Flush: injeta bolha (branch taken, JALR, etc.)
    flush           : in  std_logic;

    -- -------------------------------------------------------------------------
    -- Entradas (vem do estagio IF / pc_fetch)
    -- -------------------------------------------------------------------------
    in_pc           : in  word_t;   -- PC da instrucao (pc_out do pc_fetch)
    in_pc4          : in  word_t;   -- PC + 4          (pc4_out do pc_fetch)
    in_instr        : in  word_t;   -- instrucao da ROM (rom_data)

    -- -------------------------------------------------------------------------
    -- Saidas (disponibilizadas ao estagio ID)
    -- -------------------------------------------------------------------------
    ifid_valid      : out std_logic;  -- '0' = bolha, '1' = instrucao valida
    ifid_pc         : out word_t;
    ifid_pc4        : out word_t;
    ifid_instr      : out word_t
  );
end entity reg_IF_ID;

architecture rtl of reg_IF_ID is

  -- Registradores internos
  signal r_valid : std_logic                     := '0';
  signal r_pc    : word_t                        := (others => '0');
  signal r_pc4   : word_t                        := (others => '0');
  signal r_instr : word_t                        := (others => '0');

begin

  process(clk)
  begin
    if rising_edge(clk) then

      if reset = '1' then
        -- Reset sincrono: limpa tudo e marca como bolha
        r_valid <= '0';
        r_pc    <= (others => '0');
        r_pc4   <= (others => '0');
        r_instr <= (others => '0');

      elsif flush = '1' then
        -- Flush: injeta bolha sem alterar o PC
        -- (o pc_fetch ja foi redirecionado pelo pc_src neste mesmo ciclo)
        r_valid <= '0';
        r_pc    <= (others => '0');
        r_pc4   <= (others => '0');
        r_instr <= (others => '0');

      elsif ifid_write_en = '1' then
        -- Captura normal
        r_valid <= '1';
        r_pc    <= in_pc;
        r_pc4   <= in_pc4;
        r_instr <= in_instr;

      end if;
      -- ifid_write_en = '0' e sem reset/flush: hold (stall)

    end if;
  end process;

  -- -------------------------------------------------------------------------
  -- Saidas
  -- -------------------------------------------------------------------------
  ifid_valid <= r_valid;
  ifid_pc    <= r_pc;
  ifid_pc4   <= r_pc4;
  ifid_instr <= r_instr;

end architecture rtl;
