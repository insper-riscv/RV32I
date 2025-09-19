library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity edgeDetector is
     Port ( clk     : in  STD_LOGIC;
              entrada : in  STD_LOGIC;
              saida   : out STD_LOGIC);
end entity;

architecture bordaSubida of edgeDetector is
    signal saidaQ : STD_LOGIC;
begin
  process(clk)
  begin
        if rising_edge(clk) then
            saidaQ <= entrada;
        end if;
  end process;
  saida <= entrada and (not saidaQ);
end  architecture bordaSubida;


architecture bordaDescida of edgeDetector is
    signal saidaQ : STD_LOGIC;
begin
  process(clk)
  begin
        if rising_edge(clk) then
            saidaQ <= entrada;
        end if;
  end process;
  saida <= (not entrada) and saidaQ;
end  architecture bordaDescida;