library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_pkg.all;

entity DataMem is
  port(
    addr: in std_logic_vector(31 downto 0);
    din_store: in std_logic_vector(31 downto 0);
    word_in: in std_logic_vector(31 downto 0);
    memwrite: in std_logic;
    memsize: in mem_size_t;
    memunsigned: in std_logic;
    dout_load: out std_logic_vector(31 downto 0);
    word_out: out std_logic_vector(31 downto 0);
    we_ram: out std_logic
  );
end entity;

architecture rtl of DataMem is
  signal lane: unsigned(1 downto 0);
  signal mask4: std_logic_vector(3 downto 0);
  signal mask32: std_logic_vector(31 downto 0);
  signal sh_byte: integer range 0 to 24;
  signal sh_half: integer range 0 to 16;
  signal b: std_logic_vector(7 downto 0);
  signal h: std_logic_vector(15 downto 0);
  signal load_res: std_logic_vector(31 downto 0);
  signal store_shifted: std_logic_vector(31 downto 0);
  signal we_int: std_logic;
begin
    
  lane<=unsigned(addr(1 downto 0));
  sh_byte<=to_integer(lane)*8;
  sh_half<=to_integer(unsigned(addr(1)))*16;
  b<=word_in(sh_byte+7 downto sh_byte);
  h<=word_in(sh_half+15 downto sh_half);
  process(memsize,memunsigned,b,h,word_in,addr)
  begin
    case memsize is
      when MS_B =>
        if memunsigned='1' then
          load_res<=x"000000" & b;
        else
          load_res<=(31 downto 8=>b(7)) & b;
        end if;
      when MS_H =>
        if addr(0)='0' then
          if memunsigned='1' then
            load_res<=x"0000" & h;
          else
            load_res<=(31 downto 16=>h(15)) & h;
          end if;
        else
          load_res<=(others=>'0');
        end if;
      when others =>
        if addr(1 downto 0)="00" then
          load_res<=word_in;
        else
          load_res<=(others=>'0');
        end if;
    end case;
  end process;
  dout_load<=load_res;
  process(memsize,addr,lane,din_store)
    variable m: unsigned(3 downto 0);
  begin
    case memsize is
      when MS_B => m:="0001" sll to_integer(lane);
      when MS_H => if addr(0)='0' then m:="0011" sll (to_integer(unsigned(addr(1)))*2); else m:="0000"; end if;
      when others => if addr(1 downto 0)="00" then m:="1111" else m:="0000" end if;
    end case;
    mask4:=std_logic_vector(m);
  end process;
  process(mask4)
  begin
    mask32<=(others=>'0');
    if mask4(0)='1' then mask32(7 downto 0)<=(others=>'1'); end if;
    if mask4(1)='1' then mask32(15 downto 8)<=(others=>'1'); end if;
    if mask4(2)='1' then mask32(23 downto 16)<=(others=>'1'); end if;
    if mask4(3)='1' then mask32(31 downto 24)<=(others=>'1'); end if;
  end process;
  process(memsize,addr,lane,din_store,sh_byte,sh_half)
    variable v: unsigned(31 downto 0);
  begin
    case memsize is
      when MS_B =>
        v:=shift_left(unsigned(x"000000"&din_store(7 downto 0)),sh_byte);
      when MS_H =>
        if addr(0)='0' then v:=shift_left(unsigned(x"0000"&din_store(15 downto 0)),sh_half); else v:=(others=>'0'); end if;
      when others =>
        if addr(1 downto 0)="00" then v:=unsigned(din_store); else v:=(others=>'0'); end if;
    end case;
    store_shifted<=std_logic_vector(v);
  end process;
  word_out<=(word_in and not mask32) or (store_shifted and mask32);
  we_int<=memwrite when mask4/="0000" else '0';
  we_ram<=we_int;
end architecture;