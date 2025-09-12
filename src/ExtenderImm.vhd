library ieee;
use ieee.std_logic_1164.all;
use work.rv32i_ctrl_consts.all;  -- importa as constantes

entity ExtenderImm is 
  port(
    signalIn  : in std_logic_vector(24 downto 0);
    opExImm   : in std_logic_vector(2 downto 0);
    signalOut : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behaviour of ExtenderImm is
begin
  process(signalIn, opExImm)
  begin
    -- U: sext(instr[31:12] << 12)  == instr[31:12] & 12x'0'
    if    (opExImm = OPEXIMM_U) then 
      signalOut <= signalIn(24 downto 5) & (11 downto 0 => '0');
    
    -- I: sext(instr[31:20])  (12 bits sign-extended)
    elsif (opExImm = OPEXIMM_I) then 
      signalOut <= (31 downto 12 => signalIn(24)) & signalIn(24 downto 13);
    
    -- I_shamt: zext(instr[24:20]) (5 bits zero-extended)
    elsif (opExImm = OPEXIMM_I_SHAMT) then 
      signalOut <= (31 downto 5 => '0') & signalIn(17 downto 13);
    
    -- JAL: sext(inst[31 & 30:21 & 20 & 19:12 & '0'])
    elsif (opExImm = OPEXIMM_JAL) then 
      signalOut <= (31 downto 21 => signalIn(24)) &  -- sign extend (11 bits)
                   signalIn(24) &                    -- imm[20]
                   signalIn(12 downto 5) &           -- imm[19:12]
                   signalIn(13) &                    -- imm[11]
                   signalIn(23 downto 14) &          -- imm[10:1]
                   '0';
    
    -- JALR: sext(inst[31:20])  (mesmo slice do I-type)
    elsif (opExImm = OPEXIMM_JALR) then 
      signalOut <= (31 downto 12 => signalIn(24)) & signalIn(24 downto 13);
    
    -- S: sext(inst[31:25] & inst[11:7])
    elsif (opExImm = OPEXIMM_S) then 
      signalOut <= (31 downto 12 => signalIn(24)) & 
                   (signalIn(24 downto 18) & signalIn(4 downto 0));
    
    else 
      signalOut <= (others => '0'); -- ERROR
    end if;
  end process;
end architecture;
