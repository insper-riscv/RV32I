library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity StoreManager is
  port(
    opcode   : in  std_logic_vector(6 downto 0);
    funct3   : in  std_logic_vector(2 downto 0);
    EA       : in  std_logic_vector(1 downto 0);
    rs2Val   : in  std_logic_vector(31 downto 0);
    data_out : out std_logic_vector(31 downto 0);
    mask     : out std_logic_vector(3 downto 0)
  );
end entity;

architecture behaviour of StoreManager is
begin

process(opcode, funct3, EA, rs2Val)
  variable dout : std_logic_vector(31 downto 0);
  variable m    : std_logic_vector(3 downto 0);
begin
  dout := (others => '0');
  m    := (others => '0');

  if (opcode = "0100011") then -- STORE instructions
    case funct3 is

      when "010" =>  -- SW (Store Word)
        dout := rs2Val;
        m    := "1111";  -- enable all bytes

      when "001" =>  -- SH (Store Halfword)
        if EA(1) = '0' then
          dout(15 downto 0) := rs2Val(15 downto 0);
          m := "0011";  -- bytes 0 e 1
        else
          dout(31 downto 16) := rs2Val(15 downto 0);
          m := "1100";  -- bytes 2 e 3
        end if;

      when "000" =>  -- SB (Store Byte)
        case EA is
          when "00" =>
            dout(7 downto 0) := rs2Val(7 downto 0);
            m := "0001";
          when "01" =>
            dout(15 downto 8) := rs2Val(7 downto 0);
            m := "0010";
          when "10" =>
            dout(23 downto 16) := rs2Val(7 downto 0);
            m := "0100";
          when others => -- "11"
            dout(31 downto 24) := rs2Val(7 downto 0);
            m := "1000";
        end case;

      when others =>
        dout := (others => '0');
        m    := (others => '0');
    end case;
  else
    dout := (others => '0');
    m    := (others => '0');
  end if;

  data_out <= dout;
  mask     <= m;
end process;

end architecture;
