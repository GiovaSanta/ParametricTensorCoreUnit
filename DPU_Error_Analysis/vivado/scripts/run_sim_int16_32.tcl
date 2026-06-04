# --------------------------------------------------------------------
# run_sim_int16_32.tcl
#
# Run behavioral simulation for INT16_32 DPU error analysis.
# --------------------------------------------------------------------

set BASE_DIR [file normalize [file join [file dirname [info script]] ".." ".."]]
set REPO_DIR [file normalize [file join $BASE_DIR ".."]]

set SRC_DIR        [file join $REPO_DIR "DPU_Performance_Area_Comparison" "src"]
set TB_DIR         [file join $BASE_DIR "testbenches" "int16_32"]
set PROJECT_DIR    [file join $BASE_DIR "vivado" "projects" "int16_32_error_sim_project"]

set INPUT_FILE     [file normalize [file join $BASE_DIR "data" "dnn_random_10k" "vectors" "int16_32_vectors.txt"]]
set OUTPUT_FILE    [file normalize [file join $BASE_DIR "data" "dnn_random_10k" "hw_outputs" "int16_32_hw_outputs.txt"]]

set PART_NAME "xc7a100tcsg324-1"

close_project -quiet
create_project -force int16_32_error_sim_project $PROJECT_DIR -part $PART_NAME

set int16_32_helper_files [glob -nocomplain [file join $SRC_DIR "int16_32" "needed_flopoco_files" "*.vhd"]]
set int16_32_main_files   [glob -nocomplain [file join $SRC_DIR "int16_32" "*.vhd"]]

if {[llength $int16_32_helper_files] > 0} {
    add_files -fileset sources_1 -norecurse $int16_32_helper_files
    set_property library int16_32_lib [get_files $int16_32_helper_files]
    set_property file_type {VHDL 2008} [get_files $int16_32_helper_files]
}

if {[llength $int16_32_main_files] > 0} {
    add_files -fileset sources_1 -norecurse $int16_32_main_files
    set_property library int16_32_lib [get_files $int16_32_main_files]
    set_property file_type {VHDL 2008} [get_files $int16_32_main_files]
}

add_files -fileset sim_1 -norecurse [file join $TB_DIR "INT16_32DPU_error_TB.vhd"]
set_property file_type {VHDL 2008} [get_files [file join $TB_DIR "INT16_32DPU_error_TB.vhd"]]

set_property top INT16_32DPU_error_TB [get_filesets sim_1]
set_property generic "INPUT_FILE=$INPUT_FILE OUTPUT_FILE=$OUTPUT_FILE" [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

puts "INT16_32 error-analysis simulation completed."
puts "Input file:"
puts "  $INPUT_FILE"
puts "Output file:"
puts "  $OUTPUT_FILE"
