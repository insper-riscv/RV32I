# tests/python/cocotb/rommips.py
import re
from pathlib import Path
import cocotb
from cocotb.triggers import Timer

# ---------- Helpers ----------
def parse_mif(mif_path: Path, width_bits=32, depth=64):
    """
    Parser simples de .mif para encher uma lista de 'depth' palavras (int).
    Suporta linhas 'ADDR : DATA;' e ranges '[a..b]: DATA;'.
    Ignora comentários e linhas vazias.
    """
    mem = [0] * depth
    hex_mask = (1 << width_bits) - 1

    text = mif_path.read_text(encoding="utf-8", errors="ignore")
    # Normaliza
    lines = [ln.strip() for ln in text.splitlines()]

    # tenta achar DEPTH/WIDTH no próprio MIF se quiser autodetectar
    # (mas usaremos os defaults do entity, que batem com o seu VHDL)
    addr_data_re = re.compile(r"^(\d+)\s*:\s*([0-9A-Fa-f_]+)\s*;")
    range_re     = re.compile(r"^\[(\d+)\.\.(\d+)\]\s*:\s*([0-9A-Fa-f_]+)\s*;")

    in_content = False
    for ln in lines:
        if not ln or ln.startswith("--"):
            continue
        if ln.upper().startswith("CONTENT BEGIN"):
            in_content = True
            continue
        if ln.upper().startswith("END") and in_content:
            break
        if not in_content:
            continue

        m1 = addr_data_re.match(ln)
        if m1:
            addr = int(m1.group(1))
            data = int(m1.group(2).replace("_",""), 16) & hex_mask
            if 0 <= addr < depth:
                mem[addr] = data
            continue

        m2 = range_re.match(ln)
        if m2:
            a0  = int(m2.group(1))
            a1  = int(m2.group(2))
            data = int(m2.group(3).replace("_",""), 16) & hex_mask
            for a in range(a0, a1 + 1):
                if 0 <= a < depth:
                    mem[a] = data
            continue

    return mem

async def read_rom(dut, byte_addr: int):
    """A ROM é assíncrona: escreve Endereco e espera um pequeno delta."""
    dut.addr.value = byte_addr
    await Timer(1, units="ns")
    return int(dut.data.value)

def byte_to_index(byte_addr: int) -> int:
    """Emula a mesma fatia do VHDL: Endereco(memoryAddrWidth+1 downto 2)."""
    # Como memoryAddrWidth=6 (profundidade 64), o índice é Endereco[7:2]
    return (byte_addr >> 2) & ((1 << 6) - 1)

# ---------- TESTES ----------

@cocotb.test()
async def rom_leitura_basica(dut):
    """
    Verifica leituras de algumas palavras iniciais e zeros no final,
    comparando com o ROMcontent.mif.
    """
    # Localiza o MIF.
    # Ajuste se necessário.
    # Tenta algumas localizações comuns relativas à pasta do teste:
    here = Path(__file__).resolve()
    mif_path = here.parents[3] / "src" / "initROM.mif"

    exp = parse_mif(mif_path, width_bits=len(dut.data), depth=64)

    # Checa alguns endereços (byte addresses) que mapeiam 0, 1, 2...
    for word_idx in [0, 1, 2, 3, 4, 5, 6, 7, 10, 14, 21, 22, 63]:
        byte_addr = word_idx << 2
        got = await read_rom(dut, byte_addr)
        assert got == exp[word_idx], (
            f"ROM[{word_idx}] esperado={exp[word_idx]:#010x}, lido={got:#010x}"
        )

@cocotb.test()
async def rom_alias_byte_addresses(dut):
    """
    Confere que endereços byte-alinhados dentro da mesma palavra (k*4 + {0,1,2,3})
    retornam o MESMO data (pois Endereco[1:0] é ignorado).
    """
    # Escolhe alguns índices para amostrar
    for word_idx in [0, 1, 9, 21, 31, 63]:
        base = word_idx << 2
        vals = []
        for off in [0, 1, 2, 3]:
            vals.append(await read_rom(dut, base + off))
        assert len(set(vals)) == 1, (
            f"Byte-alias falhou em idx {word_idx}: leituras={list(map(lambda x: f'{x:#010x}', vals))}"
        )

@cocotb.test()
async def rom_limites(dut):
    """
    Limites de endereço:
    - menor byte address (0) -> idx 0
    - maior byte address que ainda indexa a última palavra: (63<<2)+{0..3} -> idx 63
    """
    low = await read_rom(dut, 0)
    low_again = await read_rom(dut, 3)
    assert low == low_again, "Endereços 0 e 3 devem mapear para o mesmo data (idx 0)."

    top_base = 63 << 2
    top_vals = [await read_rom(dut, top_base + off) for off in [0,1,2,3]]
    assert len(set(top_vals)) == 1, "Os quatro bytes finais devem ler a mesma palavra (idx 63)."
