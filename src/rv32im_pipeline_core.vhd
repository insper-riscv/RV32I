library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32im_pipeline_types.all;

entity rv32im_pipeline_core is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;

    ----------------------------------------------------------------------
    -- Interface com a ROM (somente leitura)
    ----------------------------------------------------------------------
    rom_addr : out std_logic_vector(31 downto 0);
    rom_rden : out std_logic;
    rom_data : in  std_logic_vector(31 downto 0);

    ----------------------------------------------------------------------
    -- Interface com a RAM (leitura e escrita)
    ----------------------------------------------------------------------
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

  -- IF controls (hazard unit vai dirigir esses sinais no Passo 2+)
  signal if_pc_write_en : std_logic := '1';
  signal ifid_write_en  : std_logic := '1';
  signal id_bubble_sel  : std_logic := '0';

  -- Redirecionamento de PC (branch/jalr em EX)
  signal pc_src         : std_logic_vector(1 downto 0) := "00";
  signal ex_branch_taken: std_logic := '0';
  signal branch_target  : word_t := (others => '0');
  signal jalr_target    : word_t := (others => '0');

  -- IF/ID datapath
  signal if_pc          : word_t;
  signal if_pc4         : word_t;
  signal ifid_valid     : std_logic;
  signal ifid_pc        : word_t;
  signal ifid_pc4       : word_t;
  signal ifid_instr     : word_t;

  -- ID data path para entrada do reg_ID_EX
  signal id_rs1_idx      : reg_t;
  signal id_rs2_idx      : reg_t;
  signal id_rd_idx       : reg_t;
  signal id_rs1_val      : word_t;
  signal id_rs2_val      : word_t;
  signal id_imm          : word_t;

  -- Control Unit outputs
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

  -- startMul edge detect no ID (deve passar pelo bubble_mux)
  signal isMulDiv_d         : std_logic := '0';
  signal startMul_raw       : std_logic;

  -- Bubble mux outputs (sinais prontos para entrada do reg_ID_EX)
  signal idex_selMuxPc4ALU    : std_logic;
  signal idex_opExImm         : opeximm_t;
  signal idex_selMuxALUPc4RAM : wbsel_t;
  signal idex_weReg           : std_logic;
  signal idex_opExRAM         : opexram_t;
  signal idex_selMuxRS2Imm    : std_logic;
  signal idex_selPCRS1        : std_logic;
  signal idex_opALU           : opalu_t;
  signal idex_isMulDiv        : std_logic;
  signal idex_weRAM           : std_logic;
  signal idex_reRAM           : std_logic;
  signal idex_eRAM            : std_logic;
  signal idex_startMul        : std_logic;
  signal idex_opCode          : std_logic_vector(6 downto 0);
  signal idex_funct3          : std_logic_vector(2 downto 0);

  -- Saidas registradas do ID/EX (entrada do estagio EX)
  signal ex_valid             : std_logic;
  signal ex_pc                : word_t;
  signal ex_pc4               : word_t;
  signal ex_instr             : word_t;
  signal ex_rs1_idx           : reg_t;
  signal ex_rs2_idx           : reg_t;
  signal ex_rd_idx            : reg_t;
  signal ex_rs1_val           : word_t;
  signal ex_rs2_val           : word_t;
  signal ex_imm               : word_t;
  signal ex_selMuxPc4ALU      : std_logic;
  signal ex_opExImm           : opeximm_t;
  signal ex_selMuxALUPc4RAM   : wbsel_t;
  signal ex_weReg             : std_logic;
  signal ex_opExRAM           : opexram_t;
  signal ex_selMuxRS2Imm      : std_logic;
  signal ex_selPCRS1          : std_logic;
  signal ex_opALU             : opalu_t;
  signal ex_isMulDiv          : std_logic;
  signal ex_startMul          : std_logic;
  signal ex_weRAM             : std_logic;
  signal ex_reRAM             : std_logic;
  signal ex_eRAM              : std_logic;
  signal ex_opCode            : std_logic_vector(6 downto 0);
  signal ex_funct3            : std_logic_vector(2 downto 0);

