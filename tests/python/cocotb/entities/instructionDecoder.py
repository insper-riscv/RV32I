import csv
from pathlib import Path
import cocotb
from cocotb.triggers import Timer


# ===== Helpers =====
def _parse_field(val: str, width: int) -> int:
    """
    Converte campo da tabela para inteiro.
    - '-' ou 'X...' → 0
    - Símbolos → conforme mapeamento (opExImm, opExRAM, opALU)
    - Senão → interpretado como binário
    """
    val = val.strip()
    if val == "-" or all(ch == "X" for ch in val):
        return 0

    symbol_map = {
        # opExImm[2:0]
        "U":       0b000,
        "I":       0b001,
        "I_shamt": 0b010,
        "JAL":     0b011,
        "JALR":    0b100,
        "S":       0b101,
        "BRANCH":  0b110,

        # opExRAM[2:0]
        "LW":  0b000,
        "LH":  0b001,
        "LHU": 0b010,
        "LB":  0b011,
        "LBU": 0b100,

        # opALU[4:0]
        "PASS_B": 0b00000,
        "ADD":    0b00001,
        "XOR":    0b00010,
        "OR":     0b00011,
        "AND":    0b00100,
        "SLL":    0b00101,
        "SRL":    0b00110,
        "SRA":    0b00111,
        "SUB":    0b01000,
        "SLT":    0b01001,
        "SLTU":   0b01010,
        "BEQ":    0b01011,
        "BNE":    0b01100,
        "BLT":    0b01101,
        "BGE":    0b01110,
        "BLTU":   0b01111,
        "BGEU":   0b10000,
    }

    if val in symbol_map:
        return symbol_map[val]

    return int(val, 2)


def load_reference():
    """Carrega a tabela CSV de opcodes."""
    data_dir = Path(__file__).resolve().parent / "data"
    csv_path = data_dir / "riscv_opcodes.csv"
    with open(csv_path, newline="") as f:
        return list(csv.DictReader(f))


# ===== Teste =====
@cocotb.test()
async def test_instruction_decoder(dut):
    """
    Para cada linha da tabela CSV:
    - aplica opcode/funct3/funct7
    - espera propagação
    - compara todos os sinais de saída com a tabela
    """
    ref_table = load_reference()

    for row in ref_table:
        inst = row["INST"]

        # === aplica entradas ===
        dut.opcode.value = _parse_field(row["OpCode[6:0]"], 7)
        dut.funct3.value = _parse_field(row["funct3[2:0]"], 3)
        dut.funct7.value = _parse_field(row["funct7[6:0]"], 7)

        await Timer(1, units="ns")

        # === lê saídas do DUT ===
        got_fields = {
            "SelMuxPc4ALU":         int(dut.selMuxPc4ALU.value),
            "opExImm[2:0]":         int(dut.opExImm.value),
            "selMuxALUPc4RAM[1:0]": int(dut.selMuxALUPc4RAM.value),
            "weReg":                int(dut.weReg.value),
            "opExRAM[2:0]":         int(dut.opExRAM.value),
            "selMuxRS2Imm":         int(dut.selMuxRS2Imm.value),
            "selMUXPcRS1":          int(dut.selPCRS1.value),
            "opALU[4:0]":           int(dut.opALU.value),
            "reRAM":                int(dut.reRAM.value),
            "eRAM":                 int(dut.eRAM.value),
            "weRAM":                int(dut.weRAM.value),
        }

        # === compara campo a campo ===
        for key, got in got_fields.items():
            exp_raw = row[key].strip()
            expected = _parse_field(exp_raw, len(exp_raw))

            assert got == expected, (
                f"{inst}: {key} esperado {exp_raw}({expected}), obtido {got}"
            )

        dut._log.info(
            f"{inst} OK "
            f"(selMuxPc4ALU={got_fields['SelMuxPc4ALU']} "
            f"opExImm={got_fields['opExImm[2:0]']:03b} "
            f"opALU={got_fields['opALU[4:0]']:05b})"
        )
