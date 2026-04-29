-- =============================================================================
-- hazard_detection_unit.vhd
-- Hazard Detection Unit do pipeline RV32IM 5 estagios
--
-- Detecta dois tipos de hazard e gera os sinais de controle:
--
-- 1. LOAD-USE HAZARD
--    Ocorre quando uma instrucao LOAD esta no estagio EX (ID/EX registrado)
--    e a instrucao seguinte (em ID, lida do IF/ID) usa o registrador
--    destino do load como operando.
--    Como o dado so fica disponivel apos MEM, forwarding sozinho nao resolve.
--
--    Condicao de deteccao (Patterson & Hennessy, Computer Organization and
--    Design RISC-V Edition, 2nd ed., Section 4.8), refinada para RV32I:
--      idex_reRAM = '1'   (instrucao em EX e um load)
--      idex_rd  /= "00000"  (destino valido, nao x0)
--      (idex_rd = ifid_rs1 E instrucao em ID usa rs1) OU
--      (idex_rd = ifid_rs2 E instrucao em ID usa rs2)
--
--    Acao:
--      if_pc_write_en  <= '0'  -> congela PC
--      ifid_write_en   <= '0'  -> congela registrador IF/ID
--      id_bubble_sel   <= '1'  -> bubble_mux injeta NOP no ID/EX
--
-- 2. MULDIV STALL
--    O modulo multdiv.vhd tem busy='0' hardwired (combinacional via LPM).
--    Portanto nao e necessario stall de muldiv nesta implementacao.
--    O campo e mantido por completude; se busy for '1', congela tudo.
--
--    Acao:
--      if_pc_write_en  <= '0'
--      ifid_write_en   <= '0'
--      id_bubble_sel   <= '1'
--
-- Entradas:
--   Lidos de IF/ID (instrucao no estagio ID):
--     ifid_rs1  -- instruction(19:15) -- rs1 da instrucao em ID
--     ifid_rs2  -- instruction(24:20) -- rs2 da instrucao em ID
--     ifid_opcode -- instruction(6:0), usado para saber se rs1/rs2 sao fontes
--   Lidos de ID/EX saida (instrucao no estagio EX):
--     idex_rd   -- rd da instrucao que esta em EX
--     idex_reRAM -- '1' se a instrucao em EX e um load
--   Sinal de muldiv:
--     muldiv_busy -- '1' se multdiv ainda esta processando
--
-- Convencao de nomes:
--   Segue nomenclatura de sinais do pipeline_core (prefixo ifid_/idex_)
--   e aliases do contrato (IFID_write, PC_write, sel_bubble).
--   Referencia canonica: Patterson & Hennessy, RISC-V Edition 2nd ed.,
--   Figura 4.59 (Hazard Detection Unit).
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use work.rv32im_pipeline_types.all;

entity hazard_detection_unit is
  port (
    -- -------------------------------------------------------------------------
    -- Entradas de IF/ID (instrucao atualmente no estagio ID)
    -- -------------------------------------------------------------------------
    -- rs1, rs2 e opcode da instrucao que esta sendo decodificada (IF/ID saida)
    ifid_valid : in std_logic;
    ifid_rs1  : in reg_t;   -- ifid_instr(19 downto 15)
    ifid_rs2  : in reg_t;   -- ifid_instr(24 downto 20)
    ifid_opcode : in std_logic_vector(6 downto 0); -- ifid_instr(6 downto 0)

    -- -------------------------------------------------------------------------
    -- Entradas de ID/EX saida (instrucao atualmente no estagio EX)
    -- -------------------------------------------------------------------------
    -- rd da instrucao que foi para EX (saida registrada do reg_ID_EX)
    idex_rd   : in reg_t;   -- ex_rd_idx no pipeline_core

    -- reRAM = '1' indica que a instrucao em EX e um load
    -- (equivalente a MemRead no Patterson & Hennessy)
    idex_reRAM : in std_logic;  -- ex_reRAM no pipeline_core

    -- -------------------------------------------------------------------------
    -- Sinal de stall do modulo MulDiv
    -- No projeto atual busy = '0' (LPM combinacional).
    -- Mantido para compatibilidade futura.
    -- -------------------------------------------------------------------------
    muldiv_busy : in std_logic;

    -- -------------------------------------------------------------------------
    -- Saidas de controle de hazard
    -- -------------------------------------------------------------------------
    -- '1' = operacao normal; '0' = congelar (stall)
    -- Alias: PC_write
    if_pc_write_en  : out std_logic;

    -- '1' = captura normal; '0' = congelar IF/ID (stall)
    -- Alias: IFID_write
    ifid_write_en   : out std_logic;

    -- '1' = injetar bolha (NOP) no ID/EX via bubble_mux
    -- Alias: sel_bubble
    id_bubble_sel   : out std_logic
  );
end entity hazard_detection_unit;

architecture rtl of hazard_detection_unit is

  signal load_use_hazard : std_logic;
  signal stall           : std_logic;
  signal ifid_uses_rs1   : std_logic;
  signal ifid_uses_rs2   : std_logic;

begin

  -- -------------------------------------------------------------------------
  -- Decode minimo de registradores fonte da instrucao em ID.
  -- Evita stall falso quando ifid_rs2 contem bits de imediato (I-type/load).
  -- -------------------------------------------------------------------------
  ifid_uses_rs1 <=
    '1' when (ifid_valid = '1' and
              (ifid_opcode = "0110011" or  -- R-type / M
               ifid_opcode = "0010011" or  -- I-type ALU
               ifid_opcode = "0000011" or  -- load
               ifid_opcode = "0100011" or  -- store
               ifid_opcode = "1100011" or  -- branch
               ifid_opcode = "1100111"))   -- JALR
    else '0';

  ifid_uses_rs2 <=
    '1' when (ifid_valid = '1' and
              (ifid_opcode = "0110011" or  -- R-type / M
               ifid_opcode = "0100011" or  -- store
               ifid_opcode = "1100011"))   -- branch
    else '0';

  -- -------------------------------------------------------------------------
  -- Deteccao de load-use hazard
  -- Condicao: instrucao em EX e um load (idex_reRAM = '1')
  --           E o rd do load nao e x0 (nao pode causar hazard)
  --           E o rd coincide com uma fonte real da instrucao em ID
  -- -------------------------------------------------------------------------
  load_use_hazard <=
    '1' when (idex_reRAM = '1'                  and
              idex_rd /= "00000"                 and
              ((ifid_uses_rs1 = '1' and idex_rd = ifid_rs1) or
               (ifid_uses_rs2 = '1' and idex_rd = ifid_rs2)))
    else '0';

  -- -------------------------------------------------------------------------
  -- Qualquer condicao de stall congela o pipeline na frente
  -- -------------------------------------------------------------------------
  stall <= load_use_hazard or muldiv_busy;

  -- -------------------------------------------------------------------------
  -- Saidas
  -- Quando stall = '1':
  --   PC e IF/ID congelam (write_en = '0')
  --   bubble_mux injeta NOP no ID/EX (sel = '1')
  -- Quando stall = '0': operacao normal
  -- -------------------------------------------------------------------------
  if_pc_write_en <= not stall;
  ifid_write_en  <= not stall;
  id_bubble_sel  <= stall;

end architecture rtl;
