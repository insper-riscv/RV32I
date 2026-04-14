-- =============================================================================
-- bubble_mux.vhd
-- Bubble MUX do pipeline RV32IM 5 estagios
--
-- Fica entre a Control Unit / reg_IF_ID e o registrador ID/EX.
-- Quando sel_bubble = '1', injeta um NOP (bolha) zerando os sinais de validade,
-- operacoes multi-ciclo e sinais que causam efeito colateral irreversivel.
--
-- Sinais controlados:
--   valid    -- validade da instrucao (mata a instrucao para os proximos estagios)
--   isMulDiv -- impede que o multiplicador acorde atoa em uma bolha
--   weReg    -- impede escrita no banco de registradores
--   weRAM    -- impede escrita na RAM (store)
--   reRAM    -- impede leitura da RAM (load)
--   eRAM     -- impede enable da RAM
--   startMul -- impede pulso de inicio do multdiv
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity bubble_mux is
  port (
    sel_bubble : in  std_logic;

    -- Sinais de entrada (origem: Control Unit e reg_IF_ID)
    valid_i    : in  std_logic;
    isMulDiv_i : in  std_logic;
    weReg_i    : in  std_logic;
    weRAM_i    : in  std_logic;
    reRAM_i    : in  std_logic;
    eRAM_i     : in  std_logic;
    startMul_i : in  std_logic;

    -- Sinais de saida (destino: reg_ID_EX)
    valid_o    : out std_logic;
    isMulDiv_o : out std_logic;
    weReg_o    : out std_logic;
    weRAM_o    : out std_logic;
    reRAM_o    : out std_logic;
    eRAM_o     : out std_logic;
    startMul_o : out std_logic
  );
end entity bubble_mux;

architecture rtl of bubble_mux is
begin
  process(sel_bubble, valid_i, isMulDiv_i, weReg_i, weRAM_i, reRAM_i, eRAM_i, startMul_i)
  begin
    if sel_bubble = '1' then
      -- Injeta Bolha (NOP): zera validade, multi-ciclo e efeitos colaterais
      valid_o    <= '0';
      isMulDiv_o <= '0';
      weReg_o    <= '0';
      weRAM_o    <= '0';
      reRAM_o    <= '0';
      eRAM_o     <= '0';
      startMul_o <= '0';
    else
      -- Fluxo Normal: repassa os sinais originais
      valid_o    <= valid_i;
      isMulDiv_o <= isMulDiv_i;
      weReg_o    <= weReg_i;
      weRAM_o    <= weRAM_i;
      reRAM_o    <= reRAM_i;
      eRAM_o     <= eRAM_i;
      startMul_o <= startMul_i;
    end if;
  end process;
end architecture rtl;