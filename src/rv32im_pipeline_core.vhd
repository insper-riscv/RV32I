-- =============================================================================
-- rv32im_pipeline_core.vhd
-- Top-level do pipeline RV32IM 5 estagios
-- M1: IF + ID + Control Unit + Bubble Mux + HDU + reg_IF_ID + reg_ID_EX
-- M2 (pendente): EX + MEM + WB + reg_EX_MEM + reg_MEM_WB + Forwarding Unit
--
-- Bubble Mux: componente simples entre CU e reg_ID_EX.
--   Filtra apenas os 5 sinais destrutivos (weReg, weRAM, reRAM, eRAM,
--   startMul). Todos os outros sinais da CU vao DIRETAMENTE ao reg_ID_EX.
--
-- Sinais que M2 deve preencher:
--   ex_branch_taken, ex_jalr_taken   -> controle de flush e pc_src
--   ex_branch_target, ex_jalr_target -> alvo do proximo PC
--   muldiv_busy                      -> stall estrutural do multdiv
--   wb_we, wb_rd, wb_data            -> write-back para o RegFile
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

    rom_addr : out std_logic_vector(31 downto 0);
    rom_rden : out std_logic;
    rom_data : in  std_logic_vector(31 downto 0);

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
  signal if_pc_write_en : std_logic;
  signal ifid_write_en  : std_logic;
  signal id_bubble_sel  : std_logic;

  -- =========================================================================
  -- Sinais de controle de branch/JALR (preenchidos por M2 no estagio EX)
  -- =========================================================================
  signal ex_branch_taken  : std_logic := '0';
  signal ex_jalr_taken    : std_logic := '0';
  signal ex_branch_target : word_t    := (others => '0');
  signal ex_jalr_target   : word_t    := (others => '0');

  signal pc_src       : std_logic_vector(1 downto 0);
  signal flush_if_id  : std_logic;
  signal flush_id_ex  : std_logic;

  -- =========================================================================
  -- MulDiv stall (busy='0' com LPM combinacional; M2 conecta se necessario)
  -- =========================================================================
  signal muldiv_busy : std_logic := '0';

  -- =========================================================================
  -- Estagio IF
  -- =========================================================================
  signal if_pc  : word_t;
  signal if_pc4 : word_t;

  -- =========================================================================
  -- Registrador IF/ID saidas
  -- =========================================================================
  signal ifid_valid : std_logic;
  signal ifid_pc    : word_t;
  signal ifid_pc4   : word_t;
  signal ifid_instr : word_t;

  signal ifid_rs1 : reg_t;
  signal ifid_rs2 : reg_t;

  -- =========================================================================
  -- Estagio ID: campos decodificados
  -- =========================================================================
  signal id_rs1_idx : reg_t;
  signal id_rs2_idx : reg_t;
  signal id_rd_idx  : reg_t;
  signal id_rs1_val : word_t;
  signal id_rs2_val : word_t;
  signal id_imm     : word_t;

  -- =========================================================================
  -- Control Unit saidas
  -- =========================================================================
  signal cu_selMuxPc4ALU    : std_logic;
  signal cu_opExImm         : opeximm_t;
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

  -- Edge detect de isMulDiv para startMul (pulso de 1 ciclo)
  signal isMulDiv_d   : std_logic := '0';
  signal startMul_raw : std_logic;

  -- =========================================================================
  -- Bubble Mux saidas (apenas os 5 sinais destrutivos filtrados)
  -- Os outros sinais da CU vao direto da cu_* para in_* do reg_ID_EX.
  -- =========================================================================
  signal bm_weReg    : std_logic;
  signal bm_weRAM    : std_logic;
  signal bm_reRAM    : std_logic;
  signal bm_eRAM     : std_logic;
  signal bm_startMul : std_logic;
  signal bm_valid    : std_logic;
  signal bm_isMulDiv : std_logic;

  -- =========================================================================
  -- Saidas do reg_ID_EX (entrada do estagio EX / M2)
  -- =========================================================================
  signal ex_valid           : std_logic;
  signal ex_pc              : word_t;
  signal ex_pc4             : word_t;
  signal ex_instr           : word_t;
  signal ex_rs1_idx         : reg_t;
  signal ex_rs2_idx         : reg_t;
  signal ex_rd_idx          : reg_t;
  signal ex_rs1_val         : word_t;
  signal ex_rs2_val         : word_t;
  signal ex_imm             : word_t;
  signal ex_selMuxPc4ALU    : std_logic;
  signal ex_opExImm         : opeximm_t;
  signal ex_selMuxALUPc4RAM : wbsel_t;
  signal ex_weReg           : std_logic;
  signal ex_opExRAM         : opexram_t;
  signal ex_selMuxRS2Imm    : std_logic;
  signal ex_selPCRS1        : std_logic;
  signal ex_opALU           : opalu_t;
  signal ex_isMulDiv        : std_logic;
  signal ex_startMul        : std_logic;
  signal ex_weRAM           : std_logic;
  signal ex_reRAM           : std_logic;
  signal ex_eRAM            : std_logic;
  signal ex_opCode          : std_logic_vector(6 downto 0);
  signal ex_funct3          : std_logic_vector(2 downto 0);

  -- =========================================================================
  -- Write-back: M2 preenche quando MEM/WB estiver pronto
  -- =========================================================================
  signal wb_we   : std_logic := '0';
  signal wb_rd   : reg_t    := (others => '0');
  signal wb_data : word_t   := (others => '0');

