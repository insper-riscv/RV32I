library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_consts.all;

-- L2IP

entity rv32i3stage is
	generic (
	  SIMULATION : boolean := FALSE; 
	  ROM_FILE : string := "default.hex" 
  );
  port   (
    CLK : in std_logic
  );
end entity;

architecture behaviour of rv32i3stage is

  -- add necessary signals here
  
  signal MuxPc4ALU_out : std_logic_vector(31 downto 0);
  signal PC_ID_out : std_logic_vector(31 downto 0);
  signal PC_IF_out : std_logic_vector(31 downto 0);
  
  signal ROM_out : std_logic_vector(31 downto 0);
  
  signal rd_WB_out : std_logic_vector(4 downto 0);
  
  signal selMuxPc4ALU : std_logic;
  signal opExImm : std_logic_vector(2 downto 0);
  signal selMuxALUPc4RAM_IDEXMEM, selMuxALUPc4RAM_WB_out : std_logic_vector(1 downto 0);
  signal weReg_IDEXMEM, weReg_WB_out : std_logic;
  signal opExRAM_IFEXMEM,  opExRAM_WB_out: std_logic_vector(2 downto 0);
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
  
  signal ALU_out_IDEXMEM, ALU_out_WB_out : std_logic_vector(31 downto 0);
  signal PC4_IF : std_logic_vector(31 downto 0);
  signal PC4_ID_out, PC4_WB_out : std_logic_vector(31 downto 0);
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
  
  signal CLK_IF, CLK_IDEXMEM, CLK_WB : std_logic;
 
  
  

begin

--edgeDetectorKey : entity work.edgeDetector
--    port map (
--        clk    => CLOCK_50 and (not '0'),
--        entrada=> not FPGA_RESET_N,
--        saida  => CLKbtn
--    );


clk_gen : entity work.clk_gen_3way
    port map (
        clk_in    => CLK,
        reset=> '0',
		clk0 => CLK_IF,
		clk1 => CLK_IDEXMEM,
		clk2 => CLK_WB
    );


PC_IF : entity work.genericRegister
			generic map ( data_width => 32 )
			port map (
				clock => CLK_IDEXMEM,
				clear => '0',
				enable => '1',
				source => MuxPc4ALU_out,
				destination => PC_IF_out
			);
			
PC_ID : entity work.genericRegister
			generic map ( data_width => 32 )
			port map (
				clock => CLK_IF,
				clear => '0',
				enable => '1',
				source => PC_IF_out,
				destination => PC_ID_out
			);

ROM : entity work.ROM_simulation
		generic map (ROM_FILE => ROM_FILE)  
		port map (
			addr => PC_IF_out(31 downto 2),
			clk => CLK_IF,
			re => '1',
			data => ROM_out
		);
			
InstructionDecoder : entity work.InstructionDecoder
			port map (
				opcode => ROM_out(6 downto 0),
				funct3 => ROM_out(14 downto 12),
				funct7 => ROM_out(31 downto 25),
				
				selMuxPc4ALU => selMuxPc4ALU,
				opExImm => opExImm,
				selMuxALUPc4RAM => selMuxALUPc4RAM_IDEXMEM,
				weReg => weReg_IDEXMEM,
				opExRAM => opExRAM_IFEXMEM,
				selMuxRS2Imm => selMuxRS2Imm,
				selPCRS1 => selMuxPCRS1,
				opALU => opALU,
				weRAM => weRAM,
				reRAM => reRAM,
				eRAM => eRAM
			);
			
OpExRAM_WB : entity work.genericRegister
			generic map ( data_width => 3 )
			port map (
				clock => CLK_IDEXMEM,
				clear => '0',
				enable => '1',
				source => opExRAM_IFEXMEM,
				destination => opExRAM_WB_out 
			);
			
rd_WB : entity work.genericRegister
			generic map ( data_width => 5 )
			port map (
				clock => CLK_IDEXMEM,
				clear => '0',
				enable => '1',
				source => ROM_out(11 downto 7),
				destination =>  rd_WB_out
			);
			
weReg_WB : entity work.FlipFlop
			port map (
				clock => CLK,
				clear => '0',
				enable => '1',
				source => weReg_IDEXMEM,
				destination => weReg_WB_out
			);
			
SelMux_WB : entity work.genericRegister
			generic map ( data_width => 2 )
			port map (
				clock => CLK_IDEXMEM ,
				clear => '0',
				enable => '1',
				source => selMuxALUPc4RAM_IDEXMEM,
				destination => selMuxALUPc4RAM_WB_out 
			);
			
ExtenderImm : entity work.ExtenderImm
			port map (
				Inst31downto7 => ROM_out(31 downto 7),
				opExImm => opExImm,
				
				signalOut => ExtenderImm_out
			);


