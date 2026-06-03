# --------------------------------------------------------------------
# run_synth_posit8.tcl
#
# Synthesize the registered Posit8 DPU performance wrapper.
#
# Reports generated:
#   reports/posit8/utilization_posit8.txt
#   reports/posit8/timing_posit8.txt
# --------------------------------------------------------------------

set PART_NAME "xc7a100tcsg324-1"

set BASE_DIR [file normalize [file join [file dirname [info script]] ".."]]

set SRC_DIR      [file join $BASE_DIR "src"]
set REPORT_DIR   [file join $BASE_DIR "reports" "posit8"]
set CONSTR_FILE  [file join $BASE_DIR "vivado" "constraints" "dpu_perf_clock.xdc"]

file mkdir $REPORT_DIR

close_project -quiet
create_project -force posit8_dpu_perf_project [file join $BASE_DIR "vivado" "posit8_dpu_perf_project"] -part $PART_NAME

# --------------------------------------------------------------------
# Add Posit8 DPU files into dedicated library
# --------------------------------------------------------------------
set posit8_main_files [glob -nocomplain [file join $SRC_DIR "posit8" "*.vhd"]]
set posit8_helper_files [glob -nocomplain [file join $SRC_DIR "posit8" "needed_flopoco_files" "*.vhd"]]

if {[llength $posit8_main_files] > 0} {
    add_files -fileset sources_1 -norecurse $posit8_main_files
    set_property library posit8_lib [get_files $posit8_main_files]
}

if {[llength $posit8_helper_files] > 0} {
    add_files -fileset sources_1 -norecurse $posit8_helper_files
    set_property library posit8_lib [get_files $posit8_helper_files]
}

# --------------------------------------------------------------------
# Add wrapper into default work library
# --------------------------------------------------------------------
add_files -fileset sources_1 -norecurse [file join $SRC_DIR "wrappers" "POSIT8_DPU_perf_top.vhd"]

# --------------------------------------------------------------------
# Add clock constraint
# --------------------------------------------------------------------
add_files -fileset constrs_1 -norecurse $CONSTR_FILE

set_property top POSIT8_DPU_perf_top [current_fileset]

update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
open_run synth_1

report_utilization -file [file join $REPORT_DIR "utilization_posit8.txt"]
report_timing_summary -file [file join $REPORT_DIR "timing_posit8.txt"]

puts "Posit8 DPU performance synthesis completed."
puts "Reports written to:"
puts "  [file join $REPORT_DIR utilization_posit8.txt]"
puts "  [file join $REPORT_DIR timing_posit8.txt]"