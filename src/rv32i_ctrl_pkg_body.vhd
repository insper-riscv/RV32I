library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
package body rv32i_ctrl_pkg is
  pure function alu_slv_to_enum(slv : alu_slv_t) return alu_op_t is
  begin
    case slv is
      when ALU_SLV_ADD     => return ALU_ADD;
      when ALU_SLV_SUB     => return ALU_SUB;
      when ALU_SLV_AND     => return ALU_AND;
      when ALU_SLV_OR      => return ALU_OR;
      when ALU_SLV_XOR     => return ALU_XOR;
      when ALU_SLV_SLT     => return ALU_SLT;
      when ALU_SLV_SLTU    => return ALU_SLTU;
      when ALU_SLV_SLL     => return ALU_SLL;
      when ALU_SLV_SRL     => return ALU_SRL;
      when ALU_SLV_SRA     => return ALU_SRA;
      when ALU_SLV_PASS_A  => return ALU_PASS_A;
      when ALU_SLV_PASS_B  => return ALU_PASS_B;
      when others          => return ALU_ILLEGAL;
    end case;
  end function;
end package body;