RegFile : entity work.RegFile
			port map (
				clk => CLK_WB,
				clear => '0',
				we => weReg_WB_out,
				rs1 => ROM_out(19 downto 15),
				rs2 => ROM_out(24 downto 20),
				rd => rd_WB_out,
				data_in => MuxALUPc4RAM_out,
				d_rs1 => d_rs1,
				d_rs2 => d_rs2
			);
			
PC4_WB : entity work.genericRegister
			generic map ( data_width => 32 )
			port map (
				clock => CLK_IF,
				clear => '0',
				enable => '1',
				source => PC4_ID_out,
				destination => PC4_WB_out
			);
			
ALU_out_WB : entity work.genericRegister
			generic map ( data_width => 32 )
			port map (
				clock => CLK_IDEXMEM,
				clear => '0',
				enable => '1',
				source => ALU_out_IDEXMEM,
				destination => ALU_out_WB_out
			);
			
			
 MuxWB : entity work.genericMux3x1
    generic map ( dataWidth => 32 )
    port map (
        inputA_MUX => ALU_out_WB_out,
        inputB_MUX => PC4_WB_out,
        inputC_MUX => extenderRAM_out,
        selector_MUX => selMuxALUPc4RAM_WB_out,
        output_MUX => MuxALUPc4RAM_out
    );
			
Adder_PC4_IF : entity work.genericAdder
    generic map ( dataWidth => 32 )
    port map (
        inputA => PC_IF_out,
        inputB => "00000000000000000000000000000100",
        output => PC4_IF
    );
	 
PC4_ID : entity work.genericRegister
			generic map ( data_width => 32 )
			port map (
				clock => CLK_IF,
				clear => '0',
				enable => '1',
				source => PC4_IF,
				destination => PC4_ID_out
			);
	 
Adder_ImmPC : entity work.genericAdderU
    generic map ( dataWidth => 32 )
    port map (
        inputA => ExtenderImm_out,
        inputB => PC_ID_out,
        output => addImmPC_out
    );

ALU : entity work.ALU
			port map(
				op => opALU,
				dA => MuxPCRS1_out,
				dB => MuxRS2Imm_out,
				dataOut => ALU_out_IDEXMEM,
				branch => branch_flag
			);
			
			
MuxPCRS1 : entity work.genericMux2x1
    generic map ( dataWidth => 32 )
    port map (
        inputA_MUX => PC_ID_out,
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
				opcode => ROM_out(6 downto 0),
				funct3 => ROM_out(14 downto 12),
				EA => ALU_out_IDEXMEM(1 downto 0),
				rs2Val => d_rs2,
				data_out => out_StoreManager,
				mask => mask
			);
			

RAM : entity work.RAM_sim
			port map(
				addr => ALU_out_IDEXMEM(31 downto 2), -- word addressable (alu out ´e byte, entao ignora os dois bits menos significativos)
				mask => mask,
				clk => CLK_IDEXMEM,
				data_in => out_StoreManager,
				reRAM => reRAM and eRAM,
				weRAM => weRAM and eRAM,
				eRAM => '1',
				data_out => RAM_out
			);


ExtenderRAM : entity work.ExtenderRAM
			port map(
				signalIn => RAM_out, 
				opExRAM => opExRAM_WB_out,
				EA => ALU_out_WB_out(1 downto 0),
				signalOut => extenderRAM_out
			);
			
selMuxPc4ALU_ext <= branch_flag & selMuxPc4ALU; 	

MuxPc4ALU : entity work.genericMux3x1
    generic map ( dataWidth => 32 )
    port map (
        inputA_MUX => PC4_IF,
        inputB_MUX => ALU_out_IDEXMEM ,
        inputC_MUX => addImmPC_out,
        selector_MUX => selMuxPc4ALU_ext,
        output_MUX => MuxPc4ALU_out
    );
					  

--	DecoderDisplay0 :  entity work.conversorHex7Seg
--	        port map(dadoHex => PC_out(3 downto 0),
--	                 saida7seg => HEX0);

--	DecoderDisplay1 :  entity work.conversorHex7Seg
--			  port map(dadoHex => PC_out(7 downto 4),
--						  saida7seg => HEX1);
				
--	DecoderDisplay2 :  entity work.conversorHex7Seg
--			  port map(dadoHex => ALU_out_IDEXMEM(3 downto 0),
--						  saida7seg => HEX2);
					  
--	DecoderDisplay3 :  entity work.conversorHex7Seg
--			  port map(dadoHex => ALU_out_IDEXMEM(7 downto 4),
--						  saida7seg => HEX3);
					  
--	DecoderDisplay4 :  entity work.conversorHex7Seg
--			  port map(dadoHex => ALU_out_IDEXMEM(11 downto 8),
--						  saida7seg => HEX4);
					  
--	DecoderDisplay5 :  entity work.conversorHex7Seg
--			  port map(dadoHex => ALU_out_IDEXMEM(15 downto 12),
--						  saida7seg => HEX5);


--example_blinky : entity work.Blinky
--			port map (
--				clk => CLOCK_50,      
--				led => LEDR(0)    );

end architecture;