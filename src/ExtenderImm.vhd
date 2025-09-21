library ieee;
use ieee.std_logic_1164.all;
use work.rv32i_ctrl_consts.all;  -- importa as constantes

entity ExtenderImm is 
  port(
    Inst31downto7  : in std_logic_vector(24 downto 0);
    opExImm   : in std_logic_vector(2 downto 0);
    signalOut : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behaviour of ExtenderImm is
begin
  process(Inst31downto7, opExImm)
  begin
    -- U: sext(instr[31:12] << 12)  == instr[31:12] & 12x'0'
    if    (opExImm = OPEXIMM_U) then 
      signalOut <= Inst31downto7(24 downto 5) & (11 downto 0 => '0');
    
    -- I: sext(instr[31:20])  (12 bits sign-extended)
    elsif (opExImm = OPEXIMM_I) then 
      signalOut <= (31 downto 12 => Inst31downto7(24)) & Inst31downto7(24 downto 13);
    
    -- I_shamt: zext(instr[24:20]) (5 bits zero-extended)
    elsif (opExImm = OPEXIMM_I_SHAMT) then 
      signalOut <= (31 downto 5 => '0') & Inst31downto7(17 downto 13);
    
    -- JAL: sext(inst[31 & 30:21 & 20 & 19:12 & '0'])
    elsif (opExImm = OPEXIMM_J) then 
      signalOut <= (31 downto 21 => Inst31downto7(24)) &  -- sign extend (11 bits)
                   Inst31downto7(24) &                    -- imm[20]
                   Inst31downto7(12 downto 5) &           -- imm[19:12]
                   Inst31downto7(13) &                    -- imm[11]
                   Inst31downto7(23 downto 14) &          -- imm[10:1]
                   '0';

    elsif (opExImm = OPEXIMM_B) then
      signalOut <= (31 downto 13 => Inst31downto7(24)) &  -- sign extend
                  Inst31downto7(24) &                    -- imm[12] = instr[31]
                  Inst31downto7(0) &                     -- imm[11] = instr[7]
                  Inst31downto7(23 downto 18) &          -- imm[10:5] = instr[30:25]
                  Inst31downto7(4 downto 1) &            -- imm[4:1]  = instr[11:8]
                  '0';     
    
    -- S: sext(inst[31:25] & inst[11:7])
    elsif (opExImm = OPEXIMM_S) then 
      signalOut <= (31 downto 12 => Inst31downto7(24)) & 
                   (Inst31downto7(24 downto 18) & Inst31downto7(4 downto 0));
    
    else 
      signalOut <= (others => '0'); -- ERROR
    end if;
  end process;
end architecture;
