-- =============================================================================
-- rv32im_pipeline_core.vhd
-- Top-level do pipeline RV32IM 5 estagios
-- M1: IF + ID + Control Unit + Bubble Mux + HDU + reg_IF_ID + reg_ID_EX
-- M2 (pendente): EX + MEM + WB + reg_EX_MEM + reg_MEM_WB + Forwarding Unit
--
-- CORRECCOES em relacao a versao anterior:
--   1. Instancia a hazard_detection_unit: gera if_pc_write_en, ifid_write_en
--      e id_bubble_sel a partir da logica de load-use hazard.
--   2. en do reg_ID_EX corrigido: nao usa ifid_write_en.
--      No load-use stall, o ID/EX NAO e congelado -- ele avanca e recebe
--      o NOP que o bubble_mux injeta. O enable do ID/EX so fica '0'
--      durante muldiv_busy (quando o multdiv precisa de multiplos ciclos).
--   3. flush do reg_ID_EX: controlado por ex_branch_taken (sinal de M2).
--      Quando branch e tomado em EX, tanto IF/ID quanto ID/EX sao zerados.
--   4. pc_src: controlado por sinais de M2 (ex_branch_taken, ex_jalr_taken).
--      Enquanto M2 nao existe, pc_src permanece "00" (PC+4).
--
-- Interface com M2 (sinais que M2 vai preencher):
--   ex_branch_taken  : std_logic    -- branch tomado, flush IF/ID e ID/EX
--   ex_branch_target : word_t       -- PC alvo do branch/JAL
--   ex_jalr_target   : word_t       -- PC alvo do JALR
--   wb_we            : std_logic    -- write enable do WB para o RegFile
--   wb_rd            : reg_t        -- rd do WB para o RegFile
--   wb_data          : word_t       -- dado do WB para o RegFile
--
-- Entradas disponiveis para M2 (saidas do reg_ID_EX):
--   ex_valid, ex_pc, ex_pc4, ex_instr
--   ex_rs1_idx, ex_rs2_idx, ex_rd_idx
--   ex_rs1_val, ex_rs2_val, ex_imm
--   ex_selMuxPc4ALU, ex_selMuxALUPc4RAM
--   ex_weReg, ex_opExRAM, ex_selMuxRS2Imm, ex_selPCRS1
--   ex_opALU, ex_isMulDiv, ex_startMul
--   ex_weRAM, ex_reRAM, ex_eRAM
--   ex_opCode, ex_funct3
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_consts.all;
use work.rv32im_pipeline_types.all;

entity rv32im_pipeline_core is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;

    -- Interface com a ROM
    rom_addr : out std_logic_vector(31 downto 0);
    rom_rden : out std_logic;
    rom_data : in  std_logic_vector(31 downto 0);

    -- Interface com a RAM
    ram_addr    : out std_logic_vector(31 downto 0);
    ram_wdata   : out std_logic_vector(31 downto 0);
    ram_rdata   : in  std_logic_vector(31 downto 0);
    ram_en      : out std_logic;
    ram_wren    : out std_logic;
    ram_rden    : out std_logic;
    ram_byteena : out std_logic_vector(3 downto 0)
  );
end entity rv32im_pipeline_core;

