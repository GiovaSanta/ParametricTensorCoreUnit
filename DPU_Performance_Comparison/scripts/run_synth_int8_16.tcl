# --------------------------------------------------------------------
# run_synth_int8_16.tcl
# --------------------------------------------------------------------

set PART_NAME "xc7a100tcsg324-1"

set BASE_DIR [file normalize [file join [file dirname [info script]] ".."]]

set SRC_DIR      [file join $BASE_DIR "src"]
set REPORT_DIR   [file join $BASE_DIR "reports" "int8_16"]
set CONSTR_FILE  [file join $BASE_DIR "vivado" "constraints" "dpu_perf_clock.xdc"]

file mkdir $REPORT_DIR

close_project -quiet
create_project -force int8_16_dpu_perf_project [file join $BASE_DIR "vivado" "int8_16_dpu_perf_project"] -part $PART_NAME

# Add INT8_16 source files
set int8_16_main_files [glob -nocomplain [file join $SRC_DIR "int8_16" "*.vhd"]]
set int8_16_helper_files [glob -nocomplain [file join $SRC_DIR "int8_16" "needed_flopoco_files" "*.vhd"]]

if {[llength $int8_16_main_files] > 0} {
    add_files -fileset sources_1 -norecurse $int8_16_main_files
    set_property library int8_16_lib [get_files $int8_16_main_files]
}

if {[llength $int8_16_helper_files] > 0} {
    add_files -fileset sources_1 -norecurse $int8_16_helper_files
    set_property library int8_16_lib [get_files $int8_16_helper_files]
}

# Add wrapper
add_files -fileset sources_1 -norecurse [file join $SRC_DIR "wrappers" "INT8_16_DPU_perf_top.vhd"]

# Add clock constraint
add_files -fileset constrs_1 -norecurse $CONSTR_FILE

set_property top INT8_16_DPU_perf_top [current_fileset]

update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
open_run synth_1

report_utilization -file [file join $REPORT_DIR "utilization_int8_16.txt"]
report_timing_summary -file [file join $REPORT_DIR "timing_int8_16.txt"]

puts "INT8_16 DPU performance synthesis completed."
puts "Reports written to:"
puts "  [file join $REPORT_DIR utilization_int8_16.txt]"
puts "  [file join $REPORT_DIR timing_int8_16.txt]"