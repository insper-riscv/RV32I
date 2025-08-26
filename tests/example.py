# test_my_design.py (usando cocotb.clock.Clock)
import cocotb
from cocotb.triggers import FallingEdge, Timer
from cocotb.clock import Clock

@cocotb.test()
async def firs_test(dut):
    """Try accessing the design."""

    # Inicia um clock de 2ns de período (1ns alto, 1ns baixo) no sinal dut.clk
    # A função original gerava um clock com período de 2ns
    cocotb.start_soon(Clock(dut.clk, 2, units="ns").start())

    await Timer(5, units="ns")  # wait a bit
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"

    dut._log.info("my_signal_1 is %s", dut.my_signal_1.value)
    assert dut.my_signal_2.value[0] == 0, "my_signal_2[0] is not 0!"