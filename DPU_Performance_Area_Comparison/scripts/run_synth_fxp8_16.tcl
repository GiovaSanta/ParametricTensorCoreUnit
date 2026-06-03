# --------------------------------------------------------------------
# run_synth_fxp8_16.tcl
# --------------------------------------------------------------------

set PART_NAME "xc7a100tcsg324-1"

set BASE_DIR [file normalize [file join [file dirname [info script]] ".."]]

set SRC_DIR      [file join $BASE_DIR "src"]
set REPORT_DIR   [file join $BASE_DIR "reports" "fxp8_16"]
set CONSTR_FILE  [file join $BASE_DIR "vivado" "constraints" "dpu_perf_clock.xdc"]

file mkdir $REPORT_DIR

close_project -quiet
create_project -force fxp8_16_dpu_perf_project [file join $BASE_DIR "vivado" "fxp8_16_dpu_perf_project"] -part $PART_NAME

# Add FXP8_16 source files
set fxp8_16_main_files [glob -nocomplain [file join $SRC_DIR "fxp8_16" "*.vhd"]]
set fxp8_16_helper_files [glob -nocomplain [file join $SRC_DIR "fxp8_16" "needed_flopoco_files" "*.vhd"]]

if {[llength $fxp8_16_main_files] > 0} {
    add_files -fileset sources_1 -norecurse $fxp8_16_main_files
    set_property library fxp8_16_lib [get_files $fxp8_16_main_files]
}

if {[llength $fxp8_16_helper_files] > 0} {
    add_files -fileset sources_1 -norecurse $fxp8_16_helper_files
    set_property library fxp8_16_lib [get_files $fxp8_16_helper_files]
}

# Add wrapper
add_files -fileset sources_1 -norecurse [file join $SRC_DIR "wrappers" "FXP8_16_DPU_perf_top.vhd"]

# Add clock constraint
add_files -fileset constrs_1 -norecurse $CONSTR_FILE

set_property top FXP8_16_DPU_perf_top [current_fileset]

update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
open_run synth_1

report_utilization -file [file join $REPORT_DIR "utilization_fxp8_16.txt"]
report_timing_summary -file [file join $REPORT_DIR "timing_fxp8_16.txt"]

puts "FXP8_16 DPU performance synthesis completed."
puts "Reports written to:"
puts "  [file join $REPORT_DIR utilization_fxp8_16.txt]"
puts "  [file join $REPORT_DIR timing_fxp8_16.txt]"