begin

  ----------------------------------------------------------------------
  -- Edge detect de isMulDiv para gerar startMul de 1 ciclo.
  -- Esse start passa pelo bubble_mux para nao iniciar mul/div em bolha.
  ----------------------------------------------------------------------
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

  -- Campos da instrucao em ID e extensao de imediato.
  id_rs1_idx <= ifid_instr(19 downto 15);
  id_rs2_idx <= ifid_instr(24 downto 20);
  id_rd_idx  <= ifid_instr(11 downto 7);

  u_extender_imm : entity work.ExtenderImm
    port map (
      Inst31downto7 => ifid_instr(31 downto 7),
      opExImm       => std_logic_vector(cu_opExImm),
      signalOut     => id_imm
    );

  -- RegFile em modo leitura durante esta etapa incremental.
  -- Escrita de WB sera conectada quando MEM/WB estiver pronto.
  u_regfile : entity work.RegFile
    port map (
      clk     => clk,
      clear   => reset,
      we      => '0',
      rs1     => id_rs1_idx,
      rs2     => id_rs2_idx,
      rd      => (others => '0'),
      data_in => (others => '0'),
      d_rs1   => id_rs1_val,
      d_rs2   => id_rs2_val
    );

  ----------------------------------------------------------------------
  -- IF stage
  ----------------------------------------------------------------------
  u_pc_fetch : entity work.pc_fetch
    port map (
      clk            => clk,
      reset          => reset,
      if_pc_write_en => if_pc_write_en,
      pc_src         => pc_src,
      branch_target  => branch_target,
      jalr_target    => jalr_target,
      pc_out         => if_pc,
      pc4_out        => if_pc4,
      rom_addr       => rom_addr,
      rom_rden       => rom_rden
    );

  ----------------------------------------------------------------------
  -- IF/ID register (1 de 4 registradores de pipeline)
  ----------------------------------------------------------------------
  u_reg_if_id : entity work.reg_IF_ID
    port map (
      clk           => clk,
      reset         => reset,
      ifid_write_en => ifid_write_en,
      flush         => ex_branch_taken,
      in_pc         => if_pc,
      in_pc4        => if_pc4,
      in_instr      => rom_data,
      ifid_valid    => ifid_valid,
      ifid_pc       => ifid_pc,
      ifid_pc4      => ifid_pc4,
      ifid_instr    => ifid_instr
    );

  ----------------------------------------------------------------------
  -- ID stage combinacional: Control Unit (substitui InstructionDecoder)
  ----------------------------------------------------------------------
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

  ----------------------------------------------------------------------
  -- Bubble mux entre Control Unit e reg_ID_EX
  ----------------------------------------------------------------------
  u_bubble_mux : entity work.bubble_mux
    port map (
      sel_bubble         => id_bubble_sel,
      weReg_i            => cu_weReg,
      weRAM_i            => cu_weRAM,
      reRAM_i            => cu_reRAM,
      eRAM_i             => cu_eRAM,
      isMulDiv_i         => cu_isMulDiv,
      startMul_i         => startMul_raw,
      selMuxPc4ALU_i     => cu_selMuxPc4ALU,
      opExImm_i          => cu_opExImm,
      selMuxALUPc4RAM_i  => cu_selMuxALUPc4RAM,
      opExRAM_i          => cu_opExRAM,
      selMuxRS2Imm_i     => cu_selMuxRS2Imm,
      selPCRS1_i         => cu_selPCRS1,
      opALU_i            => cu_opALU,
      opCode_i           => cu_opCode,
      funct3_i           => cu_funct3,
      weReg_o            => idex_weReg,
      weRAM_o            => idex_weRAM,
      reRAM_o            => idex_reRAM,
      eRAM_o             => idex_eRAM,
      isMulDiv_o         => idex_isMulDiv,
      startMul_o         => idex_startMul,
      selMuxPc4ALU_o     => idex_selMuxPc4ALU,
      opExImm_o          => idex_opExImm,
      selMuxALUPc4RAM_o  => idex_selMuxALUPc4RAM,
      opExRAM_o          => idex_opExRAM,
      selMuxRS2Imm_o     => idex_selMuxRS2Imm,
      selPCRS1_o         => idex_selPCRS1,
      opALU_o            => idex_opALU,
      opCode_o           => idex_opCode,
      funct3_o           => idex_funct3
    );

  ----------------------------------------------------------------------
  -- ID/EX register (2 de 4 registradores de pipeline)
  ----------------------------------------------------------------------
  u_reg_id_ex : entity work.reg_ID_EX
    port map (
      clk                 => clk,
      reset               => reset,
      en                  => ifid_write_en,
      flush               => ex_branch_taken,
      in_valid            => ifid_valid,
      in_pc               => ifid_pc,
      in_pc4              => ifid_pc4,
      in_instr            => ifid_instr,
      in_rs1_idx          => id_rs1_idx,
      in_rs2_idx          => id_rs2_idx,
      in_rd_idx           => id_rd_idx,
      in_rs1_val          => id_rs1_val,
      in_rs2_val          => id_rs2_val,
      in_imm              => id_imm,
      in_selMuxPc4ALU     => idex_selMuxPc4ALU,
      in_opExImm          => idex_opExImm,
      in_selMuxALUPc4RAM  => idex_selMuxALUPc4RAM,
      in_weReg            => idex_weReg,
      in_opExRAM          => idex_opExRAM,
      in_selMuxRS2Imm     => idex_selMuxRS2Imm,
      in_selPCRS1         => idex_selPCRS1,
      in_opALU            => idex_opALU,
      in_isMulDiv         => idex_isMulDiv,
      in_startMul         => idex_startMul,
      in_weRAM            => idex_weRAM,
      in_reRAM            => idex_reRAM,
      in_eRAM             => idex_eRAM,
      in_opCode           => idex_opCode,
      in_funct3           => idex_funct3,
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

  ----------------------------------------------------------------------
  -- TODO integração Passo 2+:
  -- 1. Instanciar reg_EX_MEM.
  -- 2. Instanciar reg_MEM_WB.
  -- 4. Fechar datapath EX/MEM/WB reaproveitando ALU/StoreManager/ExtenderRAM.
  --
  -- Referência de nomes de entidades implementadas:
  --   reg_IF_ID
  --   reg_ID_EX
  --   reg_EX_MEM (pendente)
  --   reg_MEM_WB (pendente)
  ----------------------------------------------------------------------

  -- Defaults temporários até EX/MEM/WB serem conectados.
  ram_addr    <= (others => '0');
  ram_wdata   <= (others => '0');
  ram_en      <= '0';
  ram_wren    <= '0';
  ram_rden    <= '0';
  ram_byteena <= (others => '0');

  -- Evita warning de sinal não usado durante integração incremental.
  -- Quartus normalmente remove lógica morta na síntese.
  -- pragma translate_off
  assert not (ifid_valid = 'X' or ifid_pc(0) = 'X' or ifid_pc4(0) = 'X' or ram_rdata(0) = 'X')
    report "Placeholder assert for incremental integration"
    severity note;
  -- pragma translate_on

end architecture rtl;
