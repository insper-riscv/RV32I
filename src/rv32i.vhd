library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_consts.all;

entity rv32i is
  generic (
	  SIMULATION : boolean := FALSE; -- SIMULATION = TRUE para fazer testes no cocotb, FLASE para fazer a sintese na placa física.
	  ROM_FILE : string := "default.hex" -- ROM_FILE é o programa que vai carregar a ROM quando SIMULATION = TRUE
  );
  port   (
    --CLOCK_50 : in std_logic;
	 CLK : in std_logic
	 --HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);
	 --LEDR : out std_logic_vector(9 downto 0);
	 --FPGA_RESET_N : in std_logic
  );
end entity;

architecture behaviour of rv32i is

  -- add necessary signals here
  --signal CLK : std_logic;
  
  signal MuxPc4ALU_out : std_logic_vector(31 downto 0);
  signal PC_out : std_logic_vector(31 downto 0);
  
  signal ROM_out : std_logic_vector(31 downto 0);
  
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
  signal PC4 : std_logic_vector(31 downto 0);
  signal addImmPC_out : std_logic_vector(31 downto 0);
  signal extenderRAM_out : std_logic_vector(31 downto 0);
  
  -- Created with ALU
  signal MuxPCRS1_out : std_logic_vector(31 downto 0);
  signal MuxRS2Imm_out : std_logic_vector(31 downto 0);
  signal branch_flag : std_logic;
  
  signal RAM_out : std_logic_vector(31 downto 0);
  
  signal selMuxPc4ALU_ext : std_logic_vector(1 downto 0);

  signal addr_word : std_logic_vector(31 downto 0);
  
  

begin

--edgeDetectorKey : entity work.edgeDetector
--			port map (clk => CLOCK_50, entrada => NOT(FPGA_RESET_N), saida => CLK);
			
			
	PC : entity work.genericRegister
		generic map ( data_width => 32 )
		port map (
			clock => CLK,
			clear => '0',
			enable => '1',
			source => MuxPc4ALU_out,
			
			destination => PC_out
	);

	-- rom_choice : if SIMULATION generate
	-- ROM : entity work.ROM_simulation
	-- 	generic map (ROM_FILE => ROM_FILE)   -- repassa o generic do top para a ROM
	-- 	port map (
	-- 		addr => PC_out,
	-- 		data => ROM_out
	-- 	);
	-- end generate rom_choice;

	-- rom_choice_synth : if not SIMULATION generate
	-- ROM : entity work.ROM_simulation
	-- 	generic map (ROM_FILE => ROM_FILE)   -- repassa o generic do top para a ROM
	-- 	port map (
	-- 		addr => PC_out,
	-- 		data => ROM_out
	-- 	);
	-- end generate rom_choice_synth;

	addr_word <= "00" & PC_out(31 downto 2);


	ROM : entity work.ROM_simulation
		generic map (ROM_FILE => ROM_FILE)   -- repassa o generic do top para a ROM
		port map (
			addr => addr_word,
			data => ROM_out
		);

	InstructionDecoder : entity work.InstructionDecoder
				port map (
					opcode => ROM_out(6 downto 0),
					funct3 => ROM_out(14 downto 12),
					funct7 => ROM_out(31 downto 25),
					
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
					Inst31downto7 => ROM_out(31 downto 7),
					opExImm => opExImm,
					
					signalOut => ExtenderImm_out
				);


	RegFile : entity work.RegFile
				port map (
					clk => CLK,
					clear => '0',
					we => weReg,
					rs1 => ROM_out(19 downto 15),
					rs2 => ROM_out(24 downto 20),
					rd => ROM_out(11 downto 7),
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
				
	Adder_PC4 : entity work.genericAdder
		generic map ( dataWidth => 32 )
		port map (
			inputA => PC_out,
			inputB => "00000000000000000000000000000100",
			output => PC4
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
					opcode => ROM_out(6 downto 0),
					funct3 => ROM_out(14 downto 12),
					EA => ALU_out(1 downto 0),
					rs2Val => d_rs2,
					data_out => out_StoreManager,
					mask => mask
				);
				

	RAM : entity work.RAM
				port map(
					clk => CLK,
					addr => ALU_out(31 downto 2),
					data_in => out_StoreManager,
					data_out => RAM_out,
					weRAM => weRAM,
					reRAM => reRAM,
					eRAM => eRAM,
					mask => mask
				);

	ExtenderRAM : entity work.ExtenderRAM
				port map(
					signalIn => RAM_out,
					opExRAM => opExRAM,
					EA => ALU_out(1 downto 0),
					signalOut => extenderRAM_out
				);
				
	selMuxPc4ALU_ext <= branch_flag & selMuxPc4ALU; 	

	MuxPc4ALU : entity work.genericMux3x1
		generic map ( dataWidth => 32 )
		port map (
			inputA_MUX => PC4,
			inputB_MUX => ALU_out,
			inputC_MUX => addImmPC_out,
			selector_MUX => selMuxPc4ALU_ext,
			output_MUX => MuxPc4ALU_out
		);
						

						
	--DecoderDisplay0 :  entity work.conversorHex7Seg
	--        port map(dadoHex => PC_out(3 downto 0),
	--                 saida7seg => HEX0);

	--DecoderDisplay1 :  entity work.conversorHex7Seg
	--		  port map(dadoHex => PC_out(7 downto 4),
	--					  saida7seg => HEX1);
					
	--DecoderDisplay2 :  entity work.conversorHex7Seg
	--		  port map(dadoHex => ALU_out(3 downto 0),
	--					  saida7seg => HEX2);
						
	--DecoderDisplay3 :  entity work.conversorHex7Seg
	--		  port map(dadoHex => ALU_out(7 downto 4),
	--					  saida7seg => HEX3);
						
	--DecoderDisplay4 :  entity work.conversorHex7Seg
	--		  port map(dadoHex => ALU_out(11 downto 8),
	--					  saida7seg => HEX4);
						
	--DecoderDisplay5 :  entity work.conversorHex7Seg
	--		  port map(dadoHex => ALU_out(15 downto 12),
	--					  saida7seg => HEX5);


	--example_blinky : entity work.Blinky
	--			port map (
	--				clk => CLOCK_50,      
	--				led => LEDR(0)    );

end architecture;