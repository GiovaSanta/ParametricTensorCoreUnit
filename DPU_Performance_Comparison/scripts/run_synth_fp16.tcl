# --------------------------------------------------------------------
# run_synth_fp16.tcl
#
# Synthesize the registered FP16 DPU performance wrapper.
#
# Reports generated:
#   reports/fp16/utilization_fp16.txt
#   reports/fp16/timing_fp16.txt
# --------------------------------------------------------------------

# Change this if your board/FPGA part is different
set PART_NAME "xc7a100tcsg324-1"

# Base folder: DPU_Performance_Comparison
set BASE_DIR [file normalize [file join [file dirname [info script]] ".."]]

set SRC_DIR      [file join $BASE_DIR "src"]
set REPORT_DIR   [file join $BASE_DIR "reports" "fp16"]
set CONSTR_FILE  [file join $BASE_DIR "vivado" "constraints" "dpu_perf_clock.xdc"]

file mkdir $REPORT_DIR

# Clean previous in-memory design
close_project -quiet
create_project -force fp16_dpu_perf_project [file join $BASE_DIR "vivado" "fp16_dpu_perf_project"] -part $PART_NAME

# --------------------------------------------------------------------
# Add FP16 DPU files into dedicated library
# --------------------------------------------------------------------
set fp16_main_files [glob [file join $SRC_DIR "fp16" "*.vhd"]]
set fp16_helper_files [glob [file join $SRC_DIR "fp16" "needed_flopoco_files" "*.vhd"]]

add_files -fileset sources_1 -norecurse $fp16_main_files
add_files -fileset sources_1 -norecurse $fp16_helper_files

set_property library fp16_lib [get_files $fp16_main_files]
set_property library fp16_lib [get_files $fp16_helper_files]

# --------------------------------------------------------------------
# Add wrapper into default work library
# --------------------------------------------------------------------
add_files -fileset sources_1 -norecurse [file join $SRC_DIR "wrappers" "FP16_DPU_perf_top.vhd"]

# --------------------------------------------------------------------
# Add clock constraint
# --------------------------------------------------------------------
add_files -fileset constrs_1 -norecurse $CONSTR_FILE

# Set top module
set_property top FP16_DPU_perf_top [current_fileset]

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
report_utilization -file [file join $REPORT_DIR "utilization_fp16.txt"]
report_timing_summary -file [file join $REPORT_DIR "timing_fp16.txt"]

puts "FP16 DPU performance synthesis completed."
puts "Reports written to:"
puts "  [file join $REPORT_DIR utilization_fp16.txt]"
puts "  [file join $REPORT_DIR timing_fp16.txt]"