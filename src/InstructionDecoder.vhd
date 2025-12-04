library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_consts.all;

entity InstructionDecoder is
  port (
    opcode  : in  std_logic_vector(6 downto 0);
    funct3  : in  std_logic_vector(2 downto 0);
    funct7  : in  std_logic_vector(6 downto 0);

    selMuxPc4ALU    : out std_logic;
    opExImm         : out std_logic_vector(2 downto 0);
    selMuxALUPc4RAM : out std_logic_vector(1 downto 0);
    weReg           : out std_logic;
    opExRAM         : out std_logic_vector(2 downto 0);
    selMuxRS2Imm    : out std_logic;
    selPCRS1        : out std_logic;
    opALU           : out std_logic_vector(4 downto 0);
    weRAM           : out std_logic;
    reRAM           : out std_logic;
    eRAM            : out std_logic
  );
end entity;

architecture behaviour of InstructionDecoder is

  -- pre-decode / type signals
  signal is_r_type  : std_logic;
  signal is_i_type  : std_logic;
  signal is_load    : std_logic;
  signal is_store   : std_logic;
  signal is_branch  : std_logic;
  signal is_jal     : std_logic;
  signal is_jalr    : std_logic;
  signal is_lui     : std_logic;
  signal is_auipc   : std_logic;

