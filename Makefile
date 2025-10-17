.DEFAULT_GOAL := test
SHELL := /bin/bash

# ---------- Configs ----------
PY                ?= python3
ROOT              := $(CURDIR)
RUNNER            := tests/python/utils/runner.py
COMPLIANCE_SCRIPT := tests/python/cocotb/utils/run_compliance.py
ARCHTEST_DIR      := tests/third_party/riscv-arch-test

.PHONY: test run clean compliance compliance-one compliance-clean

# ---------- Alvos principais ----------

# Roda TODOS os testes (seus + compliance)
test:
	@echo "=== Rodando testes custom ==="
	$(PY) $(RUNNER) all
	@echo ""
	@echo "=== Rodando testes de compliance RV32I ==="
	$(PY) $(COMPLIANCE_SCRIPT)

# Roda um teste específico:
#   make run TEST=<nome_no_tests.json>
#   make run TEST=compliance              (equivalente a 'make compliance')
run:
ifndef TEST
	$(error Usage: make run TEST=<test_name> | TEST=compliance)
endif
ifeq ($(TEST),compliance)
	$(MAKE) compliance
else
	$(PY) -m tests.python.utils.runner $(TEST)
endif

# ---------- Compliance (riscv-arch-test) ----------

# Roda TODOS os testes listados em tests/testlists/rv32i.txt
compliance:
	$(PY) $(COMPLIANCE_SCRIPT)

# Roda UM teste específico do riscv-arch-test.
# Uso:
#   make compliance-one S=third_party/riscv-arch-test/riscv-test-suite/rv32i_m/I/src/add.S
compliance-one:
ifndef S
	$(error Use: make compliance-one S=third_party/.../algum_teste.S)
endif
	@$(PY) - <<-'PYCODE'
	from pathlib import Path
	import os, subprocess, shlex, sys
	ROOT=Path("$(ROOT)").resolve()
	TESTS=ROOT/'tests'
	RUNNER=ROOT/'$(RUNNER)'
	MK=ROOT/'tests/python/cocotb/instructions/Makefile'
	srel=os.environ.get('S')
	if not srel: sys.exit("Use: make compliance-one S=third_party/.../X.S")
	s_abs=(TESTS/srel).resolve()
	elf=s_abs.with_suffix(".elf"); hexc=s_abs.with_suffix(".hex")
	def sh(cmd,cwd):
	    print("$",cmd); subprocess.check_call(shlex.split(cmd),cwd=cwd)
	# build (usa o Makefile com as regras dos arch-tests)
	sh(f"make -f {MK} {elf.relative_to(ROOT)}",cwd=ROOT)
	sh(f"make -f {MK} {hexc.relative_to(ROOT)}",cwd=ROOT)
	# descobrir begin/end da assinatura
	nm = subprocess.check_output(["riscv32-unknown-elf-nm","-n",str(elf)], text=True)
	b=e=0
	for line in nm.splitlines():
	    if "begin_signature" in line: b=int(line.split()[0],16)
	    if "end_signature"   in line: e=int(line.split()[0],16)
	# ambiente para o runner (substitui __SET_AT_RUNTIME__)
	env=dict(os.environ)
	env["ROM_FILE"]=str(hexc)
	env["BEGIN_SIG"]=hex(b); env["END_SIG"]=hex(e); env["ELF_PATH"]=str(elf)
	# executa o runner no caso 'compliance_rv32i'
	subprocess.check_call([sys.executable, str(RUNNER), "compliance_rv32i"], cwd=ROOT, env=env)
	PYCODE

# Remove artefatos gerados pelos arch-tests
compliance-clean:
	@find $(ARCHTEST_DIR) -type f \( -name '*.elf' -o -name '*.hex' -o -name '*.bin' \) -print -delete 2>/dev/null || true

# ---------- Utilidades ----------

# Remove waves
clean:
	find . -type f \( -name '*.vcd' -o -name '*.ghw' \) -print -delete