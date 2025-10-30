library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_consts.all;

-- L2IP

entity L2IP is
  port   (
    CLOCK_50 : in std_logic;
	 --CLK : in std_logic
	 HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);
	 LEDR : out std_logic_vector(9 downto 0);
	 SW : in std_logic_vector(9 downto 0);
	 FPGA_RESET_N : in std_logic;
	 GPIO_P : inout std_logic_vector(31 downto 0)
  );
end entity;

architecture behaviour of L2IP is

  -- add necessary signals here
  signal CLK : std_logic;
  
  signal MuxPc4ALU_out : std_logic_vector(31 downto 0);
  signal PC_out : std_logic_vector(31 downto 0);
  signal PC_out0 : std_logic_vector(31 downto 0);
  
  signal ROM_out : std_logic_vector(31 downto 0);
  
  signal MuxBubbleOut : std_logic_vector(31 downto 0);
  signal FFBubbleSelOut : std_logic;
  signal bubble_condition : std_logic;
  signal instruction_is_jmp: std_logic;
  constant JALR_OP : std_logic_vector(6 downto 0) := "1100111";
  constant JAL_OP  : std_logic_vector(6 downto 0) := "1101111";
  
  signal selMuxPc4ALU : std_logic;
  signal opExImm : std_logic_vector(2 downto 0);
  signal selMuxALUPc4RAM : std_logic_vector(1 downto 0);
  signal weReg : std_logic;
  signal opExRAM : std_logic_vector(2 downto 0);
  signal selMuxRS2Imm : std_logic;
  signal selMuxPCRS1 : std_logic;
  signal opALU : std_logic_vector(4 downto 0);
  signal mask : std_logic_vector(3 downto 0);
  signal weRAM, reRAM, eRAM : std_logic;
  
  signal ExtenderImm_out : std_logic_vector(31 downto 0);
  
  signal MuxALUPc4RAM_out : std_logic_vector(31 downto 0);
  signal d_rs1 : std_logic_vector(31 downto 0);
  signal d_rs2 : std_logic_vector(31 downto 0);
  signal out_StoreManager : std_logic_vector(31 downto 0);
  
  signal ALU_out : std_logic_vector(31 downto 0);
  signal PC40 : std_logic_vector(31 downto 0);
  signal PC4 : std_logic_vector(31 downto 0);
  signal addImmPC_out : std_logic_vector(31 downto 0);
  signal extenderRAM_out : std_logic_vector(31 downto 0);
  
  -- Created with ALU
  signal MuxPCRS1_out : std_logic_vector(31 downto 0);
  signal MuxRS2Imm_out : std_logic_vector(31 downto 0);
  signal branch_flag : std_logic;
  
  signal RAM_out : std_logic_vector(31 downto 0);
  
  signal selMuxPc4ALU_ext : std_logic_vector(1 downto 0);
  
  signal enable_led : std_logic;
  
  signal CLKbtn : std_logic;
 
   -- ========= MMIO / GPIO =========
  -- Seleção: 4KB em 0x8000_0000 (endereços de palavra)
  signal sel_gpio          : std_logic;
  signal gpio_addr_nibble  : std_logic_vector(3 downto 0);  -- 16 palavras (0x0..0xF)
  signal gpio_write_en     : std_logic;
  signal gpio_read_en      : std_logic;

  signal gpio_data_out     : std_logic_vector(31 downto 0);
  signal bus_rdata_preext  : std_logic_vector(31 downto 0);
  

  
  

begin

  -- Base 0x8000_0000 → bits [31:12] = x"80000"
  sel_gpio <= '1' when (ALU_out(31 downto 12) = x"80000") else '0';

  -- GPIO endereçado por PALAVRA; teu GPIO usa 4 bits de endereço (0..15)
  gpio_addr_nibble <= ALU_out(5 downto 2);

  -- Escrita/leitura válidas somente quando o teu “canal de memória” está ativo
  gpio_write_en <= '1' when (eRAM='1' and weRAM='1' and sel_gpio='1') else '0';
  gpio_read_en  <= '1' when (eRAM='1' and reRAM='1' and sel_gpio='1') else '0';


edgeDetectorKey : entity work.edgeDetector
    port map (
        clk    => CLOCK_50 and (not SW(0)),
        entrada=> not FPGA_RESET_N,
        saida  => CLKbtn
    );

CLK <= CLOCK_50 when SW(1) else CLKbtn;
			
			
PC0 : entity work.genericRegister
			generic map ( data_width => 32 )
			port map (
				clock => CLK,
				clear => SW(0),
				enable => '1',
				source => MuxPc4ALU_out,
				destination => PC_out0
			);
			