begin

  -- =========================================================================
  -- Controle de PC e flush
  -- =========================================================================
  pc_src <= "10" when ex_jalr_taken   = '1' else
            "01" when ex_branch_taken = '1' else
            "00";

  flush_if_id <= ex_branch_taken or ex_jalr_taken;
  flush_id_ex <= ex_branch_taken or ex_jalr_taken;

  -- =========================================================================
  -- Edge detect de isMulDiv para startMul
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
  -- Campos da instrucao em ID
  -- =========================================================================
  ifid_rs1   <= ifid_instr(19 downto 15);
  ifid_rs2   <= ifid_instr(24 downto 20);
  id_rs1_idx <= ifid_instr(19 downto 15);
  id_rs2_idx <= ifid_instr(24 downto 20);
  id_rd_idx  <= ifid_instr(11 downto 7);

  -- =========================================================================
  -- IF: pc_fetch
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
  -- Registrador IF/ID
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
  -- ID: Control Unit
  -- =========================================================================
  u_control_unit : entity work.control_unit
    port map (
      instruction     => ifid_instr,
      selMuxPc4ALU    => cu_selMuxPc4ALU,
      opExImm         => cu_opExImm,
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
  -- ID: ExtenderImm
  -- =========================================================================
  u_extender_imm : entity work.ExtenderImm
    port map (
      Inst31downto7 => ifid_instr(31 downto 7),
      opExImm       => std_logic_vector(cu_opExImm),
      signalOut     => id_imm
    );

  -- =========================================================================
  -- ID: RegFile (leitura agora; escrita WB conectada por M2)
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
  -- =========================================================================
  u_hdu : entity work.hazard_detection_unit
    port map (
      ifid_rs1       => ifid_rs1,
      ifid_rs2       => ifid_rs2,
      idex_rd        => ex_rd_idx,
      idex_reRAM     => ex_reRAM,
      muldiv_busy    => muldiv_busy,
      if_pc_write_en => if_pc_write_en,
      ifid_write_en  => ifid_write_en,
      id_bubble_sel  => id_bubble_sel
    );

-- =========================================================================
  -- Bubble Mux
  -- Filtra os 7 sinais criticos (validade, multi-ciclo e efeitos colaterais).
  -- O restante (cu_selMuxPc4ALU, cu_opALU, etc.) vai direto ao reg_ID_EX.
  -- =========================================================================
  u_bubble_mux : entity work.bubble_mux
    port map (
      sel_bubble => id_bubble_sel,
      valid_i    => ifid_valid,
      isMulDiv_i => cu_isMulDiv,
      weReg_i    => cu_weReg,
      weRAM_i    => cu_weRAM,
      reRAM_i    => cu_reRAM,
      eRAM_i     => cu_eRAM,
      startMul_i => startMul_raw,
      
      valid_o    => bm_valid,
      isMulDiv_o => bm_isMulDiv,
      weReg_o    => bm_weReg,
      weRAM_o    => bm_weRAM,
      reRAM_o    => bm_reRAM,
      eRAM_o     => bm_eRAM,
      startMul_o => bm_startMul
    );

  -- =========================================================================
  -- Registrador ID/EX
  --
  -- en = not muldiv_busy:
  --   No load-use stall, o ID/EX AVANCA e recebe o NOP do bubble_mux.
  --   Quem congela e apenas PC e IF/ID (via if_pc_write_en e ifid_write_en).
  --   O ID/EX so congela durante muldiv_busy (multi-ciclo).
  --
  -- Sinais destrutivos: vem do bubble_mux (bm_*)
  -- Demais sinais de controle: vem direto da Control Unit (cu_*)
  -- =========================================================================
  u_reg_id_ex : entity work.reg_ID_EX
    port map (
      clk    => clk,
      reset  => reset,
      en     => not muldiv_busy,
      flush  => flush_id_ex,

      in_valid   => ifid_valid,
      in_pc      => ifid_pc,
      in_pc4     => ifid_pc4,
      in_instr   => ifid_instr,
      in_rs1_idx => id_rs1_idx,
      in_rs2_idx => id_rs2_idx,
      in_rd_idx  => id_rd_idx,
      in_rs1_val => id_rs1_val,
      in_rs2_val => id_rs2_val,
      in_imm     => id_imm,

      -- Sinais destrutivos filtrados pelo bubble_mux
		in_valid           => bm_valid,     -- Vem protegido pelo Mux
      in_isMulDiv        => bm_isMulDiv,  -- Vem protegido pelo Mux
      in_weReg           => bm_weReg,
      in_weRAM           => bm_weRAM,
      in_reRAM           => bm_reRAM,
      in_eRAM            => bm_eRAM,
      in_startMul        => bm_startMul,

      -- Sinais de controle direto da Control Unit (nao passam pelo bubble_mux)
      in_selMuxPc4ALU    => cu_selMuxPc4ALU,
      in_opExImm         => cu_opExImm,
      in_selMuxALUPc4RAM => cu_selMuxALUPc4RAM,
      in_opExRAM         => cu_opExRAM,
      in_selMuxRS2Imm    => cu_selMuxRS2Imm,
      in_selPCRS1        => cu_selPCRS1,
      in_opALU           => cu_opALU,
      in_isMulDiv        => cu_isMulDiv,
      in_opCode          => cu_opCode,
      in_funct3          => cu_funct3,

      -- Saidas para o estagio EX (M2)
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
      idex_opExImm        => ex_opExImm,
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
  -- TODO (M2): reg_EX_MEM, reg_MEM_WB, ALU, StoreManager, ExtenderRAM,
  --   multdiv, forwarding_unit, fechar loop do RegFile.
  -- =========================================================================

  ram_addr    <= (others => '0');
  ram_wdata   <= (others => '0');
  ram_en      <= '0';
  ram_wren    <= '0';
  ram_rden    <= '0';
  ram_byteena <= (others => '0');

end architecture rtl;
