library ieee;
use ieee.std_logic_1164.all;

entity ExtenderImm is 
  port(
    signalIn  : in std_logic_vector(24 downto 0);
	 opExImm   : in std_logic_vector(2 downto 0);
	 signalOut : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behaviour of ExtenderImm is

  -- add necessary signals here
  
begin

process(signalIn, opExImm)
begin

  -- U: sext(instr[31:12] << 12)  == instr[31:12] & 12x'0'
  -- instr[31:12] = signalIn(24 downto 5)
  if    (opExImm = "000") then signalOut <= signalIn(24 downto 5) & (11 downto 0 => '0');
  
  
  -- I: sext(instr[31:20])  (12 bits sign-extended)
  -- instr[31:20] = signalIn(24 downto 13)
  elsif (OpExImm = "001") then signalOut <= (31 downto 12 => signalIn(24)) & signalIn(24 downto 13);
  
  
  -- I_shamt: zext(instr[24:20]) (5 bits zero-extended)
  -- instr[24:20] = signalIn(17 downto 13)
  elsif (OpExImm = "010") then signalOut <= (31 downto 5 => '0') & signalIn(17 downto 13);
  
  
  -- JAL: sext(inst[31 & 30:21 & 20 & 19:12 & '0'])
  -- imm20 = inst[31] = signalIn(24)
  -- imm10:1 = inst[30:21] = signalIn(23 downto 14)
  -- imm11   = inst[20]    = signalIn(13)
  -- imm19:12= inst[19:12] = signalIn(12 downto 5)
  elsif (OpExImm = "011") then signalOut <= (31 downto 21 => signalIn(24)) &  -- sign extend (11 bits)
														  signalIn(24) &                    -- imm[20]
														  signalIn(12 downto 5) &           -- imm[19:12]
														  signalIn(13) &                    -- imm[11]
														  signalIn(23 downto 14) &          -- imm[10:1]
														  '0';

  -- JALR: sext(inst[31:20])  (same slice as I-type)														  
  elsif (OpExImm = "100") then signalOut <= (31 downto 12 => signalIn(24)) & signalIn(24 downto 13);
  
  
  -- S: sext(inst[31:25] & inst[11:7])
  -- inst[31:25] = signalIn(24 downto 18)
  -- inst[11:7]  = signalIn(4 downto 0)
  elsif (OpExImm = "101") then signalOut <= (31 downto 12 => signalIn(24)) & (signalIn(24 downto 18) & signalIn(4 downto 0));
  
  else signalOut <= "00000000000000000000000000000000"; -- ERROR
  end if;

end process;


end architecture;