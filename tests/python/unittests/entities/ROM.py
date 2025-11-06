from pathlib import Path
import cocotb
from cocotb.triggers import Timer
from cocotb.result import TestFailure

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

async def read_rom_sync(dut, word_addr: int, do_re: bool = True):
    """
    ROM síncrona: coloca endereço, seta re conforme do_re,
    aplica uma subida de clock e lê a saída logo após a subida.
    Usa valores inteiros (0/1) para atribuir sinais std_logic.
    """
    # assegurar valores estáveis antes da borda
    dut.addr.value = word_addr
    # **IMPORTANTE**: atribuir inteiros, não strings, para sinais std_logic
    dut.re.value = 1 if do_re else 0
    # garantir clock em '0' antes da subida
    dut.clk.value = 0
    await Timer(1, units="ns")

    # gerar subida de clock
    dut.clk.value = 1
    await Timer(1, units="ns")  # esperar um pouco depois da borda para a saída estabilizar

    # capturar valor
    val = int(dut.data.value)
    # voltar clock para 0 e esperar pequena margem
    dut.clk.value = 0
    await Timer(1, units="ns")

    return val

# ---------- TESTES ----------

@cocotb.test()
async def rom_leitura_sincrona_basica(dut):
    """
    Verifica leituras sincronas de algumas palavras iniciais e zeros no final,
    comparando com o arquivo HEX. Também verifica comportamento com re = '0'
    (saída mantém último valor).
    """
    here = Path(__file__).resolve()
    hex_path = here.parent / "data" / "testROM.hex"
    exp = parse_hex(hex_path, depth=64)

    # dar um pequeno tempo para a inicialização do processo de leitura do arquivo no VHDL
    await Timer(1, units="ns")

    # leituras com re = 1 (habilitado) -- checamos várias posições
    for word_idx in [0, 1, 2, 3, 4, 5, 6, 7, 10, 14, 21, 22, 63]:
        got = await read_rom_sync(dut, word_idx, do_re=True)
        assert got == exp[word_idx], (
            f"ROM[{word_idx}] esperado={exp[word_idx]:#010x}, lido={got:#010x}"
        )

    # teste extra: com re = 0 a saída deve manter o último valor lido
    # 1) ler uma posição conhecida com re=1
    last_idx = 2
    last_val = await read_rom_sync(dut, last_idx, do_re=True)

    # 2) trocar de endereço enquanto re=0 e aplicar um pulso de clock
    new_idx = 10
    val_after_re0 = await read_rom_sync(dut, new_idx, do_re=False)

    if val_after_re0 != last_val:
        raise TestFailure(
            f"Com re=0 esperava manter último valor {last_val:#010x}, "
            f"mas a saída mudou para {val_after_re0:#010x}"
        )

    # 3) com re=1 ler o novo endereço e conferir valor esperado
    val_after_re1 = await read_rom_sync(dut, new_idx, do_re=True)
    assert val_after_re1 == exp[new_idx], (
        f"Após re=1 ROM[{new_idx}] esperado={exp[new_idx]:#010x}, lido={val_after_re1:#010x}"
    )
