-- =============================================================================
-- reg_MEM_WB.vhd
-- Registrador de pipeline entre os estagios MEM e WB
--
-- NOTA CRITICA sobre o timing da RAM:
--   A RAM (RAM_simulation) tem leitura SINCRONA com 1 ciclo de latencia.
--   Quando reRAM='1' no ciclo N (instrucao em MEM), o dado fica disponivel
--   em ram_rdata no ciclo N+1 (mesma instrucao, agora em WB).
--
--   Por isso este registrador NAO captura ram_rdata: o dado da RAM chega
--   "de graca" no ciclo WB, e o ExtenderRAM (posicionado no estagio WB,
--   apos este registrador) processa ram_rdata junto com os metadados
--   latched aqui (opExRAM, alu_out[1:0] para EA do ExtenderRAM).
--
-- Campos armazenados:
--   valid             : validade do pacote (0 = bolha)
--   pc4               : PC+4, para JAL/JALR (rd <- endereco de retorno)
--   alu_out           : resultado final do estagio EX
--                       - bits [1:0] -> EA do ExtenderRAM (byte offset)
--                       - palavra inteira -> entrada do mux de WB
--   rd_idx            : indice do registrador destino
--                       (consumido pelo RegFile e pela Forwarding Unit)
--   weReg             : write enable do RegFile
--                       (consumido pelo RegFile e pela Forwarding Unit)
--   opExRAM           : tipo de extensao da leitura (LB/LH/LW/LBU/LHU)
--                       -> entrada opExRAM do ExtenderRAM
--   selMuxALUPc4RAM   : selecao do mux final de WB
--                         "00" = ALU (R/I/U-type, AUIPC, LUI)
--                         "01" = PC+4 (JAL, JALR)
--                         "10" = RAM extendida (loads)
--
-- Campos NAO propagados (desnecessarios em WB):
--   store_data, byteena   : usados apenas pela RAM no estagio MEM
--   weRAM, reRAM, eRAM    : controles da RAM, usados apenas em MEM
--   funct3                : opExRAM ja encoda o tipo da leitura
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use work.rv32im_pipeline_types.all;

entity reg_MEM_WB is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    en    : in  std_logic;
    flush : in  std_logic;

    -- Validade do pacote MEM/WB
    in_valid : in  std_logic;

    -- Dados vindos do reg_EX_MEM
    in_pc4     : in  word_t;
    in_alu_out : in  word_t;
    in_rd_idx  : in  reg_t;

    -- Sinais de controle propagados para o estagio WB
    in_weReg           : in  std_logic;
    in_opExRAM         : in  opexram_t;
    in_selMuxALUPc4RAM : in  wbsel_t;

    -- =========================================================================
    -- Saidas para o estagio WB
    -- =========================================================================
    memwb_valid : out std_logic;

    -- Dados
    memwb_pc4     : out word_t;
    memwb_alu_out : out word_t;
    memwb_rd_idx  : out reg_t;

    -- Controle
    memwb_weReg           : out std_logic;
    memwb_opExRAM         : out opexram_t;
    memwb_selMuxALUPc4RAM : out wbsel_t
  );
end entity reg_MEM_WB;

architecture rtl of reg_MEM_WB is
  signal r_valid : std_logic := '0';

  signal r_pc4     : word_t := (others => '0');
  signal r_alu_out : word_t := (others => '0');
  signal r_rd_idx  : reg_t  := (others => '0');

  signal r_weReg           : std_logic := '0';
  signal r_opExRAM         : opexram_t := (others => '0');
  signal r_selMuxALUPc4RAM : wbsel_t   := (others => '0');
begin

  process(clk)
  begin
    if rising_edge(clk) then

      if reset = '1' then
        r_valid <= '0';

        r_pc4     <= (others => '0');
        r_alu_out <= (others => '0');
        r_rd_idx  <= (others => '0');

        r_weReg           <= '0';
        r_opExRAM         <= (others => '0');
        r_selMuxALUPc4RAM <= (others => '0');

      elsif flush = '1' then
        -- Flush zera o pacote e todos os sinais com efeito colateral.
        -- Reservado para flush por excecao (M3+). Por ora flush='0'.
        r_valid <= '0';

        r_pc4     <= (others => '0');
        r_alu_out <= (others => '0');
        r_rd_idx  <= (others => '0');

        r_weReg           <= '0';
        r_opExRAM         <= (others => '0');
        r_selMuxALUPc4RAM <= (others => '0');

      elsif en = '1' then
        r_valid <= in_valid;

        r_pc4     <= in_pc4;
        r_alu_out <= in_alu_out;
        r_rd_idx  <= in_rd_idx;

        r_weReg           <= in_weReg;
        r_opExRAM         <= in_opExRAM;
        r_selMuxALUPc4RAM <= in_selMuxALUPc4RAM;
      end if;
      -- en = '0': hold (stall por muldiv_busy)

    end if;
  end process;

  -- Saidas diretamente dos registros internos
  memwb_valid <= r_valid;

  memwb_pc4     <= r_pc4;
  memwb_alu_out <= r_alu_out;
  memwb_rd_idx  <= r_rd_idx;

  memwb_weReg           <= r_weReg;
  memwb_opExRAM         <= r_opExRAM;
  memwb_selMuxALUPc4RAM <= r_selMuxALUPc4RAM;

end architecture rtl;
