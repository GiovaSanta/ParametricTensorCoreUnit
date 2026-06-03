# --------------------------------------------------------------------
# run_synth_int16_32.tcl
#
# Synthesize the registered INT16_32 DPU performance wrapper.
#
# Reports generated:
#   reports/int16_32/utilization_int16_32.txt
#   reports/int16_32/timing_int16_32.txt
# --------------------------------------------------------------------

set PART_NAME "xc7a100tcsg324-1"

set BASE_DIR [file normalize [file join [file dirname [info script]] ".."]]

set SRC_DIR      [file join $BASE_DIR "src"]
set REPORT_DIR   [file join $BASE_DIR "reports" "int16_32"]
set CONSTR_FILE  [file join $BASE_DIR "vivado" "constraints" "dpu_perf_clock.xdc"]

file mkdir $REPORT_DIR

close_project -quiet
create_project -force int16_32_dpu_perf_project [file join $BASE_DIR "vivado" "int16_32_dpu_perf_project"] -part $PART_NAME

# --------------------------------------------------------------------
# Add INT16_32 DPU files into dedicated library
# --------------------------------------------------------------------
set int16_32_main_files [glob -nocomplain [file join $SRC_DIR "int16_32" "*.vhd"]]
set int16_32_helper_files [glob -nocomplain [file join $SRC_DIR "int16_32" "needed_flopoco_files" "*.vhd"]]

if {[llength $int16_32_main_files] > 0} {
    add_files -fileset sources_1 -norecurse $int16_32_main_files
    set_property library int16_32_lib [get_files $int16_32_main_files]
}

if {[llength $int16_32_helper_files] > 0} {
    add_files -fileset sources_1 -norecurse $int16_32_helper_files
    set_property library int16_32_lib [get_files $int16_32_helper_files]
}

# --------------------------------------------------------------------
# Add wrapper into default work library
# --------------------------------------------------------------------
add_files -fileset sources_1 -norecurse [file join $SRC_DIR "wrappers" "INT16_32_DPU_perf_top.vhd"]

# --------------------------------------------------------------------
# Add clock constraint
# --------------------------------------------------------------------
add_files -fileset constrs_1 -norecurse $CONSTR_FILE

set_property top INT16_32_DPU_perf_top [current_fileset]

update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
open_run synth_1

report_utilization -file [file join $REPORT_DIR "utilization_int16_32.txt"]
report_timing_summary -file [file join $REPORT_DIR "timing_int16_32.txt"]

puts "INT16_32 DPU performance synthesis completed."
puts "Reports written to:"
puts "  [file join $REPORT_DIR utilization_int16_32.txt]"
puts "  [file join $REPORT_DIR timing_int16_32.txt]"