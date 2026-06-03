# --------------------------------------------------------------------
# run_sim_fp16.tcl
#
# Run behavioral simulation for FP16 DPU error analysis.
#
# Input:
#   DPU_Error_Analysis/data/dnn_random_10k/vectors/fp16_vectors.txt
#
# Output:
#   DPU_Error_Analysis/data/dnn_random_10k/hw_outputs/fp16_hw_outputs.txt
# --------------------------------------------------------------------

set BASE_DIR [file normalize [file join [file dirname [info script]] ".." ".."]]
set REPO_DIR [file normalize [file join $BASE_DIR ".."]]

set SRC_DIR        [file join $REPO_DIR "DPU_Performance_Area_Comparison" "src"]
set TB_DIR         [file join $BASE_DIR "testbenches" "fp16"]
set PROJECT_DIR    [file join $BASE_DIR "vivado" "projects" "fp16_error_sim_project"]

set INPUT_FILE     [file normalize [file join $BASE_DIR "data" "dnn_random_10k" "vectors" "fp16_vectors.txt"]]
set OUTPUT_FILE    [file normalize [file join $BASE_DIR "data" "dnn_random_10k" "hw_outputs" "fp16_hw_outputs.txt"]]

set PART_NAME "xc7a100tcsg324-1"

close_project -quiet
create_project -force fp16_error_sim_project $PROJECT_DIR -part $PART_NAME

# --------------------------------------------------------------------
# Add FP16 DPU and helper files to fp16_lib
# --------------------------------------------------------------------
set fp16_main_files [glob -nocomplain [file join $SRC_DIR "fp16" "*.vhd"]]
set fp16_helper_files [glob -nocomplain [file join $SRC_DIR "fp16" "needed_flopoco_files" "*.vhd"]]

if {[llength $fp16_main_files] > 0} {
    add_files -fileset sources_1 -norecurse $fp16_main_files
    set_property library fp16_lib [get_files $fp16_main_files]
    set_property file_type {VHDL 2008} [get_files $fp16_main_files]
}

if {[llength $fp16_helper_files] > 0} {
    add_files -fileset sources_1 -norecurse $fp16_helper_files
    set_property library fp16_lib [get_files $fp16_helper_files]
    set_property file_type {VHDL 2008} [get_files $fp16_helper_files]
}

# --------------------------------------------------------------------
# Add testbench to simulation fileset
# --------------------------------------------------------------------
add_files -fileset sim_1 -norecurse [file join $TB_DIR "FP16DPU_error_tb.vhd"]
set_property file_type {VHDL 2008} [get_files [file join $TB_DIR "FP16DPU_error_tb.vhd"]]

set_property top FP16_error_tb [get_filesets sim_1]

# Pass file paths to VHDL testbench generics
set_property generic "INPUT_FILE=$INPUT_FILE OUTPUT_FILE=$OUTPUT_FILE" [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

puts "FP16 error-analysis simulation completed."
puts "Input file:"
puts "  $INPUT_FILE"
puts "Output file:"
puts "  $OUTPUT_FILE"