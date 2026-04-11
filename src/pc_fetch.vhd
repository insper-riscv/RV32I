-- =============================================================================
-- pc_fetch.vhd
-- Estagio IF: registrador de PC + calculo de PC+4 + MUX de proximo PC
--
-- Implementa o Passo 1 do pipeline RV32IM 5 estagios.
-- Substitui os dois genericRegister (PC_IF e PC_ID) que estavam soltos
-- dentro do rv32i3stage_core.vhd.
--
-- Entradas de selecao de proximo PC (pc_src):
--   "00" -> PC + 4          (fluxo normal)
--   "01" -> branch_target   (branch taken, vem de EX: PC_ID + imm)
--   "10" -> jalr_target     (JALR, vem de EX: ALU_out com LSB zerado)
--
-- Controle de stall:
--   if_pc_write_en = '0' -> PC congela (stall por load-use ou muldiv)
--
-- Compatibilidade com o contrato (RV32IM_PIPELINE_PASSO0_CONTRATO.md):
--   - if_pc_write_en  alias PC_write
--   - rom_addr        <= PC atual (equivalente a rom_addr <= PC_IF_out no core)
--   - pc_out          -> ifid_pc  (entrada do reg_IF_ID)
--   - pc4_out         -> ifid_pc4 (entrada do reg_IF_ID)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32im_pipeline_types.all;

entity pc_fetch is
  port (
    clk               : in  std_logic;
    reset             : in  std_logic;

    -- Controle de stall (da Hazard Detection Unit)
    -- '1' = normal, '0' = congela PC (stall)
    if_pc_write_en    : in  std_logic;

    -- Selecao do proximo PC
    -- "00" = PC+4, "01" = branch_target, "10" = jalr_target
    pc_src            : in  std_logic_vector(1 downto 0);

    -- Alvos de desvio (calculados no estagio EX)
    branch_target     : in  word_t;   -- PC_ID + imm  (branches / JAL)
    jalr_target       : in  word_t;   -- (rs1 + imm) AND 0xFFFFFFFE

    -- Saidas para o registrador IF/ID
    pc_out            : out word_t;   -- PC da instrucao atual
    pc4_out           : out word_t;   -- PC + 4

    -- Interface com a ROM (equivalente a rom_addr no core original)
    rom_addr          : out word_t;
    rom_rden          : out std_logic
  );
end entity pc_fetch;

architecture rtl of pc_fetch is

  -- Registrador de PC interno
  signal pc_reg   : word_t := (others => '0');

  -- PC + 4 combinacional
  signal pc4_wire : word_t;

  -- Proximo valor do PC (saida do MUX)
  signal pc_next  : word_t;

begin

  -- -------------------------------------------------------------------------
  -- PC + 4 (adder combinacional, equivalente ao Adder_PC4_IF do core)
  -- -------------------------------------------------------------------------
  pc4_wire <= std_logic_vector(unsigned(pc_reg) + 4);

  -- -------------------------------------------------------------------------
  -- MUX de proximo PC
  -- "00" -> PC + 4 (fluxo normal)
  -- "01" -> branch_target (branch taken ou JAL)
  -- "10" -> jalr_target   (JALR)
  -- "11" -> reservado, usa PC+4 por seguranca
  -- -------------------------------------------------------------------------
  with pc_src select pc_next <=
    pc4_wire      when "00",
    branch_target when "01",
    jalr_target   when "10",
    pc4_wire      when others;

  -- -------------------------------------------------------------------------
  -- Registrador de PC com enable e reset sincrono
  -- -------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        pc_reg <= (others => '0');
      elsif if_pc_write_en = '1' then
        pc_reg <= pc_next;
      end if;
      -- if_pc_write_en = '0': pc_reg mantem valor (stall)
    end if;
  end process;

  -- -------------------------------------------------------------------------
  -- Saidas
  -- -------------------------------------------------------------------------
  pc_out   <= pc_reg;
  pc4_out  <= pc4_wire;

  -- Interface ROM: endereco e sempre o PC atual
  rom_addr <= pc_reg;
  rom_rden <= '1';

end architecture rtl;
