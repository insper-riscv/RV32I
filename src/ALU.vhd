library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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

  if (op = "00000") then
    -- PASS_B
    dataOut <= dB;
    branch  <= '0';

  elsif (op = "00001") then
    -- ADD
    dataOut <= std_logic_vector(unsigned(dA) + unsigned(dB));
    branch  <= '0';

  elsif (op = "00010") then
    -- XOR
    dataOut <= dA xor dB;
    branch  <= '0';

  elsif (op = "00011") then
    -- OR
    dataOut <= dA or dB;
    branch  <= '0';

  elsif (op = "00100") then
    -- AND
    dataOut <= dA and dB;
    branch  <= '0';

  elsif (op = "00101") then
    -- SLL  (logical left)
    dataOut <= std_logic_vector(shift_left(unsigned(dA), to_integer(unsigned(dB(4 downto 0)))));
    branch  <= '0';

  elsif (op = "00110") then
    -- SRL  (logical right)
    dataOut <= std_logic_vector(shift_right(unsigned(dA), to_integer(unsigned(dB(4 downto 0)))));
    branch  <= '0';

  elsif (op = "00111") then
    -- SRA  (arithmetic right)
    dataOut <= std_logic_vector(shift_right(signed(dA), to_integer(unsigned(dB(4 downto 0)))));
    branch  <= '0';

  elsif (op = "01000") then
    -- SUB
    dataOut <= std_logic_vector(unsigned(dA) - unsigned(dB));
    branch  <= '0';

  elsif (op = "01001") then
    -- SLT (signed)
    if signed(dA) < signed(dB) then
      dataOut <= (31 downto 1 => '0') & '1';
    else
      dataOut <= (others => '0');
    end if;
	 
    branch <= '0';

  elsif (op = "01010") then
    -- SLTU (unsigned)
    if unsigned(dA) < unsigned(dB) then
      dataOut <= (31 downto 1 => '0') & '1';
    else
      dataOut <= (others => '0');
    end if;
	 
    branch <= '0';

  elsif (op = "01011") then
    -- BEQ
    dataOut <= (others => '0');
    if dA = dB then 
	   branch <= '1'; else branch <= '0'; 
	 end if;

  elsif (op = "01100") then
    -- BNE
    dataOut <= (others => '0');
    if dA /= dB then 
	   branch <= '1'; else branch <= '0'; 
	 end if;

  elsif (op = "01101") then
    -- BLT (signed)
    dataOut <= (others => '0');
    if signed(dA) < signed(dB) then 
	   branch <= '1'; else branch <= '0'; 
	 end if;

  elsif (op = "01110") then
    -- BGE (signed)
    dataOut <= (others => '0');
    if signed(dA) >= signed(dB) then 
	   branch <= '1'; else branch <= '0'; 
	  end if;

  elsif (op = "01111") then
    -- BLTU (unsigned)
    dataOut <= (others => '0');
    if unsigned(dA) < unsigned(dB) then 
	   branch <= '1'; else branch <= '0'; 
	 end if;

  elsif (op = "10000") then
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
