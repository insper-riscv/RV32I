#!/usr/bin/env python3
"""
MIFboot.py

Uso:
    python3 MIFboot.py <caminho_para_mif> <MEM_ID>

Exemplo:
    python3 MIFboot.py ../build/program.mif ROM
"""

import os
import sys
import subprocess
import time
import fileinput

def usage():
    print("Uso: MIFboot.py <mif_file> <MEM_ID>")
    sys.exit(1)

def programCDF(cdf):
    # reinicia o driver do jtagd para garantir que esteja funcionando
    try:
        subprocess.run(["killall", "jtagd"], check=False)
    except Exception:
        pass
    time.sleep(1)
    subprocess.run(["jtagconfig"], check=False)
    time.sleep(1)

    cdf = os.path.abspath(cdf)
    if not os.path.isfile(cdf):
        print(f"Arquivo {cdf} não encontrado")
        return 1

    print("Executando quartus_pgm para .cdf (se aplicável)...")
    # Se você tiver um .cdf para programar, pode chamar aqui.
    # pPGM = subprocess.Popen(["quartus_pgm", "-c", "1", "-m", "jtag", cdf])
    # exit_codes = pPGM.wait()
    return 0

def set_line_in_file(tclFile, key, new_value):
    """Substitui a linha que começa com 'set <key>' por: set <key> "<new_value>" """
    replaced = False
    for line in fileinput.input(tclFile, inplace=True):
        if line.strip().startswith(f"set {key}"):
            print(f'set {key} {{{new_value}}}')
            replaced = True
        else:
            print(line.rstrip())
    if not replaced:
        # Se a chave não existia, append no final
        with open(tclFile, "a") as f:
            f.write(f'\nset {key} {{{new_value}}}\n')

def getJtagPort():
    """
    Executa `jtagconfig` e retorna a parte útil da primeira linha,
    removendo um possível prefixo numérico do tipo '1) '.
    Ex: "1) USB-Blaster [1-4]" -> "USB-Blaster [1-4]".
    """
    proc = subprocess.Popen("jtagconfig", stdout=subprocess.PIPE, shell=True)
    (out, err) = proc.communicate()
    if not out:
        return ""
    text = out.decode(errors="ignore").strip()
    for line in text.splitlines():
        s = line.strip()
        if not s:
            continue
        # Se começar com algo como "1) ...", remova até o ')'
        if ')' in s:
            idx = s.find(')')
            candidate = s[idx+1:].strip()
        else:
            candidate = s
        # candidate agora é, por exemplo, "USB-Blaster [1-4]"
        return candidate
    return ""


def programROM(mif, memid):
    """
    Atualiza o arquivo TCL (atualizaMemoria.tcl) com o caminho do MIF, JTAG port e MEMID,
    e executa quartus_stp -t atualizaMemoria.tcl
    """
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    TCL = os.path.join(SCRIPT_DIR, "atualizaMemoria.tcl")

    mif = os.path.abspath(mif)
    if not os.path.isfile(mif):
        print(f"Arquivo {mif} não encontrado")
        return 1

    mif = mif.replace("\\", "/")

    print(f"Atualizando TCL: {TCL}")
    print(f" -> MIF = {mif}")
    print(f" -> MEMID = {memid}")

    # Substitui linhas no TCL
    set_line_in_file(TCL, "MIF", mif)
    set_line_in_file(TCL, "MEMID", memid)

    # detecta porta JTAG e coloca no TCL
    port = getJtagPort()
    if port:
        set_line_in_file(TCL, "JTAG", port)
        print(f"Porta JTAG detectada: {port}")
    else:
        print("Aviso: não foi possível detectar porta JTAG automaticamente (jtagconfig).")

    # chama quartus_stp com o TCL
    cmd = f"quartus_stp -t \"{TCL}\""
    print("Executando:", cmd)
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
    out, _ = proc.communicate()
    print(out.decode(errors="ignore"))
    return proc.returncode

def main():
    if len(sys.argv) < 3:
        usage()

    mif = sys.argv[1]
    memid = sys.argv[2]

    # opcional: garante que python é executado a partir da pasta tools
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    rc = programROM(mif, memid)
    if rc != 0:
        print("Erro ao executar programROM (exit code {})".format(rc))
        sys.exit(rc)
    print("Concluído com sucesso.")

if __name__ == "__main__":
    main()
