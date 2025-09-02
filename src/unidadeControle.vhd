library ieee;
use ieee.std_logic_1164.all;

entity unidadeControle is
  port (
    opcode  : in  std_logic_vector(6 downto 0);
    funct3  : in  std_logic_vector(2 downto 0);
    funct7  : in  std_logic_vector(6 downto 0);
    saida   : out std_logic_vector(13 downto 0)
  );
end entity;

architecture comportamento of unidadeControle is
  -- opcodes
  constant LUI      : std_logic_vector(6 downto 0) := "0110111";
  constant AUIPC    : std_logic_vector(6 downto 0) := "0010111";
  constant JAL      : std_logic_vector(6 downto 0) := "1101111";
  constant JALR     : std_logic_vector(6 downto 0) := "1100111";
  constant B_type   : std_logic_vector(6 downto 0) := "1100011";
  constant L_type   : std_logic_vector(6 downto 0) := "0000011";
  constant S_type   : std_logic_vector(6 downto 0) := "0100011";
  constant I_type   : std_logic_vector(6 downto 0) := "0010011";
  constant R_type   : std_logic_vector(6 downto 0) := "0110011";

  -- sinais de saida
  signal RegWrite   : std_logic;
  signal ResultSrc  : std_logic_vector(1 downto 0);
  signal MemWrite   : std_logic;
  signal ALUControl : std_logic_vector(3 downto 0);
  signal ALUSrc     : std_logic;
  signal ImmSrc     : std_logic_vector(2 downto 0);
  signal Branch     : std_logic;
  signal Jump       : std_logic;
  signal ALUOp      : std_logic_vector(1 downto 0);

begin

	process(opcode)
	begin
		case opcode is
			when L_type =>
			  RegWrite   <= '1';  ResultSrc <= "01"; MemWrite <= '0';
			  ALUSrc     <= '1';  ImmSrc    <= "000"; Branch   <= '0'; Jump <= '0';
			  ALUOp      <= "00";

			when S_type =>
			  RegWrite   <= '0';  ResultSrc <= "00"; MemWrite <= '1';
			  ALUSrc     <= '1';  ImmSrc    <= "001"; Branch   <= '0'; Jump <= '0';
			  ALUOp      <= "00";

			when B_type =>
			  RegWrite   <= '0';  ResultSrc <= "00"; MemWrite <= '0';
			  ALUSrc     <= '0';  ImmSrc    <= "010"; Branch   <= '1'; Jump <= '0';
			  ALUOp      <= "01";

			when I_type =>
			  RegWrite   <= '1';  ResultSrc <= "00"; MemWrite <= '0';
			  ALUSrc     <= '1';  ImmSrc    <= "000"; Branch   <= '0'; Jump <= '0';
			  ALUOp      <= "10";

			when R_type =>
			  RegWrite   <= '1';  ResultSrc <= "00"; MemWrite <= '0';
			  ALUSrc     <= '0';  ImmSrc    <= "000"; Branch   <= '0'; Jump <= '0';
			  ALUOp      <= "10";

			when LUI | AUIPC =>
			  RegWrite   <= '1';  ResultSrc <= "00"; MemWrite <= '0';
			  ALUSrc     <= '1';  ImmSrc    <= "011"; Branch   <= '0'; Jump <= '0';
			  ALUOp      <= "00";

			when JAL | JALR =>
			  RegWrite   <= '1';  ResultSrc <= "10"; MemWrite <= '0';
			  ALUSrc     <= '1';  ImmSrc    <= "100"; Branch   <= '0'; Jump <= '1';
			  ALUOp      <= "00";

			when others =>
			  RegWrite   <= '0';  ResultSrc <= "00"; MemWrite <= '0';
			  ALUSrc     <= '0';  ImmSrc    <= "000"; Branch   <= '0'; Jump <= '0';
			  ALUOp      <= "00";
		 end case;
	end process;

	process(ALUOp, funct3, funct7)
		begin
			case ALUOp is
				when "00" => ALUControl <= "0000"; -- ADD (nao tipoR)
				when "01" => ALUControl <= "0001"; -- SUB tipo B
				when "10" =>
					case funct3 is
						when "000" =>
							if funct7(5) = '1' then
								ALUControl <= "0001"; -- SUB
							else
								ALUControl <= "0000"; -- ADD
							end if;
						when "111" => ALUControl <= "0010"; -- AND/ANDI
						when "110" => ALUControl <= "0011"; -- OR/ORI
						when "100" => ALUControl <= "0100"; -- XOR/XORI
						when "010" => ALUControl <= "0101"; -- SLT/SLTI
						when "011" => ALUControl <= "0110"; -- SLTU/SLTIU
						when "001" => ALUControl <= "1000"; -- SLL/SLLI
						when "101" =>                       -- SRL/SRA / SRLI/SRAI
							if funct7(5)='1' then 
								ALUControl <="1010"; -- SRA/SRAI
							else 
								ALUControl <="1001"; -- SRL/SRLI
							end if;
						when others => ALUControl <= "0000";
					end case;
				when others => ALUControl <= "0000";
			end case;
	end process;

   saida <= RegWrite & ResultSrc & MemWrite & ALUControl & ALUSrc & ImmSrc & Branch & Jump;

end architecture;