begin

  -- Pre-decode by opcode (single place comparing opcode)
  process(opcode)
  begin
    is_r_type  <= '0';
    is_i_type  <= '0';
    is_load    <= '0';
    is_store   <= '0';
    is_branch  <= '0';
    is_jal     <= '0';
    is_jalr    <= '0';
    is_lui     <= '0';
    is_auipc   <= '0';

    case opcode is
      when "0110011" => is_r_type <= '1';        -- R-type
      when "0010011" => is_i_type <= '1';        -- I-type ALU/shift-immediate
      when "0000011" => is_load <= '1';          -- loads
      when "0100011" => is_store <= '1';         -- stores
      when "1100011" => is_branch <= '1';        -- branches
      when "1101111" => is_jal <= '1';           -- JAL
      when "1100111" => is_jalr <= '1';          -- JALR
      when "0110111" => is_lui <= '1';           -- LUI
      when "0010111" => is_auipc <= '1';         -- AUIPC
      when others    => null;
    end case;
  end process;

  -- Main decoder process: set defaults once, then override by case branches
  process(opcode, funct3, funct7, is_r_type, is_i_type, is_load, is_store, is_branch, is_jal, is_jalr, is_lui, is_auipc)
  begin
    -- defaults (same as your "else" branch)
    selMuxPc4ALU    <= '0';
    opExImm         <= (others => '0');
    selMuxALUPc4RAM <= (others => '0');
    weReg           <= '0';
    opExRAM         <= (others => '0');
    selMuxRS2Imm    <= '0';
    selPCRS1        <= '0';
    opALU           <= (others => '0');
    weRAM           <= '0';
    reRAM           <= '0';
    eRAM            <= '0';

    -- Use opcode-driven case to avoid many repeated opcode comparisons
    case opcode is

      -- I-type ALU (immediate / shifts)
      when "0010011" =>
        case funct3 is
          when "001" =>  -- SLLI (funct7 = 0000000)
            if funct7 = "0000000" then
              selMuxPc4ALU    <= '0';
              opExImm         <= OPEXIMM_I_SHAMT;
              selMuxALUPc4RAM <= "00";
              weReg           <= '1';
              opExRAM         <= "000";
              selMuxRS2Imm    <= '1';
              selPCRS1        <= '1';
              opALU           <= OPALU_SLL;
              weRAM           <= '0';
              reRAM           <= '0';
              eRAM            <= '0';
            end if;

          when "101" =>  -- SRLI / SRAI
            if funct7 = "0000000" then -- SRLI
              selMuxPc4ALU    <= '0';
              opExImm         <= OPEXIMM_I_SHAMT;
              selMuxALUPc4RAM <= "00";
              weReg           <= '1';
              opExRAM         <= "000";
              selMuxRS2Imm    <= '1';
              selPCRS1        <= '1';
              opALU           <= OPALU_SRL;
              weRAM           <= '0';
              reRAM           <= '0';
              eRAM            <= '0';
            elsif funct7 = "0100000" then -- SRAI
              selMuxPc4ALU    <= '0';
              opExImm         <= OPEXIMM_I_SHAMT;
              selMuxALUPc4RAM <= "00";
              weReg           <= '1';
              opExRAM         <= "000";
              selMuxRS2Imm    <= '1';
              selPCRS1        <= '1';
              opALU           <= OPALU_SRA;
              weRAM           <= '0';
              reRAM           <= '0';
              eRAM            <= '0';
            end if;

          when "000" =>  -- ADDI
            selMuxPc4ALU    <= '0';
            opExImm         <= OPEXIMM_I;
            selMuxALUPc4RAM <= "00";
            weReg           <= '1';
            opExRAM         <= "000";
            selMuxRS2Imm    <= '1';
            selPCRS1        <= '1';
            opALU           <= OPALU_ADD;
            weRAM           <= '0';
            reRAM           <= '0';
            eRAM            <= '0';

          when "100" => -- XORI
            selMuxPc4ALU    <= '0';
            opExImm         <= OPEXIMM_I;
            selMuxALUPc4RAM <= "00";
            weReg           <= '1';
            opExRAM         <= "000";
            selMuxRS2Imm    <= '1';
            selPCRS1        <= '1';
            opALU           <= OPALU_XOR;
            weRAM           <= '0';
            reRAM           <= '0';
            eRAM            <= '0';

          when "110" => -- ORI
            selMuxPc4ALU    <= '0';
            opExImm         <= OPEXIMM_I;
            selMuxALUPc4RAM <= "00";
            weReg           <= '1';
            opExRAM         <= "000";
            selMuxRS2Imm    <= '1';
            selPCRS1        <= '1';
            opALU           <= OPALU_OR;
            weRAM           <= '0';
            reRAM           <= '0';
            eRAM            <= '0';

          when "111" => -- ANDI
            selMuxPc4ALU    <= '0';
            opExImm         <= OPEXIMM_I;
            selMuxALUPc4RAM <= "00";
            weReg           <= '1';
            opExRAM         <= "000";
            selMuxRS2Imm    <= '1';
            selPCRS1        <= '1';
            opALU           <= OPALU_AND;
            weRAM           <= '0';
            reRAM           <= '0';
            eRAM            <= '0';

          when "010" => -- SLTI
            selMuxPc4ALU    <= '0';
            opExImm         <= OPEXIMM_I;
            selMuxALUPc4RAM <= "00";
            weReg           <= '1';
            opExRAM         <= "000";
            selMuxRS2Imm    <= '1';
            selPCRS1        <= '1';
            opALU           <= OPALU_SLT;
            weRAM           <= '0';
            reRAM           <= '0';
            eRAM            <= '0';

          when "011" => -- SLTIU
            selMuxPc4ALU    <= '0';
            opExImm         <= OPEXIMM_I;
            selMuxALUPc4RAM <= "00";
            weReg           <= '1';
            opExRAM         <= "000";
            selMuxRS2Imm    <= '1';
            selPCRS1        <= '1';
            opALU           <= OPALU_SLTU;
            weRAM           <= '0';
            reRAM           <= '0';
            eRAM            <= '0';

          when others =>
            null;
        end case;

      -- R-type ALU
      when "0110011" =>
        case funct3 is
          when "000" =>
            if funct7 = "0000000" then -- ADD
              selMuxPc4ALU    <= '0';
              opExImm         <= (others => '0');
              selMuxALUPc4RAM <= "00";
              weReg           <= '1';
              opExRAM         <= "000";
              selMuxRS2Imm    <= '0';
              selPCRS1        <= '1';
              opALU           <= OPALU_ADD;
              weRAM           <= '0';
              reRAM           <= '0';
              eRAM            <= '0';
            elsif funct7 = "0100000" then -- SUB
              selMuxPc4ALU    <= '0';
              opExImm         <= (others => '0');
              selMuxALUPc4RAM <= "00";
              weReg           <= '1';
              opExRAM         <= "000";
              selMuxRS2Imm    <= '0';
              selPCRS1        <= '1';
              opALU           <= OPALU_SUB;
              weRAM           <= '0';
              reRAM           <= '0';
              eRAM            <= '0';
            end if;

          when "100" => -- XOR
            selMuxPc4ALU    <= '0';
            opExImm         <= (others => '0');
            selMuxALUPc4RAM <= "00";
            weReg           <= '1';
            opExRAM         <= "000";
            selMuxRS2Imm    <= '0';
            selPCRS1        <= '1';
            opALU           <= OPALU_XOR;
            weRAM           <= '0';
            reRAM           <= '0';
            eRAM            <= '0';

          when "110" => -- OR
            selMuxPc4ALU    <= '0';
            opExImm         <= (others => '0');
            selMuxALUPc4RAM <= "00";
            weReg           <= '1';
            opExRAM         <= "000";
            selMuxRS2Imm    <= '0';
            selPCRS1        <= '1';
            opALU           <= OPALU_OR;
            weRAM           <= '0';
            reRAM           <= '0';
            eRAM            <= '0';

          when "111" => -- AND
            selMuxPc4ALU    <= '0';
            opExImm         <= (others => '0');
            selMuxALUPc4RAM <= "00";
            weReg           <= '1';
            opExRAM         <= "000";
            selMuxRS2Imm    <= '0';
            selPCRS1        <= '1';
            opALU           <= OPALU_AND;
            weRAM           <= '0';
            reRAM           <= '0';
            eRAM            <= '0';

          when "001" => -- SLL
            selMuxPc4ALU    <= '0';
            opExImm         <= (others => '0');
            selMuxALUPc4RAM <= "00";
            weReg           <= '1';
            opExRAM         <= "000";
            selMuxRS2Imm    <= '0';
            selPCRS1        <= '1';
            opALU           <= OPALU_SLL;
            weRAM           <= '0';
            reRAM           <= '0';
            eRAM            <= '0';

          when "101" =>
            if funct7 = "0000000" then -- SRL
              selMuxPc4ALU    <= '0';
              opExImm         <= (others => '0');
              selMuxALUPc4RAM <= "00";
              weReg           <= '1';
              opExRAM         <= "000";
              selMuxRS2Imm    <= '0';
              selPCRS1        <= '1';
              opALU           <= OPALU_SRL;
              weRAM           <= '0';
              reRAM           <= '0';
              eRAM            <= '0';
            elsif funct7 = "0100000" then -- SRA
              selMuxPc4ALU    <= '0';
              opExImm         <= (others => '0');
              selMuxALUPc4RAM <= "00";
              weReg           <= '1';
              opExRAM         <= "000";
              selMuxRS2Imm    <= '0';
              selPCRS1        <= '1';
              opALU           <= OPALU_SRA;
              weRAM           <= '0';
              reRAM           <= '0';
              eRAM            <= '0';
            end if;

          when "010" => -- SLT
            selMuxPc4ALU    <= '0';
            opExImm         <= (others => '0');
            selMuxALUPc4RAM <= "00";
            weReg           <= '1';
            opExRAM         <= "000";
            selMuxRS2Imm    <= '0';
            selPCRS1        <= '1';
            opALU           <= OPALU_SLT;
            weRAM           <= '0';
            reRAM           <= '0';
            eRAM            <= '0';

          when "011" => -- SLTU
            selMuxPc4ALU    <= '0';
            opExImm         <= (others => '0');
            selMuxALUPc4RAM <= "00";
            weReg           <= '1';
            opExRAM         <= "000";
            selMuxRS2Imm    <= '0';
            selPCRS1        <= '1';
            opALU           <= OPALU_SLTU;
            weRAM           <= '0';
            reRAM           <= '0';
            eRAM            <= '0';

          when others =>
            null;
        end case;

      -- Branches (B-type)
      when "1100011" =>
        selMuxPc4ALU    <= '0';
        opExImm         <= OPEXIMM_B;
        selMuxALUPc4RAM <= "00";
        weReg           <= '0';
        opExRAM         <= "000";
        selMuxRS2Imm    <= '0';
        selPCRS1        <= '1';
        weRAM           <= '0';
        reRAM           <= '0';
        eRAM            <= '0';

        case funct3 is
          when "000" => opALU <= OPALU_BEQ;
          when "001" => opALU <= OPALU_BNE;
          when "100" => opALU <= OPALU_BLT;
          when "101" => opALU <= OPALU_BGE;
          when "110" => opALU <= OPALU_BLTU;
          when "111" => opALU <= OPALU_BGEU;
          when others => opALU <= (others => '0');
        end case;

      -- Loads (I-type loads)
      when "0000011" =>
        selMuxPc4ALU    <= '0';
        opExImm         <= OPEXIMM_I;
        selMuxALUPc4RAM <= "10";
        weReg           <= '1';
        selMuxRS2Imm    <= '1';
        selPCRS1        <= '1';
        opALU           <= OPALU_ADD;
        weRAM           <= '0';
        reRAM           <= '1';
        eRAM            <= '1';

        case funct3 is
          when "010" => opExRAM <= "000"; -- LW
          when "001" => opExRAM <= OPEXRAM_LH; -- LH
          when "101" => opExRAM <= OPEXRAM_LHU; -- LHU
          when "000" => opExRAM <= OPEXRAM_LB; -- LB
          when "100" => opExRAM <= OPEXRAM_LBU; -- LBU
          when others => opExRAM <= "000";
        end case;

      -- Stores (S-type)
      when "0100011" =>
        selMuxPc4ALU    <= '0';
        opExImm         <= OPEXIMM_S;
        selMuxALUPc4RAM <= "00";
        weReg           <= '0';
        opExRAM         <= "000";
        selMuxRS2Imm    <= '1';
        selPCRS1        <= '1';
        opALU           <= OPALU_ADD;
        weRAM           <= '1';
        reRAM           <= '0';
        eRAM            <= '1';

      -- LUI
      when "0110111" =>
        selMuxPc4ALU    <= '0';
        opExImm         <= OPEXIMM_U;
        selMuxALUPc4RAM <= "00";
        weReg           <= '1';
        opExRAM         <= "000";
        selMuxRS2Imm    <= '1';
        selPCRS1        <= '0';
        opALU           <= OPALU_PASS_B;
        weRAM           <= '0';
        reRAM           <= '0';
        eRAM            <= '0';

      -- AUIPC
      when "0010111" =>
        selMuxPc4ALU    <= '0';
        opExImm         <= OPEXIMM_U;
        selMuxALUPc4RAM <= "00";
        weReg           <= '1';
        opExRAM         <= "000";
        selMuxRS2Imm    <= '1';
        selPCRS1        <= '0';
        opALU           <= OPALU_ADD;
        weRAM           <= '0';
        reRAM           <= '0';
        eRAM            <= '0';

      -- JAL
      when "1101111" =>
        selMuxPc4ALU    <= '1';
        opExImm         <= OPEXIMM_J;
        selMuxALUPc4RAM <= "01";
        weReg           <= '1';
        opExRAM         <= "000";
        selMuxRS2Imm    <= '1';
        selPCRS1        <= '0';
        opALU           <= OPALU_ADD;
        weRAM           <= '0';
        reRAM           <= '0';
        eRAM            <= '0';

      -- JALR
      when "1100111" =>
        selMuxPc4ALU    <= '1';
        opExImm         <= OPEXIMM_I;
        selMuxALUPc4RAM <= "01";
        weReg           <= '1';
        opExRAM         <= "000";
        selMuxRS2Imm    <= '1';
        selPCRS1        <= '1';
        opALU           <= OPALU_JALR;
        weRAM           <= '0';
        reRAM           <= '0';
        eRAM            <= '0';

      when others =>
        null;
    end case;
  end process;

end architecture;