PC : entity work.genericRegister
			generic map ( data_width => 32 )
			port map (
				clock => CLK,
				clear => SW(0),
				enable => '1',
				source => PC_out0,
				destination => PC_out
			);
			
ROM : entity work.room
			port map (
				address => PC_out0(10 downto 2), /* Ignora os dois bits menos significativos pois a room ´e word addressable*/
				clock => CLK,
				q => ROM_out
			);
			
instruction_is_jmp <= '1' when ((MuxBubbleOut(6 downto 0) = JALR_OP) or (MuxBubbleOut(6 downto 0) = JAL_OP)) else '0';
bubble_condition <=(instruction_is_jmp or branch_flag);
			
BubbleSel : entity work.FlipFlop
			port map (
				clock => CLK,
				clear => SW(0),
				enable => '1',
				source => bubble_condition,
				destination => FFBubbleSelOut
			);
			
MuxBubble : entity work.genericMux2x1
    generic map ( dataWidth => 32 )
    port map (
        inputA_MUX => ROM_out,
        inputB_MUX => "00000000000000000000000000010011", /* addi x0, x0, 0 <- nao altera nada no programa (nop)*/ 
        selector_MUX => FFBubbleSelOut,
        output_MUX => MuxBubbleOut
    );

InstructionDecoder : entity work.InstructionDecoder
			port map (
				opcode => MuxBubbleOut(6 downto 0),
				funct3 => MuxBubbleOut(14 downto 12),
				funct7 => MuxBubbleOut(31 downto 25),
				
				selMuxPc4ALU => selMuxPc4ALU,
				opExImm => opExImm,
				selMuxALUPc4RAM => selMuxALUPc4RAM,
				weReg => weReg,
				opExRAM => opExRAM,
				selMuxRS2Imm => selMuxRS2Imm,
				selPCRS1 => selMuxPCRS1,
				opALU => opALU,
				weRAM => weRAM,
				reRAM => reRAM,
				eRAM => eRAM
			);
			
ExtenderImm : entity work.ExtenderImm
			port map (
				Inst31downto7 => MuxBubbleOut(31 downto 7),
				opExImm => opExImm,
				
				signalOut => ExtenderImm_out
			);


RegFile : entity work.RegFile
			port map (
				clk => CLK,
				clear => '0',
				we => weReg,
				rs1 => MuxBubbleOut(19 downto 15),
				rs2 => MuxBubbleOut(24 downto 20),
				rd => MuxBubbleOut(11 downto 7),
				data_in => MuxALUPc4RAM_out,
				
				d_rs1 => d_rs1,
				d_rs2 => d_rs2
			);
			
			
 MuxALUPc4RAM : entity work.genericMux3x1
    generic map ( dataWidth => 32 )
    port map (
        inputA_MUX => ALU_out,
        inputB_MUX => PC4,
        inputC_MUX => extenderRAM_out,
        selector_MUX => selMuxALUPc4RAM,
        output_MUX => MuxALUPc4RAM_out
    );
			
Adder_PC40 : entity work.genericAdder
    generic map ( dataWidth => 32 )
    port map (
        inputA => PC_out0,
        inputB => "00000000000000000000000000000100",
        output => PC40
    );
	 
PC4Reg : entity work.genericRegister
			generic map ( data_width => 32 )
			port map (
				clock => CLK,
				clear => SW(0),
				enable => '1',
				source => PC40,
				destination => PC4
			);
	 
Adder_ImmPC : entity work.genericAdderU
    generic map ( dataWidth => 32 )
    port map (
        inputA => ExtenderImm_out,
        inputB => PC_out,
        output => addImmPC_out
    );

ALU : entity work.ALU
			port map(
				op => opALU,
				dA => MuxPCRS1_out,
				dB => MuxRS2Imm_out,
				
				dataOut => ALU_out,
				branch => branch_flag
			);
			
			
MuxPCRS1 : entity work.genericMux2x1
    generic map ( dataWidth => 32 )
    port map (
        inputA_MUX => PC_out,
        inputB_MUX => d_rs1,
        selector_MUX => selMuxPCRS1,
        output_MUX => MuxPCRS1_out
    );		 

	 
MuxRS2Imm : entity work.genericMux2x1
    generic map ( dataWidth => 32 )
    port map (
        inputA_MUX => d_rs2,
        inputB_MUX => ExtenderImm_out,
        selector_MUX => selMuxRS2Imm,
        output_MUX => MuxRS2Imm_out
    );
	 
	 
StoreManager : entity work.StoreManager
			port map(
				opcode => MuxBubbleOut(6 downto 0),
				funct3 => MuxBubbleOut(14 downto 12),
				EA => ALU_out(1 downto 0),
				rs2Val => d_rs2,
				data_out => out_StoreManager,
				mask => mask
			);
			

