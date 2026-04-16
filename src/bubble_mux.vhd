-- =============================================================================
-- bubble_mux.vhd
-- Bubble MUX do pipeline RV32IM 5 estagios
--
-- Fica entre a Control Unit e o registrador ID/EX.
-- Quando sel_bubble = '1', zera os 5 sinais que causam efeito colateral.
-- Os demais sinais da Control Unit vao DIRETAMENTE para o reg_ID_EX,
-- sem passar por aqui.
--
-- Sinais controlados:
--   weReg    -- escrita no banco de registradores
--   weRAM    -- escrita na RAM (store)
--   reRAM    -- leitura da RAM (load)
--   eRAM     -- enable da RAM
--   startMul -- pulso de inicio do multdiv
--
-- Quando sel_bubble = '0': saidas = entradas (passagem normal)
-- Quando sel_bubble = '1': saidas = "00000"  (NOP: nenhum efeito colateral)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity bubble_mux is
  port (
    sel_bubble : in  std_logic;

    weReg_i    : in  std_logic;
    weRAM_i    : in  std_logic;
    reRAM_i    : in  std_logic;
    eRAM_i     : in  std_logic;
    startMul_i : in  std_logic;

    weReg_o    : out std_logic;
    weRAM_o    : out std_logic;
    reRAM_o    : out std_logic;
    eRAM_o     : out std_logic;
    startMul_o : out std_logic
  );
end entity bubble_mux;

architecture rtl of bubble_mux is
begin

  weReg_o    <= weReg_i    when sel_bubble = '0' else '0';
  weRAM_o    <= weRAM_i    when sel_bubble = '0' else '0';
  reRAM_o    <= reRAM_i    when sel_bubble = '0' else '0';
  eRAM_o     <= eRAM_i     when sel_bubble = '0' else '0';
  startMul_o <= startMul_i when sel_bubble = '0' else '0';

end architecture rtl;