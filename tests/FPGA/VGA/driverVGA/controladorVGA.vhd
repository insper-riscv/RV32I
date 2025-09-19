library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity controladorVGA is

  generic (
    h_pulse_width       : integer := 96;    --horizontal sync pulse width in pixels
    h_back_porch_width  : integer := 48;    --horizontal back porch width in pixels
    h_pixels_size       : integer := 640;   --horizontal display width in pixels
    h_front_porch_width : integer := 16;    --horizontal front porch width in pixels
    h_pulse_polarity    : std_logic := '0'; --horizontal sync pulse polarity (1 = positive, 0 = negative)
      --
    v_pulse_width       : integer := 2;     --vertical sync pulse width in rows
    v_back_porch_width  : integer := 33;    --vertical back porch width in rows
    v_pixels_size       : integer := 480;   --vertical display width in rows
    v_front_porch_width : integer := 10;    --vertical front porch width in rows
    v_pulse_polarity    : std_logic := '0'   --vertical sync pulse polarity (1 = positive, 0 = negative)
  );
  port(
    pixel_clk : IN    std_logic;  --pixel clock at frequency of VGA mode being used -> send to DAC
    reset_n   : IN    std_logic;  --active low asycnchronous reset
    HSync       : OUT std_logic;  --horizontal sync pulse
    VSync       : OUT std_logic;  --vertical sync pulse
    disp_enable : OUT std_logic;  --display enable ('1' = display time, '0' = blanking time)
    column    : OUT std_logic_vector(9 downto 0);
    row     : OUT std_logic_vector(9 downto 0)
  );
  
end entity;




architecture behavior of controladorVGA is
  
  constant  h_period  : natural := h_pulse_width + h_back_porch_width + h_pixels_size + h_front_porch_width;  --total number of pixel clocks in a row (96+48+640+16 = 800)
  constant  v_period  : natural := v_pulse_width + v_back_porch_width + v_pixels_size + v_front_porch_width;  --total number of rows (2+33+480+10 = 525)
  constant  mem_Size  : natural := (h_pixels_size/8)*(v_pixels_size/8); --Total posicoes na memoria de video
  signal hor_Active_Window  : std_logic := '0';
  signal vert_Active_Window : std_logic := '0';
  signal incrementaMemAddr  : std_logic := '0';
  signal display_en : std_logic := '0';
  signal h_sync, v_sync : std_logic;
  signal clk80colunas, clkLinha, clkContagemLinhas : std_logic;
  signal contagem8pixelsCols : std_logic_vector(3 downto 0);

begin

  process(pixel_clk, reset_n)
    variable hor_count  : natural RANGE 0 TO h_period - 1 := 0;                      --Contador horizontal (counts the columns)
    variable hor_Active_Window_Pixel_Count  : Integer RANGE -2 TO h_period - 1 := 0;  --Contador de pixels ativos na horizontal (counts the columns of chars)
    variable vert_count : natural RANGE 0 TO v_period - 1 := 0;                      --Contador Vertical (counts the rows)
    variable vert_Active_Window_Line_Count  : Integer RANGE -2 TO v_period - 1 := 0;  --Contador de pixels ativos na vertical (counts the rows of chars)
  
  begin
    if(reset_n = '0') then
      hor_count := 0;
      vert_count := 0;
      hor_Active_Window_Pixel_Count := 0;
      hor_Active_Window <= '0';
      vert_Active_Window_Line_Count := 0;
      vert_Active_Window <= '0';
      h_sync <= NOT h_pulse_polarity;  --Desativa sincronismo horizontal
      v_sync <= NOT v_pulse_polarity;  --Desativa sincronismo vertical
      display_en <= '0';
      column <= (others => '0');

    -- Incrementa os contadores:
    elsif(rising_edge(pixel_clk)) then
      if(hor_count < h_period - 1 ) then    --horizontal counter (pixels): 0 to 799
        hor_count := hor_count + 1;
      else
        hor_count := 0;
        if(vert_count < v_period - 1) then  --vertical counter (rows): 0 to 524
          vert_count := vert_count + 1;
          -- Create Vertical Active Window
          if(vert_count > (v_back_porch_width-1) and vert_count < (v_back_porch_width + v_pixels_size-1)) then
            vert_Active_Window <= '1';   -- Active Window
            vert_Active_Window_Line_Count := vert_Active_Window_Line_Count + 1;
          else
            if vert_Active_Window = '1' then
              vert_Active_Window_Line_Count := 524;
            end if;
            vert_Active_Window <= '0';

          end if;
        else
          vert_count := 0;
        end if;
      end if;
      if vert_count > (v_back_porch_width + v_pixels_size+2) then
        vert_Active_Window_Line_Count := -1;
      end if;

      -- Create Horizontal Sync
      if(hor_count > (h_back_porch_width + h_pixels_size + h_front_porch_width)) then    -- h_pulse_width
        h_sync <= h_pulse_polarity;   -- Create Horizontal Sync Pulse
      else
        h_sync <= NOT h_pulse_polarity;
      end if;

      -- Create Horizontal Active Window
      if(hor_count > (h_back_porch_width-2) and hor_count < (h_back_porch_width + h_pixels_size-1)) then
        hor_Active_Window <= '1';   -- Active Window
        hor_Active_Window_Pixel_Count := hor_Active_Window_Pixel_Count + 1;
      else
        if hor_Active_Window = '1' then
          hor_Active_Window_Pixel_Count := 639;
        end if;
        hor_Active_Window <= '0';
      end if;
      -- Para acertar o reinicio da contagem da coluna
      if(hor_count > (h_back_porch_width + h_pixels_size + 2)) then
        hor_Active_Window_Pixel_Count := -2;  --Precisa comecar de -2 para gerar o caracter adequadamente
      end if;

      column <= std_logic_vector(to_unsigned(hor_Active_Window_Pixel_Count,column'length));  --set horizontal char coordinate
      row    <= std_logic_vector(to_unsigned(vert_Active_Window_Line_Count,row'length));     --set vertical char coordinate

      -- Create Vertical Sync
      if(vert_count > (v_back_porch_width + v_pixels_size + v_front_porch_width)) then
        v_sync <= v_pulse_polarity;   -- Create Vertical Sync Pulse
      else
        v_sync <= NOT v_pulse_polarity;     --assert vertical sync pulse : entre 490 e 492
      end if;

      display_en <= hor_Active_Window AND vert_Active_Window;

    end if;
  end process;

  disp_enable <= display_en;

  HSync <= h_sync;
  VSync <= v_sync;
end architecture;