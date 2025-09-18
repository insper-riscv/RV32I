import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_load_store_via_loads(dut):
    """Testa SW, SH, SB verificando os valores através de loads subsequentes"""

    async def step():
        # sobe clock
        dut.CLK.value = 1
        await Timer(5, units="ns")

        # word lida diretamente da RAM
        ram_out = int(dut.RAM_out.value)

        # dado já tratado pelo load (shift + sign/zero extend)
        ex_ram_out = int(dut.extenderRAM_out.value)

        # desce clock
        dut.CLK.value = 0
        await Timer(10, units="ns")

        # prepara próxima subida
        dut.CLK.value = 1
        await Timer(5, units="ns")

        return ram_out, ex_ram_out


    # ===== Inicialização =====
    await step()  # addi x1,0,0
    await step()  # lui x2,0xAABBD
    await step()  # addi x2,-803   (x2 = 0xAABBCCDD)

    # ===== STORES =====
    await step()  # sw
    await step()  # sh
    await step()  # sb

    # ===== LOADS e verificações =====
    ram, got_lw = await step()
    assert ram == 0xAABBCCDD, f"LW RAM errado: {ram:#x}"
    assert got_lw == 0xAABBCCDD, f"LW registrador errado: {got_lw:#x}"

    # LH (half aligned, 0x4)
    ram, got_lh = await step()
    assert (ram & 0xFFFF) == 0xCCDD, f"LH RAM errado: {ram:#x}"
    assert got_lh == 0xFFFFCCDD, f"LH registrador errado: {got_lh:#x}"

    # LHU
    ram, got_lhu = await step()
    assert (ram & 0xFFFF) == 0xCCDD, f"LHU RAM errado: {ram:#x}"
    assert got_lhu == 0x0000CCDD, f"LHU registrador errado: {got_lhu:#x}"

    # LB
    ram, got_lb = await step()
    assert (ram & 0xFF) == 0xDD, f"LB RAM errado: {ram:#x}"
    assert got_lb == 0xFFFFFFDD, f"LB registrador errado: {got_lb:#x}"

    # LBU
    ram, got_lbu = await step()
    assert (ram & 0xFF) == 0xDD, f"LBU RAM errado: {ram:#x}"
    assert got_lbu == 0x000000DD, f"LBU registrador errado: {got_lbu:#x}"


    dut._log.info("Todos os stores foram verificados via loads subsequentes")
