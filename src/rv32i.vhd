library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32i_ctrl_consts.all;

entity rv32i is
  generic ( 
    simulacao : boolean := TRUE -- To test in FPGA, set to FALSE
  );

  port   (
    CLOCK_50 : in std_logic;
	 HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);
	 LEDR : out std_logic_vector(9 downto 0);
	 FPGA_RESET_N : in std_logic
  );
end entity;

architecture behaviour of rv32i is

  -- add necessary signals here
  signal CLK : std_logic;
  
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
  signal weRAM : std_logic;
  
  signal ExtenderImm_out : std_logic_vector(31 downto 0);
  
  signal MuxALUPc4RAM_out : std_logic_vector(31 downto 0);
  signal d_rs1 : std_logic_vector(31 downto 0);
  signal d_rs2 : std_logic_vector(31 downto 0);
  
  signal ALU_out : std_logic_vector(31 downto 0);
  signal PC4 : std_logic_vector(31 downto 0);
  signal extenderRAM_out : std_logic_vector(31 downto 0);
  
  -- Created with ALU
  signal MuxPCRS1_out : std_logic_vector(31 downto 0);
  signal MuxRS2Imm_out : std_logic_vector(31 downto 0);
  signal branch_flag : std_logic;
  
  signal RAM_out : std_logic_vector(31 downto 0);
  
  

begin

edgeDetectorKey : entity work.edgeDetector
			port map (clk => CLOCK_50, entrada => NOT(FPGA_RESET_N), saida => CLK);
			
			
PC : entity work.genericRegister
			generic map ( data_width => 32 )
			port map (
				clock => CLK,
				clear => '0',
				enable => '1',
				source => MuxPc4ALU_out,
				
				destination => PC_out
			);
			
ROM : entity work.ROM
			port map (
				addr => PC_out,
				
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
				mask => mask,
				weRAM => weRAM
			);
			
ExtenderImm : entity work.ExtenderImm
			port map (
				signalIn => ROM_out(31 downto 7),
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
MuxALUPc4RAM_out <= ALU_out         when SelMuxALUPc4RAM = "00" else
                    PC4             when SelMuxALUPc4RAM = "01" else
                    extenderRAM_out when SelMuxALUPc4RAM = "10" else
                    (others => '0');
			
PC4 <= std_logic_vector(unsigned(PC_out) + 4);

ALU : entity work.ALU
			port map(
				op => opALU,
				dA => MuxPCRS1_out,
				dB => MuxRS2Imm_out,
				
				dataOut => ALU_out,
				branch => branch_flag
			);
MuxPCRS1_out <= PC_out   when selMuxPCRS1 = '0' else
                d_rs1    when	selMuxPCRS1	= '1' else	
		          (others => '0');			 

MuxRS2Imm_out <= d_rs2           when selMuxRS2Imm = '0' else
                 ExtenderImm_out when selMuxRS2Imm = '1' else
					  (others => '0');
					  
RAM : entity work.RAM
			port map(
				clk => CLK,
				addr => ALU_out,
				data_in => d_rs2,
				we => weRAM,
				mask => mask,
				
				data_out => RAM_out
			);

ExtenderRAM : entity work.ExtenderRAM
			port map(
				signalIn => RAM_out,
				opExRAM => opExImm,
				
				signalOut => extenderRAM_out
			);
			
MuxPc4ALU_out <= PC4                                                             when ( std_logic_vector'(branch_flag & selMuxPc4ALU) = "00" ) else
					  ALU_out                                                         when ( std_logic_vector'(branch_flag & selMuxPc4ALU) = "01" ) else
					  std_logic_vector(unsigned(ExtenderImm_out) + unsigned(PC_out))  when ( std_logic_vector'(branch_flag & selMuxPc4ALU) = "10" ) else
					  (others => '0');
					  

					  
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


example_blinky : entity work.Blinky
			port map (
				clk => CLOCK_50,      
				led => LEDR(0)    
			);
end architecture;