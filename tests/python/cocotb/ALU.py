
import re
import random
from pathlib import Path

import cocotb
from cocotb.triggers import Timer

MASK32 = 0xFFFFFFFF

def u32(x: int) -> int:
    return x & MASK32

def s32(x: int) -> int:
    x &= MASK32
    return x if x < 0x8000_0000 else x - 0x1_0000_0000

def sll32(a, b):
    sh = b & 0x1F
    return u32(u32(a) << sh)

def srl32(a, b):
    sh = b & 0x1F
    return (u32(a) >> sh) & MASK32

def sra32(a, b):
    sh = b & 0x1F
    return u32(s32(a) >> sh)

def _parse_alu_enum_from_pkg(vhd_text: str) -> dict:
    vhd_text = re.sub(r"--.*?$", "", vhd_text, flags=re.M)  # strip line comments
    m = re.search(r"type\s+alu_op_t\s+is\s*\((.*?)\)\s*;", vhd_text, flags=re.S|re.I)
    if not m:
        raise RuntimeError("Não encontrei 'type alu_op_t is (...)' em rv32i_ctrl_pkg.vhd")
    inside = m.group(1)
    names = [n.strip() for n in re.split(r",", inside) if n.strip()]
    return {name: idx for idx, name in enumerate(names)}

def _load_opcodes():
    # tests/python/cocotb/ALU.py -> repo_root
    repo_root = Path(__file__).resolve().parents[3]
    pkg_path = repo_root / "src" / "rv32i_ctrl_pkg.vhd"
    txt = pkg_path.read_text(encoding="utf-8", errors="ignore")
    mapping = _parse_alu_enum_from_pkg(txt)
    # sanity de chaves requeridas
    required = [
        "ALU_ADD","ALU_SUB","ALU_AND","ALU_OR","ALU_XOR",
        "ALU_SLT","ALU_SLTU","ALU_SLL","ALU_SRL","ALU_SRA",
        "ALU_PASS_A","ALU_PASS_B","ALU_ILLEGAL"
    ]
    missing = [k for k in required if k not in mapping]
    if missing:
        raise RuntimeError(f"Literals ausentes no alu_op_t: {missing}")
    return mapping

OPCODES = None

async def drive_and_read(dut, op_name: str, a: int, b: int) -> int:
    global OPCODES
    if OPCODES is None:
        OPCODES = _load_opcodes()

    # inicializa para evitar warnings de metavalue no 0 ns
    dut.dA.value = 0
    dut.dB.value = 0
    dut.op.value = int(OPCODES[op_name])
    await Timer(1, units="ns")

    dut.dA.value = u32(a)
    dut.dB.value = u32(b)
    await Timer(1, units="ns")  # ALU combinacional

    return dut.destination.value.integer

@cocotb.test()
async def sanity_opcodes_from_pkg(dut):
    global OPCODES
    OPCODES = _load_opcodes()
    assert len(set(OPCODES.values())) == len(OPCODES), "Códigos duplicados no alu_op_t?"

@cocotb.test()
async def test_add_sub(dut):
    vectors = [
        (0, 0),
        (1, 1),
        (0x7FFFFFFF, 1),
        (0xFFFFFFFF, 1),
        (0x80000000, 0x80000000),
        (0x01234567, 0x89ABCDEF),
        (-1, -1),
        (-123456, 789),
    ]
    for a, b in vectors:
        got = await drive_and_read(dut, "ALU_ADD", a, b)
        exp = u32(a + b)
        assert got == exp, f"ADD {a:#x}+{b:#x}: got={got:#010x}, exp={exp:#010x}"

        got = await drive_and_read(dut, "ALU_SUB", a, b)
        exp = u32(a - b)
        assert got == exp, f"SUB {a:#x}-{b:#x}: got={got:#010x}, exp={exp:#010x}"

    for _ in range(100):
        a = random.getrandbits(32)
        b = random.getrandbits(32)
        assert await drive_and_read(dut, "ALU_ADD", a, b) == u32(a + b)
        assert await drive_and_read(dut, "ALU_SUB", a, b) == u32(a - b)

@cocotb.test()
async def test_bitwise(dut):
    vecs = [
        (0, 0), (0xFFFFFFFF, 0), (0xAAAAAAAA, 0x55555555),
        (0x12345678, 0x87654321), (-1, 0x13579BDF)
    ]
    for a, b in vecs:
        assert await drive_and_read(dut, "ALU_AND", a, b) == u32(a & b)
        assert await drive_and_read(dut, "ALU_OR",  a, b) == u32(a | b)
        assert await drive_and_read(dut, "ALU_XOR", a, b) == u32(a ^ b)

    for _ in range(100):
        a = random.getrandbits(32)
        b = random.getrandbits(32)
        assert await drive_and_read(dut, "ALU_AND", a, b) == u32(a & b)
        assert await drive_and_read(dut, "ALU_OR",  a, b) == u32(a | b)
        assert await drive_and_read(dut, "ALU_XOR", a, b) == u32(a ^ b)

@cocotb.test()
async def test_shifts(dut):
    vecs = [
        (0x1, 0), (0x1, 1), (0x1, 31), (0xF0F0F0F0, 4),
        (0x80000000, 1), (0x80000000, 31), (-1, 1), (-1, 31),
        (0x12345678, 40),  # usa só 5 LSBs -> 8
    ]

    for a, b in vecs:
        assert await drive_and_read(dut, "ALU_SLL", a, b) == sll32(a, b)
        assert await drive_and_read(dut, "ALU_SRL", a, b) == srl32(a, b)
        assert await drive_and_read(dut, "ALU_SRA", a, b) == sra32(a, b)

    for _ in range(100):
        a = random.getrandbits(32)
        b = random.getrandbits(32)
        assert await drive_and_read(dut, "ALU_SLL", a, b) == sll32(a, b)
        assert await drive_and_read(dut, "ALU_SRL", a, b) == srl32(a, b)
        assert await drive_and_read(dut, "ALU_SRA", a, b) == sra32(a, b)

@cocotb.test()
async def test_slt_sltu(dut):
    cases = [
        (-1, 1),
        (1, -1),
        (0, 0),
        (0x7fffffff, 0x80000000),
        (0xffffffff, 0),
        (1, 0xffffffff),
    ]

    for a, b in cases:
        got = await drive_and_read(dut, "ALU_SLT", a, b)
        exp = 1 if s32(a) < s32(b) else 0
        assert got == exp, f"SLT {a:#x} <s {b:#x}: got={got:#x}, exp={exp:#x}"

        got = await drive_and_read(dut, "ALU_SLTU", a, b)
        exp = 1 if u32(a) < u32(b) else 0
        assert got == exp, f"SLTU {a:#x} <u {b:#x}: got={got:#x}, exp={exp:#x}"

    for _ in range(100):
        a = random.getrandbits(32)
        b = random.getrandbits(32)
        assert await drive_and_read(dut, "ALU_SLT", a, b)  == (1 if s32(a) < s32(b) else 0)
        assert await drive_and_read(dut, "ALU_SLTU", a, b) == (1 if u32(a) < u32(b) else 0)

@cocotb.test()
async def test_pass_and_illegal(dut):
    vecs = [
        (0, 0), (0x12345678, 0x9ABCDEF0), (-1, 123), (0xCAFEBABE, 0xFEEDFACE)
    ]
    for a, b in vecs:
        assert await drive_and_read(dut, "ALU_PASS_A",  a, b) == u32(a)
        assert await drive_and_read(dut, "ALU_PASS_B",  a, b) == u32(b)
        assert await drive_and_read(dut, "ALU_ILLEGAL", a, b) == 0