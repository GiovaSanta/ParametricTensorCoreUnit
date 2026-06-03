# --------------------------------------------------------------------
# run_sim_fp32.tcl
#
# Run behavioral simulation for FP32 DPU error analysis.
# --------------------------------------------------------------------

set BASE_DIR [file normalize [file join [file dirname [info script]] ".." ".."]]
set REPO_DIR [file normalize [file join $BASE_DIR ".."]]

set SRC_DIR        [file join $REPO_DIR "DPU_Performance_Area_Comparison" "src"]
set TB_DIR         [file join $BASE_DIR "testbenches" "fp32"]
set PROJECT_DIR    [file join $BASE_DIR "vivado" "projects" "fp32_error_sim_project"]

set INPUT_FILE     [file normalize [file join $BASE_DIR "data" "dnn_random_10k" "vectors" "fp32_vectors.txt"]]
set OUTPUT_FILE    [file normalize [file join $BASE_DIR "data" "dnn_random_10k" "hw_outputs" "fp32_hw_outputs.txt"]]

set PART_NAME "xc7a100tcsg324-1"

close_project -quiet
create_project -force fp32_error_sim_project $PROJECT_DIR -part $PART_NAME

set fp32_main_files [glob -nocomplain [file join $SRC_DIR "fp32" "*.vhd"]]
set fp32_helper_files [glob -nocomplain [file join $SRC_DIR "fp32" "needed_flopoco_files" "*.vhd"]]

if {[llength $fp32_main_files] > 0} {
    add_files -fileset sources_1 -norecurse $fp32_main_files
    set_property library fp32_lib [get_files $fp32_main_files]
    set_property file_type {VHDL 2008} [get_files $fp32_main_files]
}

if {[llength $fp32_helper_files] > 0} {
    add_files -fileset sources_1 -norecurse $fp32_helper_files
    set_property library fp32_lib [get_files $fp32_helper_files]
    set_property file_type {VHDL 2008} [get_files $fp32_helper_files]
}

add_files -fileset sim_1 -norecurse [file join $TB_DIR "FP32DPU_error_tb.vhd"]
set_property file_type {VHDL 2008} [get_files [file join $TB_DIR "FP32DPU_error_tb.vhd"]]

set_property top FP32_error_tb [get_filesets sim_1]

set_property generic "INPUT_FILE=$INPUT_FILE OUTPUT_FILE=$OUTPUT_FILE" [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

puts "FP32 error-analysis simulation completed."
puts "Input file:"
puts "  $INPUT_FILE"
puts "Output file:"
puts "  $OUTPUT_FILE"