architecture rtl of rv32im_pipeline_core is

  -- =========================================================================
  -- Sinais de controle de hazard (gerados pela HDU)
  -- =========================================================================
  signal if_pc_write_en : std_logic;  -- '1' = normal; '0' = stall PC
  signal ifid_write_en  : std_logic;  -- '1' = normal; '0' = stall IF/ID
  signal id_bubble_sel  : std_logic;  -- '1' = bubble_mux injeta NOP

  -- =========================================================================
  -- Sinais de controle de branch (gerados por M2, no estagio EX)
  -- =========================================================================
  -- INTERFACE M2: M2 deve conectar esses sinais quando implementar EX.
  --   ex_branch_taken  -> flush de IF/ID e ID/EX; pc_src <= "01"
  --   ex_jalr_taken    -> flush de IF/ID e ID/EX; pc_src <= "10"
  signal ex_branch_taken  : std_logic := '0';  -- M2 preenche
  signal ex_jalr_taken    : std_logic := '0';  -- M2 preenche
  signal ex_branch_target : word_t    := (others => '0');  -- M2 preenche
  signal ex_jalr_target   : word_t    := (others => '0');  -- M2 preenche

  -- Selecao do proximo PC para o pc_fetch
  -- "00" = PC+4 (normal), "01" = branch_target, "10" = jalr_target
  signal pc_src : std_logic_vector(1 downto 0);

  -- Flush combinado: qualquer desvio tomado limpa IF e ID
  signal flush_if_id : std_logic;
  signal flush_id_ex : std_logic;

  -- =========================================================================
  -- Sinais de stall do muldiv
  -- No projeto atual busy='0' (LPM combinacional, decisao do orientador).
  -- Mantido para compatibilidade futura.
  -- =========================================================================
  signal muldiv_busy : std_logic := '0';  -- M2 conecta ex_muldiv_busy aqui

  -- =========================================================================
  -- Estagio IF: pc_fetch
  -- =========================================================================
  signal if_pc  : word_t;
  signal if_pc4 : word_t;

  -- =========================================================================
  -- Registrador IF/ID
  -- =========================================================================
  signal ifid_valid : std_logic;
  signal ifid_pc    : word_t;
  signal ifid_pc4   : word_t;
  signal ifid_instr : word_t;

  -- Campos extraidos de ifid_instr para HDU e ID
  signal ifid_rs1 : reg_t;  -- ifid_instr(19:15)
  signal ifid_rs2 : reg_t;  -- ifid_instr(24:20)

  -- =========================================================================
  -- Estagio ID: decodificacao combinacional
  -- =========================================================================
  signal id_rs1_idx : reg_t;
  signal id_rs2_idx : reg_t;
  signal id_rd_idx  : reg_t;
  signal id_rs1_val : word_t;
  signal id_rs2_val : word_t;
  signal id_imm     : word_t;

  -- =========================================================================
  -- Control Unit: saidas
  -- =========================================================================
  signal cu_selMuxPc4ALU    : std_logic;
  signal cu_selMuxALUPc4RAM : wbsel_t;
  signal cu_weReg           : std_logic;
  signal cu_opExRAM         : opexram_t;
  signal cu_selMuxRS2Imm    : std_logic;
  signal cu_selPCRS1        : std_logic;
  signal cu_opALU           : opalu_t;
  signal cu_isMulDiv        : std_logic;
  signal cu_weRAM           : std_logic;
  signal cu_reRAM           : std_logic;
  signal cu_eRAM            : std_logic;
  signal cu_opCode          : std_logic_vector(6 downto 0);
  signal cu_funct3          : std_logic_vector(2 downto 0);

  -- Edge detect de isMulDiv para gerar startMul (1 ciclo de pulso)
  signal isMulDiv_d   : std_logic := '0';
  signal startMul_raw : std_logic;

  -- =========================================================================
  -- Bubble Mux: saidas (sinais prontos para entrar no reg_ID_EX)
  -- =========================================================================
  signal bm_selMuxPc4ALU    : std_logic;
  signal bm_selMuxALUPc4RAM : wbsel_t;
  signal bm_weReg           : std_logic;
  signal bm_opExRAM         : opexram_t;
  signal bm_selMuxRS2Imm    : std_logic;
  signal bm_selPCRS1        : std_logic;
  signal bm_opALU           : opalu_t;
  signal bm_isMulDiv        : std_logic;
  signal bm_startMul        : std_logic;
  signal bm_weRAM           : std_logic;
  signal bm_reRAM           : std_logic;
  signal bm_eRAM            : std_logic;
  signal bm_opCode          : std_logic_vector(6 downto 0);
  signal bm_funct3          : std_logic_vector(2 downto 0);

  -- =========================================================================
  -- Saidas do reg_ID_EX (disponibilizadas para o estagio EX / M2)
  -- =========================================================================
  -- INTERFACE M2: todos os sinais abaixo sao consumidos por M2.
  signal ex_valid             : std_logic;
  signal ex_pc                : word_t;
  signal ex_pc4               : word_t;
  signal ex_instr             : word_t;
  signal ex_rs1_idx           : reg_t;
  signal ex_rs2_idx           : reg_t;
  signal ex_rd_idx            : reg_t;   -- usado tambem pela HDU
  signal ex_rs1_val           : word_t;
  signal ex_rs2_val           : word_t;
  signal ex_imm               : word_t;
  signal ex_selMuxPc4ALU      : std_logic;
  signal ex_selMuxALUPc4RAM   : wbsel_t;
  signal ex_weReg             : std_logic;
  signal ex_opExRAM           : opexram_t;
  signal ex_selMuxRS2Imm      : std_logic;
  signal ex_selPCRS1          : std_logic;
  signal ex_opALU             : opalu_t;
  signal ex_isMulDiv          : std_logic;
  signal ex_startMul          : std_logic;
  signal ex_weRAM             : std_logic;
  signal ex_reRAM             : std_logic;  -- usado pela HDU (load detect)
  signal ex_eRAM              : std_logic;
  signal ex_opCode            : std_logic_vector(6 downto 0);
  signal ex_funct3            : std_logic_vector(2 downto 0);

  -- =========================================================================
  -- Write-back: conectado por M2 quando MEM/WB estiver pronto
  -- INTERFACE M2: preencher esses sinais para fechar o loop no RegFile
  -- =========================================================================
  signal wb_we   : std_logic := '0';         -- M2 preenche
  signal wb_rd   : reg_t    := (others => '0');  -- M2 preenche
  signal wb_data : word_t   := (others => '0');  -- M2 preenche

