-- =============================================================================
-- bubble_mux.vhd
-- Bubble MUX (NOP inject) do pipeline RV32IM 5 estagios
--
-- Posicionado ENTRE a Control Unit e o registrador ID/EX.
-- Quando sel_bubble = '1' (gerado pela Hazard Detection Unit),
-- zera todos os sinais de controle que causariam efeito colateral
-- no pipeline (escritas em registrador, escrita/leitura na RAM,
-- inicio de multiplicacao/divisao).
--
-- Sinais zerados quando sel_bubble = '1':
--   weReg           -> '0'   impede escrita no banco de registradores
--   weRAM           -> '0'   impede escrita na RAM (store)
--   reRAM           -> '0'   impede leitura da RAM (load)
--   eRAM            -> '0'   desabilita a RAM completamente
--   isMulDiv        -> '0'   nao inicia operacao M
--   startMul        -> '0'   nao gera pulso de start para o multdiv
--
-- Sinais PASSADOS INTACTOS mesmo com sel_bubble = '1':
--   opALU, opExImm, selMuxRS2Imm, selPCRS1, selMuxPc4ALU,
--   selMuxALUPc4RAM, opExRAM, opCode, funct3_out
--   Esses sinais nao causam efeito colateral: a ALU vai calcular
--   algo, mas o resultado sera descartado pois weReg = '0'.
--
-- Compatibilidade com o contrato (RV32IM_PIPELINE_PASSO0_CONTRATO.md):
--   - sel_bubble = id_bubble_sel
--   - Saidas com sufixo _o sao as que entram no reg_ID_EX
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use work.rv32i_ctrl_consts.all;
use work.rv32im_pipeline_types.all;

entity bubble_mux is
  port (
    -- Sinal de controle de bolha (da Hazard Detection Unit)
    -- '0' = passagem normal, '1' = injetar NOP
    sel_bubble      : in  std_logic;

    -- -------------------------------------------------------------------------
    -- Entradas: sinais vindos da Control Unit
    -- -------------------------------------------------------------------------
    -- Controle de escrita/memoria (zerados na bolha)
    weReg_i         : in  std_logic;
    weRAM_i         : in  std_logic;
    reRAM_i         : in  std_logic;
    eRAM_i          : in  std_logic;
    isMulDiv_i      : in  std_logic;
    startMul_i      : in  std_logic;

    -- Controle de fluxo e ALU (passados intactos)
    selMuxPc4ALU_i    : in  std_logic;
    opExImm_i         : in  opeximm_t;
    selMuxALUPc4RAM_i : in  wbsel_t;
    opExRAM_i         : in  opexram_t;
    selMuxRS2Imm_i    : in  std_logic;
    selPCRS1_i        : in  std_logic;
    opALU_i           : in  opalu_t;
    opCode_i          : in  std_logic_vector(6 downto 0);
    funct3_i          : in  std_logic_vector(2 downto 0);

    -- -------------------------------------------------------------------------
    -- Saidas: sinais que entram no registrador ID/EX
    -- -------------------------------------------------------------------------
    -- Controle de escrita/memoria (zerados na bolha)
    weReg_o         : out std_logic;
    weRAM_o         : out std_logic;
    reRAM_o         : out std_logic;
    eRAM_o          : out std_logic;
    isMulDiv_o      : out std_logic;
    startMul_o      : out std_logic;

    -- Controle de fluxo e ALU (passados intactos)
    selMuxPc4ALU_o    : out std_logic;
    opExImm_o         : out opeximm_t;
    selMuxALUPc4RAM_o : out wbsel_t;
    opExRAM_o         : out opexram_t;
    selMuxRS2Imm_o    : out std_logic;
    selPCRS1_o        : out std_logic;
    opALU_o           : out opalu_t;
    opCode_o          : out std_logic_vector(6 downto 0);
    funct3_o          : out std_logic_vector(2 downto 0)
  );
end entity bubble_mux;

architecture rtl of bubble_mux is
begin

  -- -------------------------------------------------------------------------
  -- Sinais zerados quando sel_bubble = '1'
  -- Esses cinco sinais causam efeitos colaterais irreversiveis:
  --   escrita em registradores, acesso a RAM, inicio de mul/div.
  -- -------------------------------------------------------------------------
  weReg_o    <= '0' when sel_bubble = '1' else weReg_i;
  weRAM_o    <= '0' when sel_bubble = '1' else weRAM_i;
  reRAM_o    <= '0' when sel_bubble = '1' else reRAM_i;
  eRAM_o     <= '0' when sel_bubble = '1' else eRAM_i;
  isMulDiv_o <= '0' when sel_bubble = '1' else isMulDiv_i;
  startMul_o <= '0' when sel_bubble = '1' else startMul_i;

  -- -------------------------------------------------------------------------
  -- Sinais passados intactos independente do sel_bubble
  -- A ALU pode operar, mas o resultado sera descartado (weReg = '0').
  -- -------------------------------------------------------------------------
  selMuxPc4ALU_o    <= selMuxPc4ALU_i;
  opExImm_o         <= opExImm_i;
  selMuxALUPc4RAM_o <= selMuxALUPc4RAM_i;
  opExRAM_o         <= opExRAM_i;
  selMuxRS2Imm_o    <= selMuxRS2Imm_i;
  selPCRS1_o        <= selPCRS1_i;
  opALU_o           <= opALU_i;
  opCode_o          <= opCode_i;
  funct3_o          <= funct3_i;

end architecture rtl;
