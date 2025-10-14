import os
from pathlib import Path
import cocotb
from cocotb.triggers import Timer
from utils.dut_io import dump_signature_from_dut  # só se for colher assinatura agora

@cocotb.test()
async def compliance_rv32i(dut):
    # dados passados pelo run_compliance.py
    elf_path = os.getenv("ELF_PATH")
    b = int(os.getenv("BEGIN_SIG", "0"), 0)
    e = int(os.getenv("END_SIG", "0"), 0)

    # reset
    if hasattr(dut, "RST"):
        dut.RST.value = 1
    dut.CLK.value = 0
    await Timer(10, "ns")
    if hasattr(dut, "RST"):
        dut.RST.value = 0

    # roda ciclos suficientes (ajuste)
    for _ in range(8000):
        dut.CLK.value = 1; await Timer(10, "ns")
        dut.CLK.value = 0; await Timer(10, "ns")

    # (opcional fase 1) coletar assinatura da RAM
    if e > b:
        out = Path(f"{elf_path}.dut.sig")
        dump_signature_from_dut(dut, b, e, out)
        dut._log.info(f"assinatura salva: {out}")