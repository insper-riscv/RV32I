-- =============================================================================
-- forwarding_unit.vhd
-- Unidade de forwarding (data hazard bypass) para o pipeline RV32IM
--
-- Detecta dependencias RAW entre instrucoes em voo e seleciona a fonte
-- correta para os operandos da ALU no estagio EX.
--
-- Codificacao de forward_A / forward_B:
--   "00" = sem forwarding  -> usa valor de ex_rs1_val / ex_rs2_val (ID/EX)
--   "10" = forward EX/MEM  -> usa exmem_alu_out (resultado da ALU anterior)
--   "01" = forward MEM/WB  -> usa wb_data (dado do WB, pode ser RAM ou ALU)
--
-- Prioridade: EX/MEM > MEM/WB > ID/EX
--   Necessaria quando duas instrucoes consecutivas escrevem no mesmo rd:
--   a mais recente (EX/MEM) deve ter prioridade sobre a mais antiga (MEM/WB).
--
-- Condicoes de forwarding (Patterson & Hennessy):
--   EX/MEM: exmem_weReg='1' AND exmem_rd /= x0 AND exmem_rd = ex_rsX
--   MEM/WB: memwb_weReg='1' AND memwb_rd /= x0 AND memwb_rd  = ex_rsX
--             AND NOT (condicao EX/MEM satisfeita)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use work.rv32im_pipeline_types.all;

entity forwarding_unit is
  port (
    -- Indices dos registradores fonte da instrucao em EX (saidos do reg_ID_EX)
    ex_rs1_idx   : in  reg_t;
    ex_rs2_idx   : in  reg_t;

    -- Instrucao em MEM: destino e write-enable (saidos do reg_EX_MEM)
    exmem_rd_idx : in  reg_t;
    exmem_weReg  : in  std_logic;

    -- Instrucao em WB: destino e write-enable (saidos do reg_MEM_WB / wb_*)
    memwb_rd_idx : in  reg_t;
    memwb_weReg  : in  std_logic;

    -- Selecoes de forwarding para os muxes 3:1 que alimentam a ALU
    forward_A    : out std_logic_vector(1 downto 0);  -- mux do operando A (rs1)
    forward_B    : out std_logic_vector(1 downto 0)   -- mux do operando B (rs2)
  );
end entity forwarding_unit;

architecture rtl of forwarding_unit is
  -- Constante auxiliar para comparacao com o registrador zero (x0)
  constant REG_ZERO : reg_t := (others => '0');
begin

  -- ===========================================================================
  -- Forward A: operando rs1
  -- ===========================================================================
  process(ex_rs1_idx, exmem_rd_idx, exmem_weReg, memwb_rd_idx, memwb_weReg)
  begin
    if    exmem_weReg = '1'
      and exmem_rd_idx /= REG_ZERO
      and exmem_rd_idx  = ex_rs1_idx
    then
      -- Hazard EX/MEM: instrucao anterior esta em MEM, seu resultado ainda
      -- nao foi escrito no RegFile mas ja esta disponivel em exmem_alu_out.
      forward_A <= "10";

    elsif memwb_weReg = '1'
      and memwb_rd_idx /= REG_ZERO
      and memwb_rd_idx  = ex_rs1_idx
    then
      -- Hazard MEM/WB: instrucao duas posicoes atras esta em WB.
      -- O resultado esta disponivel em wb_data (ALU ou RAM).
      forward_A <= "01";

    else
      -- Sem hazard: valor lido do RegFile no estagio ID e valido.
      forward_A <= "00";
    end if;
  end process;

  -- ===========================================================================
  -- Forward B: operando rs2
  -- ===========================================================================
  process(ex_rs2_idx, exmem_rd_idx, exmem_weReg, memwb_rd_idx, memwb_weReg)
  begin
    if    exmem_weReg = '1'
      and exmem_rd_idx /= REG_ZERO
      and exmem_rd_idx  = ex_rs2_idx
    then
      forward_B <= "10";

    elsif memwb_weReg = '1'
      and memwb_rd_idx /= REG_ZERO
      and memwb_rd_idx  = ex_rs2_idx
    then
      forward_B <= "01";

    else
      forward_B <= "00";
    end if;
  end process;

end architecture rtl;
