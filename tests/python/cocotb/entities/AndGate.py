import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_andgate(dut):
    # Caso 1: 0 AND 0 = 0
    dut.a.value = 0
    dut.b.value = 0
    await Timer(1, units="ns")
    assert dut.y.value == 0
    # Caso 2: 1 AND 0 = 0
    dut.a.value = 1
    dut.b.value = 0
    await Timer(1, units="ns")
    assert dut.y.value == 0
    # Caso 3: 1 AND 1 = 1
    dut.a.value = 1
    dut.b.value = 1
    await Timer(1, units="ns")
    assert dut.y.value == 1