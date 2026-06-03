# --------------------------------------------------------------------
# run_synth_fxp16_32.tcl
#
# Synthesize the registered FXP16_32 DPU performance wrapper.
#
# Reports generated:
#   reports/fxp16_32/utilization_fxp16_32.txt
#   reports/fxp16_32/timing_fxp16_32.txt
# --------------------------------------------------------------------

set PART_NAME "xc7a100tcsg324-1"

set BASE_DIR [file normalize [file join [file dirname [info script]] ".."]]

set SRC_DIR      [file join $BASE_DIR "src"]
set REPORT_DIR   [file join $BASE_DIR "reports" "fxp16_32"]
set CONSTR_FILE  [file join $BASE_DIR "vivado" "constraints" "dpu_perf_clock.xdc"]

file mkdir $REPORT_DIR

close_project -quiet
create_project -force fxp16_32_dpu_perf_project [file join $BASE_DIR "vivado" "fxp16_32_dpu_perf_project"] -part $PART_NAME

# --------------------------------------------------------------------
# Add FXP16_32 DPU files into dedicated library
# --------------------------------------------------------------------
set fxp16_32_main_files [glob -nocomplain [file join $SRC_DIR "fxp16_32" "*.vhd"]]
set fxp16_32_helper_files [glob -nocomplain [file join $SRC_DIR "fxp16_32" "needed_flopoco_files" "*.vhd"]]

if {[llength $fxp16_32_main_files] > 0} {
    add_files -fileset sources_1 -norecurse $fxp16_32_main_files
    set_property library fxp16_32_lib [get_files $fxp16_32_main_files]
}

if {[llength $fxp16_32_helper_files] > 0} {
    add_files -fileset sources_1 -norecurse $fxp16_32_helper_files
    set_property library fxp16_32_lib [get_files $fxp16_32_helper_files]
}

# --------------------------------------------------------------------
# Add wrapper into default work library
# --------------------------------------------------------------------
add_files -fileset sources_1 -norecurse [file join $SRC_DIR "wrappers" "FXP16_32_DPU_perf_top.vhd"]

# --------------------------------------------------------------------
# Add clock constraint
# --------------------------------------------------------------------
add_files -fileset constrs_1 -norecurse $CONSTR_FILE

set_property top FXP16_32_DPU_perf_top [current_fileset]

update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
open_run synth_1

report_utilization -file [file join $REPORT_DIR "utilization_fxp16_32.txt"]
report_timing_summary -file [file join $REPORT_DIR "timing_fxp16_32.txt"]

puts "FXP16_32 DPU performance synthesis completed."
puts "Reports written to:"
puts "  [file join $REPORT_DIR utilization_fxp16_32.txt]"
puts "  [file join $REPORT_DIR timing_fxp16_32.txt]"