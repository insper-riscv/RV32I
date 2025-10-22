import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_load_store_via_loads_and_regs(dut):
    """Testa SW, SH, SB verificando loads + valores nos registradores via ADD t3,reg,x0"""

    async def step():
        dut.CLK.value = 1
        await Timer(5, units="ns")
        alu_out = int(dut.ALU_out.value)
        ram_out = int(dut.RAM_out.value)
        ext_ram_out = int(dut.extenderRAM_out.value)
        dut.CLK.value = 0
        await Timer(10, units="ns")
        dut.CLK.value = 1
        await Timer(5, units="ns")
        return alu_out, ram_out, ext_ram_out

    # ===== Inicialização =====
    await step()  # addi x1,0,0
    await step()  # lui x2,0xAABBD
    await step()  # addi x2,-803   (x2 = 0xAABBCCDD)

    # ===== STORES =====
    await step()  # sw
    await step()  # sh
    await step()  # sb

    # ===== LOADS + exposições =====
    _, _, _ = await step()       # lw
    alu, _, _ = await step()     # add t3,x3,x0
    assert alu == 0xAABBCCDD, f"LW falhou no reg: {alu:#x}"

    _, _, _ = await step()       # lh
    alu, _, _ = await step()     # add t3,x4,x0
    assert alu == 0xFFFFCCDD & 0xFFFFFFFF, f"LH falhou no reg: {alu:#x}"

    _, _, _ = await step()       # lhu
    alu, _, _ = await step()     # add t3,x5,x0
    assert alu == 0x0000CCDD, f"LHU falhou no reg: {alu:#x}"

    _, _, _ = await step()       # lb
    alu, _, _ = await step()     # add t3,x6,x0
    assert alu == 0xFFFFFFDD & 0xFFFFFFFF, f"LB falhou no reg: {alu:#x}"

    _, _, _ = await step()       # lbu
    alu, _, _ = await step()     # add t3,x7,x0
    assert alu == 0x000000DD, f"LBU falhou no reg: {alu:#x}"

    dut._log.info("Todos os loads/stores + registradores passaram")
