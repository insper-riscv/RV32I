from pathlib import Path
import cocotb
from cocotb.triggers import Timer

# ---------- Helpers ----------
def parse_hex(hex_path: Path, depth=64):
    """
    Lê um arquivo .hex com uma palavra de 32 bits por linha.
    Retorna uma lista de 'depth' palavras (int).
    """
    mem = [0] * depth
    lines = [ln.strip() for ln in hex_path.read_text().splitlines() if ln.strip()]
    for idx, ln in enumerate(lines):
        if idx >= depth:
            break
        mem[idx] = int(ln, 16) & 0xFFFFFFFF
    return mem

async def read_rom(dut, byte_addr: int):
    """ROM é assíncrona: coloca endereço e espera um delta."""
    dut.addr.value = byte_addr
    await Timer(1, units="ns")
    return int(dut.data.value)

def byte_to_index(byte_addr: int, memoryAddrWidth=6) -> int:
    """Mesma lógica do VHDL: Endereco[memoryAddrWidth+1 downto 2]."""
    return (byte_addr >> 2) & ((1 << memoryAddrWidth) - 1)

# ---------- TESTES ----------

@cocotb.test()
async def rom_leitura_basica(dut):
    """
    Verifica leituras de algumas palavras iniciais e zeros no final,
    comparando com o arquivo HEX.
    """
    here = Path(__file__).resolve()
    hex_path = here.parent / "data" / "testROM.hex"
    exp = parse_hex(hex_path, depth=64)

    for word_idx in [0, 1, 2, 3, 4, 5, 6, 7, 10, 14, 21, 22, 63]:
        byte_addr = word_idx << 2
        got = await read_rom(dut, byte_addr)
        assert got == exp[word_idx], (
            f"ROM[{word_idx}] esperado={exp[word_idx]:#010x}, lido={got:#010x}"
        )

@cocotb.test()
async def rom_alias_byte_addresses(dut):
    """
    Confere que endereços byte-alinhados dentro da mesma word (k*4+{0,1,2,3})
    retornam o mesmo dado.
    """
    for word_idx in [0, 1, 9, 21, 31, 63]:
        base = word_idx << 2
        vals = [await read_rom(dut, base + off) for off in [0, 1, 2, 3]]
        assert len(set(vals)) == 1, (
            f"Byte-alias falhou em idx {word_idx}: leituras={[f'{v:#010x}' for v in vals]}"
        )

@cocotb.test()
async def rom_limites(dut):
    """
    Testa limites de endereço:
    - menor byte address (0) -> idx 0
    - maior byte address que ainda indexa a última word: (63<<2)+{0..3} -> idx 63
    """
    low = await read_rom(dut, 0)
    low_again = await read_rom(dut, 3)
    assert low == low_again, "Endereços 0 e 3 devem mapear para a mesma word (idx 0)."

    top_base = 63 << 2
    top_vals = [await read_rom(dut, top_base + off) for off in [0, 1, 2, 3]]
    assert len(set(top_vals)) == 1, "Os quatro bytes finais devem ler a mesma word (idx 63)."
