library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_ctrl_consts.all;

entity ALU is

    port (
        op          : in  std_logic_vector(4 downto 0);
        dA          : in  std_logic_vector(31 downto 0);
        dB          : in  std_logic_vector(31 downto 0);
        dataOut     : out std_logic_vector(31 downto 0);
		    branch      : out std_logic
    );

end entity;

architecture RTL of ALU is

begin

process(op, dA, dB)
begin
  -- default (safety)
  dataOut <= (others => '0');
  branch  <= '0';

  if (op = OPALU_PASS_B) then
    -- PASS_B
    dataOut <= dB;
    branch  <= '0';

  elsif (op = OPALU_ADD) then
    -- ADD
    dataOut <= std_logic_vector(unsigned(dA) + unsigned(dB));
    branch  <= '0';

  elsif (op = OPALU_XOR) then
    -- XOR
    dataOut <= dA xor dB;
    branch  <= '0';

  elsif (op = OPALU_OR) then
    -- OR
    dataOut <= dA or dB;
    branch  <= '0';

  elsif (op = OPALU_AND) then
    -- AND
    dataOut <= dA and dB;
    branch  <= '0';

  elsif (op = OPALU_SLL) then
    -- SLL  (logical left)
    dataOut <= std_logic_vector(shift_left(unsigned(dA), to_integer(unsigned(dB(4 downto 0)))));
    branch  <= '0';

  elsif (op = OPALU_SRL) then
    -- SRL  (logical right)
    dataOut <= std_logic_vector(shift_right(unsigned(dA), to_integer(unsigned(dB(4 downto 0)))));
    branch  <= '0';

  elsif (op = OPALU_SRA) then
    -- SRA  (arithmetic right)
    dataOut <= std_logic_vector(shift_right(signed(dA), to_integer(unsigned(dB(4 downto 0)))));
    branch  <= '0';

  elsif (op = OPALU_SUB) then
    -- SUB
    dataOut <= std_logic_vector(unsigned(dA) - unsigned(dB));
    branch  <= '0';

  elsif (op = OPALU_SLT) then
    -- SLT (signed)
    if signed(dA) < signed(dB) then
      dataOut <= (31 downto 1 => '0') & '1';
    else
      dataOut <= (others => '0');
    end if;
	 
    branch <= '0';

  elsif (op = OPALU_SLTU) then
    -- SLTU (unsigned)
    if unsigned(dA) < unsigned(dB) then
      dataOut <= (31 downto 1 => '0') & '1';
    else
      dataOut <= (others => '0');
    end if;
	 
    branch <= '0';

  elsif (op = OPALU_BEQ) then
    -- BEQ
    dataOut <= (others => '0');
    if dA = dB then 
	   branch <= '1'; else branch <= '0'; 
	 end if;

  elsif (op = OPALU_BNE) then
    -- BNE
    dataOut <= (others => '0');
    if dA /= dB then 
	   branch <= '1'; else branch <= '0'; 
	 end if;

  elsif (op = OPALU_BLT) then
    -- BLT (signed)
    dataOut <= (others => '0');
    if signed(dA) < signed(dB) then 
	   branch <= '1'; else branch <= '0'; 
	 end if;

  elsif (op = OPALU_BGE) then
    -- BGE (signed)
    dataOut <= (others => '0');
    if signed(dA) >= signed(dB) then 
	   branch <= '1'; else branch <= '0'; 
	  end if;

  elsif (op = OPALU_BLTU) then
    -- BLTU (unsigned)
    dataOut <= (others => '0');
    if unsigned(dA) < unsigned(dB) then 
	   branch <= '1'; else branch <= '0'; 
	 end if;

  elsif (op = OPALU_BGEU) then
    -- BGEU (unsigned)
    dataOut <= (others => '0');
    if unsigned(dA) >= unsigned(dB) then 
	   branch <= '1'; else branch <= '0'; 
	 end if;

  else
    -- keep defaults
    null;
  end if;
end process;


end architecture;