RAM : entity work.RAM
			port map(
				clk => CLK,
				addr => ALU_out(31 downto 2), -- word addressable (alu out ´e byte, entao ignora os dois bits menos significativos)
				data_in => out_StoreManager,
				data_out => RAM_out,
				weRAM => weRAM,
				reRAM => reRAM,
				eRAM => eRAM and (not(ALU_out(31))),
				mask => mask
			);
			
enable_led <= '1'
  when (eRAM = '1' and weRAM = '1' and
        unsigned(ALU_out(31 downto 2)) = to_unsigned(1024, 30))
  else '0';
			
leds : entity work.genericRegister
			generic map ( data_width => 8 )
			port map (
				clock => CLK,
				clear => SW(0),
				enable => enable_led,
				source => out_StoreManager(7 downto 0),
				destination => LEDR(7 downto 0)
			);

  -- Se for leitura de GPIO (MMIO), pega do GPIO; senão, da RAM
bus_rdata_preext <= gpio_data_out when (sel_gpio='1' and reRAM='1' and eRAM='1') else RAM_out;

ExtenderRAM : entity work.ExtenderRAM
  port map(
    signalIn  => bus_rdata_preext,
    opExRAM   => opExRAM,
    EA        => ALU_out(1 downto 0),
    signalOut => extenderRAM_out
  );

			
selMuxPc4ALU_ext <= branch_flag & selMuxPc4ALU; 	

MuxPc4ALU : entity work.genericMux3x1
    generic map ( dataWidth => 32 )
    port map (
        inputA_MUX => PC40,
        inputB_MUX => ALU_out,
        inputC_MUX => addImmPC_out,
        selector_MUX => selMuxPc4ALU_ext,
        output_MUX => MuxPc4ALU_out
    );
					  

					  
--DecoderDisplay0 :  entity work.conversorHex7Seg
--        port map(dadoHex => PC_out(5 downto 2),
--                 saida7seg => HEX0);
--
--DecoderDisplay1 :  entity work.conversorHex7Seg
--		  port map(dadoHex => MuxBubbleOut(3 downto 0),
--					  saida7seg => HEX1);
--				
--DecoderDisplay2 :  entity work.conversorHex7Seg
--		  port map(dadoHex => MuxBubbleOut(7 downto 4),
--					  saida7seg => HEX2);
--					  
--DecoderDisplay3 :  entity work.conversorHex7Seg
--		  port map(dadoHex => MuxBubbleOut(11 downto 8),
--					  saida7seg => HEX3);
--					  
--DecoderDisplay4 :  entity work.conversorHex7Seg
--		  port map(dadoHex => MuxBubbleOut(15 downto 12),
--					  saida7seg => HEX4);
--					  
--DecoderDisplay5 :  entity work.conversorHex7Seg
--		  port map(dadoHex => MuxBubbleOut(19 downto 16),
--					  saida7seg => HEX5);

DecoderDisplay0 :  entity work.conversorHex7Seg
        port map(dadoHex => PC_out(3 downto 0),
                 saida7seg => HEX0);

DecoderDisplay1 :  entity work.conversorHex7Seg
		  port map(dadoHex => PC_out(7 downto 4),
					  saida7seg => HEX1);
				
DecoderDisplay2 :  entity work.conversorHex7Seg
		  port map(dadoHex => ALU_out(3 downto 0),
					  saida7seg => HEX2);
					  
DecoderDisplay3 :  entity work.conversorHex7Seg
		  port map(dadoHex => ALU_out(7 downto 4),
					  saida7seg => HEX3);
					  
DecoderDisplay4 :  entity work.conversorHex7Seg
		  port map(dadoHex => ALU_out(11 downto 8),
					  saida7seg => HEX4);
					  
DecoderDisplay5 :  entity work.conversorHex7Seg
		  port map(dadoHex => ALU_out(15 downto 12),
					  saida7seg => HEX5);
					  
u_gpio : entity work.GPIO
 generic map (
	DATA_WIDTH => 32
 )
 port map (
	clock     => CLK,                 -- teu clock interno
	clear     => not FPGA_RESET_N,    -- reset ativo alto interno (ajuste se precisar)
	data_in   => out_StoreManager,    -- dados de escrita vindos do StoreManager
	address   => gpio_addr_nibble,    -- 4 bits (palavra)
	write     => gpio_write_en,
	read      => gpio_read_en,
	data_out  => gpio_data_out,       -- volta dado de leitura do GPIO
	irq       => open,                -- liga aqui se/qd usar interrupção
	gpio_pins => GPIO_P               -- pinos físicos
 );



--example_blinky : entity work.Blinky
--			port map (
--				clk => CLOCK_50,      
--				led => LEDR(0)    );

end architecture;