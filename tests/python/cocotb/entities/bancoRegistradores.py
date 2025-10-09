# tests/RegFIle.py
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# ===== Helpers =====
def _mask(width: int) -> int:
    """Faz uma mascara, se os registradores tem 8 bits, retorna 0xFF, se tem 4 bits, retorna 0xF e assim por diante."""
    return (1 << width) - 1 if width > 0 else 0

async def _read_ports(dut, a_addr: int, b_addr: int):
    """Leituras assíncronas: ajusta endereços e espera pequenos deltas."""
    dut.rs1.value = a_addr
    dut.rs2.value = b_addr
    # Espera uma pequena janela para propagação combinacional
    await Timer(1, units="ns")
    aval = int(dut.d_rs1.value)
    bval = int(dut.d_rs2.value)
    return aval, bval

async def _write_reg(dut, addr: int, data: int):
    """Escrita sincronizada: amostrada na borda de subida do clock."""
    dut.rd.value = addr
    dut.data_in.value = data
    dut.we.value = 1
    await RisingEdge(dut.clk)
    # pequena folga de propagação para leituras combinacionais subsequentes
    #await Timer(1, units="ns")
    dut.we.value = 0


def _restart_clock(dut, period_ns=10):

    if hasattr(dut, "_clk_gen"):
        try:
            dut._clk_gen.kill()
        except Exception:
            pass

    dut.clk.setimmediatevalue(0)

    dut._clk_gen = cocotb.start_soon(
        Clock(dut.clk, period_ns, units="ns").start()
    )

# ============== 1) Leitura inicial (x0 zero) ==============
@cocotb.test()
async def inicializacao_e_x0(dut):
    """Verifica leitura inicial e o comportamento do registrador x0 (endereço 0 => sempre zero)."""
    _restart_clock(dut, 10)

    dut.clear.value=1
    await Timer(1, units="ns")
    dut.clear.value=0

    aw = len(dut.rs1)
    dw = len(dut.d_rs1)
    m = _mask(dw)

    # Lê x0 simultaneamente em A e B
    a, b = await _read_ports(dut, 0, 0)
    assert a == 0 and b == 0, f"x0 deveria ser 0; A={a}, B={b}"

    # Lê dois registradores quaisquer diferentes de zero (não depende de pré-inicialização)
    last = (1 << aw) - 1
    a_addr, b_addr = 1, last
    a, b = await _read_ports(dut, a_addr, b_addr)
    # Não há expectativa fixa; apenas garante que são w-bit
    assert 0 <= a <= m and 0 <= b <= m

# ============== 2) Escrita e leitura simples ==============
@cocotb.test()
async def escrita_e_leitura_basica(dut):
    """Escreve em um registrador e confere leituras nas duas portas."""
    _restart_clock(dut, 10)

    dut.clear.value=1
    await Timer(1, units="ns")
    dut.clear.value=0

    dw = len(dut.d_rs1)
    m = _mask(dw)

    addr = 3
    val  = 0xDEADBEEF & m

    await _write_reg(dut, addr, val)

    a, b = await _read_ports(dut, addr, addr)
    assert a == val and b == val, f"Após escrita, esperado {val:#x} em A/B, obtido A={a:#x} B={b:#x}"

# ============== 3) x0 hardwired a zero mesmo após escrita ==============
@cocotb.test()
async def x0_sempre_zero(dut):
    """Tenta escrever em x0; leituras de endereço 0 devem continuar retornando zero."""
    _restart_clock(dut, 10)

    dut.clear.value=1
    await Timer(1, units="ns")
    dut.clear.value=0

    dw = len(dut.d_rs1)
    m = _mask(dw)

    val = 0xFFFFFFFF & m
    await _write_reg(dut, 0, val)

    a, b = await _read_ports(dut, 0, 0)
    assert a == 0 and b == 0, f"x0 deve ser 0 mesmo após escrita; A={a:#x} B={b:#x}"

# ============== 4) Leituras simultâneas independentes ==============
@cocotb.test()
async def leituras_simultaneas(dut):
    """Portas A e B devem ler endereços independentes no mesmo ciclo."""
    _restart_clock(dut, 10)

    dut.clear.value=1
    await Timer(1, units="ns")
    dut.clear.value=0

    aw = len(dut.rs1)
    dw = len(dut.d_rs1)
    m = _mask(dw)

    addr_a = 4
    addr_b = 7
    vala = 0x12345678 & m
    valb = 0xA5A5A5A5 & m

    await _write_reg(dut, addr_a, vala)
    await _write_reg(dut, addr_b, valb)

    a, b = await _read_ports(dut, addr_a, addr_b)
    assert a == vala and b == valb, f"Esperado A={vala:#x}, B={valb:#x}; obtido A={a:#x}, B={b:#x}"

# ============== 5) Escrever e ler o MESMO endereço no ciclo ==============
@cocotb.test()
async def write_then_read_same_cycle(dut):
    """
    Se os endereços de leitura apontarem para o mesmo alvo da escrita,
    após a borda de subida (quando a escrita acontece), a leitura combinacional deve refletir o novo valor.
    """
    _restart_clock(dut, 10)

    dut.clear.value=1
    await Timer(1, units="ns")
    dut.clear.value=0

    await RisingEdge(dut.clk)

    dw = len(dut.d_rs1)
    mask = (1 << dw) - 1
    addr = 9
    novo = 0xCAFEBABE & mask

    # Configura leituras
    dut.rs1.value = addr
    dut.rs2.value = addr
    dut.rd.value = addr
    dut.data_in.value = novo
    dut.we.value = 1

    await RisingEdge(dut.clk)
    dut.we.value = 0
    
    await Timer(1, units="ns")
    # Log detalhado
    a = int(dut.d_rs1.value)
    b = int(dut.d_rs2.value)
    dut._log.info(f"[DEPOIS DA BORDA] addr={addr} novo={novo:#x} A={a:#x} B={b:#x}")

    assert a == novo and b == novo, (
        f"A/B deveriam refletir novo valor {novo:#x}; A={a:#x} B={b:#x}"
    )


# ============== 6) Fuzz: muitos ciclos aleatórios ==============
@cocotb.test()
async def fuzz_banco(dut):
    """Sequência aleatória de escritas e leituras; x0 deve permanecer 0 em todas leituras."""
    _restart_clock(dut, 10)

    dut.clear.value=1
    await Timer(1, units="ns")
    dut.clear.value=0

    aw = len(dut.rs1)
    dw = len(dut.d_rs1)
    m = _mask(dw)
    nregs = 2**aw # Quantidade de registradores no banco

    ref = [0] * nregs

    random.seed(2025)
    N = 200

    for _ in range(N):
        op = random.choice(["W", "R"])
        if op == "W":
            addr = random.randrange(nregs)
            data = random.getrandbits(dw) & m
            await _write_reg(dut, addr, data)
            ref[addr] = data
        else:
            a_addr = random.randrange(nregs)
            b_addr = random.randrange(nregs)
            a, b = await _read_ports(dut, a_addr, b_addr)

            exp_a = 0 if a_addr == 0 else ref[a_addr]
            exp_b = 0 if b_addr == 0 else ref[b_addr]

            assert a == exp_a, f"(R) A: end={a_addr} exp={exp_a:#x} got={a:#x}"
            assert b == exp_b, f"(R) B: end={b_addr} exp={exp_b:#x} got={b:#x}"

    # Checagem final explícita de x0
    a, b = await _read_ports(dut, 0, 0)
    assert a == 0 and b == 0, f"x0 deve ser 0 ao final; A={a:#x} B={b:#x}"
