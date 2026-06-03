# --------------------------------------------------------------------
# run_synth_lns16.tcl
#
# Synthesize the registered LNS16 DPU performance wrapper.
#
# Reports generated:
#   reports/lns16/utilization_lns16.txt
#   reports/lns16/timing_lns16.txt
# --------------------------------------------------------------------

# Change this if your board/FPGA part is different
set PART_NAME "xc7a100tcsg324-1"

# Base folder: DPU_Performance_Comparison
set BASE_DIR [file normalize [file join [file dirname [info script]] ".."]]

set SRC_DIR      [file join $BASE_DIR "src"]
set REPORT_DIR   [file join $BASE_DIR "reports" "lns16"]
set CONSTR_FILE  [file join $BASE_DIR "vivado" "constraints" "dpu_perf_clock.xdc"]

file mkdir $REPORT_DIR

# Clean previous in-memory design and create project
close_project -quiet
create_project -force lns16_dpu_perf_project [file join $BASE_DIR "vivado" "lns16_dpu_perf_project"] -part $PART_NAME

# --------------------------------------------------------------------
# Add LNS16 DPU files into dedicated library
# --------------------------------------------------------------------
set lns16_main_files [glob -nocomplain [file join $SRC_DIR "lns16" "*.vhd"]]
set lns16_helper_files [glob -nocomplain [file join $SRC_DIR "lns16" "needed_flopoco_files" "*.vhd"]]

if {[llength $lns16_main_files] > 0} {
    add_files -fileset sources_1 -norecurse $lns16_main_files
    set_property library lns16_lib [get_files $lns16_main_files]
}

if {[llength $lns16_helper_files] > 0} {
    add_files -fileset sources_1 -norecurse $lns16_helper_files
    set_property library lns16_lib [get_files $lns16_helper_files]
}

# --------------------------------------------------------------------
# Add wrapper into default work library
# --------------------------------------------------------------------
add_files -fileset sources_1 -norecurse [file join $SRC_DIR "wrappers" "LNS16_DPU_perf_top.vhd"]

# --------------------------------------------------------------------
# Add clock constraint
# --------------------------------------------------------------------
add_files -fileset constrs_1 -norecurse $CONSTR_FILE

# Set top module
set_property top LNS16_DPU_perf_top [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

# --------------------------------------------------------------------
# Run synthesis
# --------------------------------------------------------------------
reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
open_run synth_1

# --------------------------------------------------------------------
# Generate reports
# --------------------------------------------------------------------
report_utilization -file [file join $REPORT_DIR "utilization_lns16.txt"]
report_timing_summary -file [file join $REPORT_DIR "timing_lns16.txt"]

puts "LNS16 DPU performance synthesis completed."
puts "Reports written to:"
puts "  [file join $REPORT_DIR utilization_lns16.txt]"
puts "  [file join $REPORT_DIR timing_lns16.txt]"