begin

  -- =========================================================================
  -- Logica combinacional de controle de PC e flush
  -- =========================================================================

  -- Selecao do proximo PC:
  --   "00" = PC+4 (fluxo normal)
  --   "01" = branch_target (branch tomado ou JAL)
  --   "10" = jalr_target (JALR)
  -- Prioridade: jalr > branch > normal (raramente ambos ocorrem ao mesmo ciclo)
  pc_src <= "10" when ex_jalr_taken   = '1' else
            "01" when ex_branch_taken = '1' else
            "00";

  -- Flush: qualquer desvio tomado limpa IF/ID e ID/EX no ciclo seguinte.
  -- Ambos os registradores recebem o mesmo flush pois estao a 1 e 2 ciclos
  -- antes de EX respectivamente, e as instrucoes buscadas podem ser incorretas.
  flush_if_id <= ex_branch_taken or ex_jalr_taken;
  flush_id_ex <= ex_branch_taken or ex_jalr_taken;

  -- =========================================================================
  -- Edge detect de isMulDiv para gerar startMul (pulso de 1 ciclo)
  -- Registra isMulDiv quando IF/ID esta avancando (nao durante stall)
  -- =========================================================================
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        isMulDiv_d <= '0';
      elsif ifid_write_en = '1' then
        isMulDiv_d <= cu_isMulDiv;
      end if;
    end if;
  end process;

  startMul_raw <= cu_isMulDiv and (not isMulDiv_d);

  -- =========================================================================
  -- Campos extraidos da instrucao em IF/ID (para HDU e ID)
  -- =========================================================================
  ifid_rs1   <= ifid_instr(19 downto 15);
  ifid_rs2   <= ifid_instr(24 downto 20);
  id_rs1_idx <= ifid_instr(19 downto 15);
  id_rs2_idx <= ifid_instr(24 downto 20);
  id_rd_idx  <= ifid_instr(11 downto 7);

  -- =========================================================================
  -- IF stage: pc_fetch
  -- =========================================================================
  u_pc_fetch : entity work.pc_fetch
    port map (
      clk            => clk,
      reset          => reset,
      if_pc_write_en => if_pc_write_en,
      pc_src         => pc_src,
      branch_target  => ex_branch_target,
      jalr_target    => ex_jalr_target,
      pc_out         => if_pc,
      pc4_out        => if_pc4,
      rom_addr       => rom_addr,
      rom_rden       => rom_rden
    );

  -- =========================================================================
  -- Registrador IF/ID (pipeline reg 1 de 4)
  -- =========================================================================
  u_reg_if_id : entity work.reg_IF_ID
    port map (
      clk           => clk,
      reset         => reset,
      ifid_write_en => ifid_write_en,
      flush         => flush_if_id,
      in_pc         => if_pc,
      in_pc4        => if_pc4,
      in_instr      => rom_data,
      ifid_valid    => ifid_valid,
      ifid_pc       => ifid_pc,
      ifid_pc4      => ifid_pc4,
      ifid_instr    => ifid_instr
    );

  -- =========================================================================
  -- ID stage: Control Unit (substitui InstructionDecoder)
  -- =========================================================================
  u_control_unit : entity work.control_unit
    port map (
      instruction     => ifid_instr,
      selMuxPc4ALU    => cu_selMuxPc4ALU,
      selMuxALUPc4RAM => cu_selMuxALUPc4RAM,
      weReg           => cu_weReg,
      opExRAM         => cu_opExRAM,
      selMuxRS2Imm    => cu_selMuxRS2Imm,
      selPCRS1        => cu_selPCRS1,
      opALU           => cu_opALU,
      isMulDiv        => cu_isMulDiv,
      weRAM           => cu_weRAM,
      reRAM           => cu_reRAM,
      eRAM            => cu_eRAM,
      opCode          => cu_opCode,
      funct3_out      => cu_funct3
    );

  -- =========================================================================
  -- ID stage: ExtenderImm
  -- =========================================================================
  u_extender_imm : entity work.ExtenderImm
    port map (
      Inst31downto7 => ifid_instr(31 downto 7),
      signalOut     => id_imm
    );

  -- =========================================================================
  -- ID stage: RegFile
  -- Leitura combinacional de rs1/rs2.
  -- Escrita (WB) sera conectada por M2 quando MEM/WB estiver pronto.
  -- =========================================================================
  u_regfile : entity work.RegFile
    port map (
      clk     => clk,
      clear   => reset,
      we      => wb_we,
      rs1     => id_rs1_idx,
      rs2     => id_rs2_idx,
      rd      => wb_rd,
      data_in => wb_data,
      d_rs1   => id_rs1_val,
      d_rs2   => id_rs2_val
    );

  -- =========================================================================
  -- Hazard Detection Unit
  -- Monitora load-use hazard e muldiv stall.
  -- =========================================================================
  u_hdu : entity work.hazard_detection_unit
    port map (
      -- Instrucao em ID (lida do IF/ID)
      ifid_rs1      => ifid_rs1,
      ifid_rs2      => ifid_rs2,
      -- Instrucao em EX (saida do reg_ID_EX)
      idex_rd       => ex_rd_idx,
      idex_reRAM    => ex_reRAM,
      -- MulDiv stall (busy='0' nesta implementacao com LPM combinacional)
      muldiv_busy   => muldiv_busy,
      -- Sinais de controle de stall
      if_pc_write_en => if_pc_write_en,
      ifid_write_en  => ifid_write_en,
      id_bubble_sel  => id_bubble_sel
    );

  -- =========================================================================
  -- Bubble Mux (entre Control Unit e reg_ID_EX)
  -- Zera sinais destrutivos quando sel_bubble='1' (load-use ou muldiv stall)
  -- =========================================================================
  u_bubble_mux : entity work.bubble_mux
    port map (
      sel_bubble        => id_bubble_sel,
      -- Entradas da Control Unit
      weReg_i           => cu_weReg,
      weRAM_i           => cu_weRAM,
      reRAM_i           => cu_reRAM,
      eRAM_i            => cu_eRAM,
      isMulDiv_i        => cu_isMulDiv,
      startMul_i        => startMul_raw,
      selMuxPc4ALU_i    => cu_selMuxPc4ALU,
      selMuxALUPc4RAM_i => cu_selMuxALUPc4RAM,
      opExRAM_i         => cu_opExRAM,
      selMuxRS2Imm_i    => cu_selMuxRS2Imm,
      selPCRS1_i        => cu_selPCRS1,
      opALU_i           => cu_opALU,
      opCode_i          => cu_opCode,
      funct3_i          => cu_funct3,
      -- Saidas para o reg_ID_EX
      weReg_o           => bm_weReg,
      weRAM_o           => bm_weRAM,
      reRAM_o           => bm_reRAM,
      eRAM_o            => bm_eRAM,
      isMulDiv_o        => bm_isMulDiv,
      startMul_o        => bm_startMul,
      selMuxPc4ALU_o    => bm_selMuxPc4ALU,
      selMuxALUPc4RAM_o => bm_selMuxALUPc4RAM,
      opExRAM_o         => bm_opExRAM,
      selMuxRS2Imm_o    => bm_selMuxRS2Imm,
      selPCRS1_o        => bm_selPCRS1,
      opALU_o           => bm_opALU,
      opCode_o          => bm_opCode,
      funct3_o          => bm_funct3
    );

  -- =========================================================================
  -- Registrador ID/EX (pipeline reg 2 de 4)
  --
  -- en: NAO usa ifid_write_en.
  --   No load-use stall: IF/ID congela (ifid_write_en='0'), mas ID/EX
  --   AVANCA e recebe o NOP injetado pelo bubble_mux (en='1').
  --   O ID/EX so congela durante muldiv_busy (hazard estrutural do multdiv).
  --   Como muldiv_busy='0' nesta implementacao, en e sempre '1'.
  --
  -- flush: recebe flush_id_ex (branch/JALR tomado em EX).
  --   Quando M2 detectar branch taken, seta ex_branch_taken='1' e
  --   tanto IF/ID quanto ID/EX serao zerados no ciclo seguinte.
  -- =========================================================================
  u_reg_id_ex : entity work.reg_ID_EX
    port map (
      clk    => clk,
      reset  => reset,
      en     => not muldiv_busy,  -- so congela se multdiv multi-ciclo ativo
      flush  => flush_id_ex,

      -- Validade: propagado do IF/ID; '0' se bolha ou instrucao invalida
      in_valid   => ifid_valid,

      -- Dados de PC e instrucao
      in_pc      => ifid_pc,
      in_pc4     => ifid_pc4,
      in_instr   => ifid_instr,

      -- Indices de registrador (usados por HDU e Forwarding Unit)
      in_rs1_idx => id_rs1_idx,
      in_rs2_idx => id_rs2_idx,
      in_rd_idx  => id_rd_idx,

      -- Valores lidos do RegFile
      in_rs1_val => id_rs1_val,
      in_rs2_val => id_rs2_val,

      -- Imediato extendido
      in_imm     => id_imm,

      -- Controle (pos bubble_mux)
      in_selMuxPc4ALU    => bm_selMuxPc4ALU,
      in_selMuxALUPc4RAM => bm_selMuxALUPc4RAM,
      in_weReg           => bm_weReg,
      in_opExRAM         => bm_opExRAM,
      in_selMuxRS2Imm    => bm_selMuxRS2Imm,
      in_selPCRS1        => bm_selPCRS1,
      in_opALU           => bm_opALU,
      in_isMulDiv        => bm_isMulDiv,
      in_startMul        => bm_startMul,
      in_weRAM           => bm_weRAM,
      in_reRAM           => bm_reRAM,
      in_eRAM            => bm_eRAM,
      in_opCode          => bm_opCode,
      in_funct3          => bm_funct3,

      -- Saidas para o estagio EX (consumidas por M2)
      idex_valid          => ex_valid,
      idex_pc             => ex_pc,
      idex_pc4            => ex_pc4,
      idex_instr          => ex_instr,
      idex_rs1_idx        => ex_rs1_idx,
      idex_rs2_idx        => ex_rs2_idx,
      idex_rd_idx         => ex_rd_idx,
      idex_rs1_val        => ex_rs1_val,
      idex_rs2_val        => ex_rs2_val,
      idex_imm            => ex_imm,
      idex_selMuxPc4ALU   => ex_selMuxPc4ALU,
      idex_selMuxALUPc4RAM=> ex_selMuxALUPc4RAM,
      idex_weReg          => ex_weReg,
      idex_opExRAM        => ex_opExRAM,
      idex_selMuxRS2Imm   => ex_selMuxRS2Imm,
      idex_selPCRS1       => ex_selPCRS1,
      idex_opALU          => ex_opALU,
      idex_isMulDiv       => ex_isMulDiv,
      idex_startMul       => ex_startMul,
      idex_weRAM          => ex_weRAM,
      idex_reRAM          => ex_reRAM,
      idex_eRAM           => ex_eRAM,
      idex_opCode         => ex_opCode,
      idex_funct3         => ex_funct3
    );

  -- =========================================================================
  -- TODO (M2): instanciar reg_EX_MEM, reg_MEM_WB, ALU, StoreManager,
  --   ExtenderRAM, multdiv, forwarding_unit e fechar o loop do RegFile.
  --
  -- Sinais que M2 deve preencher neste arquivo:
  --   ex_branch_taken  <= resultado da comparacao da ALU (branch flag)
  --   ex_jalr_taken    <= '1' quando instrucao em EX e JALR
  --   ex_branch_target <= PC_EX + imm_EX (ou ALU_out para JALR)
  --   ex_jalr_target   <= (rs1_EX + imm_EX) AND x"FFFFFFFE"
  --   muldiv_busy      <= busy do multdiv (se for multi-ciclo)
  --   wb_we            <= weReg do MEM/WB
  --   wb_rd            <= rd_idx do MEM/WB
  --   wb_data          <= resultado final do MUX de WB
  -- =========================================================================

  -- Saidas de RAM: defaults temporarios ate M2 conectar
  ram_addr    <= (others => '0');
  ram_wdata   <= (others => '0');
  ram_en      <= '0';
  ram_wren    <= '0';
  ram_rden    <= '0';
  ram_byteena <= (others => '0');

end architecture rtl;
