# tools/dumpMemory.tcl
# Uso:
#   quartus_stp -t tools/dumpMemory.tcl <OUTFILE> <INST_IDX>
# Exemplo:
#   quartus_stp -t tools/dumpMemory.tcl core/output_mifs/test1_ram.mif 1

package require ::quartus::insystem_memory_edit

# argumentos (com defaults)
set OUTFILE  [expr {[llength $argv] >= 1 ? [lindex $argv 0] : "core/output_mifs/ram_dump.mif"}]
set INST_IDX [expr {[llength $argv] >= 2 ? [lindex $argv 1] : 1}]

# detecta JTAG via jtagconfig (fallback)
set JTAG "USB-Blaster"
if { [catch { set jc [exec jtagconfig] } err] } {
    puts "jtagconfig não disponível, usando JTAG: $JTAG"
} else {
    foreach line [split $jc "\n"] {
        if {[regexp {^\s*\d+\)\s+(.+)$} $line -> hwname]} {
            set JTAG [string trim $hwname]
            break
        }
    }
    puts "Usando JTAG: $JTAG"
}

# device string — ajuste se necessário
set DEV_NAME "@1: 5CE(BA4|FA4) (0x02B050DD)"

puts ""
puts "Iniciando dump da memória editável"
puts "  arquivo de saída: $OUTFILE"
puts "  instance index  : $INST_IDX"
puts "  hardware        : $JTAG"
puts "  device          : $DEV_NAME"
puts ""

# encerra sessão se houver
catch { end_memory_edit }

if { [catch { begin_memory_edit -hardware_name $JTAG -device_name $DEV_NAME } err] } {
    puts stderr "Erro em begin_memory_edit: $err"
    exit 2
}

# Lista instâncias editáveis (útil para escolher o índice correto)
set inst_list [list]
if {[catch { set inst_list [get_editable_mem_instances] } gerr]} {
    puts "Aviso: não foi possível listar instâncias de memória editável: $gerr"
} else {
    puts "Instâncias editáveis encontradas (index : description) :"
    set i 0
    foreach it $inst_list {
        puts "  $i : $it"
        incr i
    }
}

# Salva o conteúdo da instância selecionada (mem_file_type = mif)
if {[catch { save_content_from_memory_to_file -instance_index $INST_IDX -mem_file_path $OUTFILE -mem_file_type "mif" } serr]} {
    puts stderr "Erro em save_content_from_memory_to_file: $serr"
    catch { end_memory_edit }
    exit 3
}

catch { end_memory_edit }
puts "Dump concluído: $OUTFILE"
exit 0
