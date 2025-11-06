import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# Máscaras de exemplo
MASKS = [
    0b0001, 0b0010, 0b0100, 0b1000,   # 1 byte
    0b0011, 0b1100, 0b0110,           # 2 bytes
    0b1110, 0b0111,                   # 3 bytes
    0b1111                            # 4 bytes
]

async def init_dut(dut):
    dut.addr.value = 0
    dut.data_in.value = 0
    dut.mask.value = 0
    dut.weRAM.value = 0
    dut.reRAM.value = 0
    dut.eRAM.value = 0
    await Timer(1, units="ns")

async def write_word(dut, addr, data, mask):
    dut.addr.value = addr
    dut.data_in.value = data
    dut.mask.value = mask
    dut.eRAM.value = 1
    dut.weRAM.value = 1
    await RisingEdge(dut.clk)
    dut.weRAM.value = 0
    dut.eRAM.value = 0

async def read_word(dut, addr, expect_z=False):
    """
    Leitura síncrona: coloca endereço, habilita eRAM/reRAM, espera a subida do clock
    e captura o valor logo após a borda. Se expect_z=True, tenta verificar Z (raro
    em leitura síncrona; mantive o parâmetro por compatibilidade).
    """
    dut.addr.value = addr
    dut.eRAM.value = 1
    dut.reRAM.value = 1
    # esperar a borda que provoca a leitura síncrona
    await RisingEdge(dut.clk)
    # pequeno delay pós-borda para estabilização
    await Timer(1, units="ns")
    val = dut.data_out.value
    # desabilitar sinais (comportamento de teste original)
    dut.reRAM.value = 0
    dut.eRAM.value = 0

    if expect_z:
        # leitura síncrona normalmente não retorna Z; mantemos a verificação caso alguém
        # explicitamente peça por isso.
        assert str(val).lower().count("z") > 0, f"Esperado Z, obtido {val}"
        return None

    return int(val)

@cocotb.test()
async def sw_fullword(dut):
    """Testa escrita/leitura com mask=1111 (SW)."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    data = 0xDEADBEEF
    await write_word(dut, 0, data, 0b1111)
    got = await read_word(dut, 0)
    assert got == data, f"SW falhou: esperado {data:#010x}, obtido {got:#010x}"

@cocotb.test()
async def all_masks(dut):
    """Testa todas as máscaras possíveis de escrita parcial."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    base = 0x11223344
    addr = 0

    for mask in MASKS:
        # escreve valor base completo
        await write_word(dut, addr, base, 0b1111)
        # escreve valor novo parcial
        newval = 0xAABBCCDD
        await write_word(dut, addr, newval, mask)
        got = await read_word(dut, addr)

        # calcula esperado: mistura de base + newval conforme mask
        expected = 0
        for i in range(4):
            if (mask >> i) & 1:
                expected |= ((newval >> (8*i)) & 0xFF) << (8*i)
            else:
                expected |= ((base >> (8*i)) & 0xFF) << (8*i)

        assert got == expected, f"Mask {mask:04b} falhou: esperado {expected:#010x}, obtido {got:#010x}"

@cocotb.test()
async def disable_read(dut):
    """Verifica comportamento quando reRAM=0 ou eRAM=0 para leitura síncrona."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    data = 0xCAFEBABE
    await write_word(dut, 0, data, 0b1111)

    # 1) Ler normalmente com re=1/e=1 para obter o valor esperado
    dut.addr.value = 0
    dut.eRAM.value = 1
    dut.reRAM.value = 1
    await RisingEdge(dut.clk)
    await Timer(1, "ns")
    last_val = int(dut.data_out.value)
    # desabilita leitura (reRAM=0) e aplica outra borda: a saída deve manter last_val
    dut.reRAM.value = 0
    dut.eRAM.value = 1
    await RisingEdge(dut.clk)
    await Timer(1, "ns")
    assert int(dut.data_out.value) == last_val, "Esperado manter último valor quando reRAM=0"

    # agora testar eRAM=0: com re=1 mas eRAM=0 a leitura síncrona não deve atualizar o registrador,
    # então a saída deve continuar sendo last_val
    dut.reRAM.value = 1
    dut.eRAM.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, "ns")
    assert int(dut.data_out.value) == last_val, "Esperado manter último valor quando eRAM=0"

@cocotb.test()
async def multi_positions(dut):
    """Escreve em posições diferentes e confere leituras independentes."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    data0, data1, data2 = 0x11111111, 0x22222222, 0x33333333

    await write_word(dut, 0, data0, 0b1111)
    await write_word(dut, 4, data1, 0b1111)
    await write_word(dut, 8, data2, 0b1111)

    got0 = await read_word(dut, 0)
    got1 = await read_word(dut, 4)
    got2 = await read_word(dut, 8)

    assert got0 == data0
    assert got1 == data1
    assert got2 == data2

@cocotb.test()
async def overwrite(dut):
    """Escreve, sobrescreve, e confere atualização."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await init_dut(dut)

    first, second = 0xAAAAAAAA, 0x55555555

    await write_word(dut, 0, first, 0b1111)
    got1 = await read_word(dut, 0)
    assert got1 == first

    await write_word(dut, 0, second, 0b1111)
    got2 = await read_word(dut, 0)
    assert got2 == second
