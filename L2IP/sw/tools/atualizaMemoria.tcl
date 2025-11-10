# atualizaMemoria.tcl - simples, aceita index opcional
# Usage: quartus_stp -t atualizaMemoria.tcl <MIF_PATH> <MEM_ID> [INSTANCE_INDEX]
# Example: quartus_stp -t atualizaMemoria.tcl build/firmware_rom.mif ROM 0

package require ::quartus::insystem_memory_edit

if { $argc < 2 } {
    puts stderr "Uso: quartus_stp -t atualizaMemoria.tcl <MIF_PATH> <MEM_ID> [INSTANCE_INDEX]"
    exit 1
}

set MIF_PATH [lindex $argv 0]
set MEMID    [lindex $argv 1]
# optional 3rd arg: instance index
if { $argc >= 3 } {
    set INST_IDX [lindex $argv 2]
} else {
    set INST_IDX 0
}

# try to detect JTAG interface name, fallback to USB-Blaster
set JTAG "USB-Blaster"
if { [catch { set jc [exec jtagconfig] } err] } {
    # no jtagconfig -> keep fallback
    puts "jtagconfig não disponível, usando JTAG padrão: $JTAG"
} else {
    # parse first found line like "1) USB-Blaster [1-4]"
    foreach line [split $jc "\n"] {
        if {[regexp {^\s*\d+\)\s+(.+)$} $line -> hwname]} {
            set JTAG [string trim $hwname]
            break
        }
    }
    puts "Usando JTAG: $JTAG"
}

# device string (ajuste se necessário)
set DEV_NAME "@1: 5CE(BA4|FA4) (0x02B050DD)"

puts ""
puts "Atualizando memória:"
puts "  MIF: $MIF_PATH"
puts "  MEMID (info): $MEMID"
puts "  instance_index: $INST_IDX"
puts "  hardware: $JTAG"
puts "  device: $DEV_NAME"
puts ""

# try to end any previous session (best-effort)
catch { end_memory_edit }

# begin session
if { [catch { begin_memory_edit -hardware_name $JTAG -device_name $DEV_NAME } err] } {
    puts stderr "Erro em begin_memory_edit: $err"
    exit 2
}

# update using index provided
if { [catch { update_content_to_memory_from_file -instance_index $INST_IDX -mem_file_path $MIF_PATH -mem_file_type "mif" } uerr] } {
    puts stderr "Erro em update_content_to_memory_from_file (index $INST_IDX): $uerr"
    catch { end_memory_edit }
    exit 3
}

# finalize
if { [catch { end_memory_edit } enderr] } {
    puts stderr "Warning ao terminar sessão: $enderr"
}

puts "Atualização concluída para instance_index $INST_IDX"
exit 0
