# --------------------------------------------------------------------
# run_sim_posit8.tcl
#
# Run behavioral simulation for Posit8 DPU error analysis.
# --------------------------------------------------------------------

set BASE_DIR [file normalize [file join [file dirname [info script]] ".." ".."]]
set REPO_DIR [file normalize [file join $BASE_DIR ".."]]

set SRC_DIR        [file join $REPO_DIR "DPU_Performance_Area_Comparison" "src"]
set TB_DIR         [file join $BASE_DIR "testbenches" "posit8"]
set PROJECT_DIR    [file join $BASE_DIR "vivado" "projects" "posit8_error_sim_project"]

set INPUT_FILE     [file normalize [file join $BASE_DIR "data" "dnn_random_10k" "vectors" "posit8_vectors.txt"]]
set OUTPUT_FILE    [file normalize [file join $BASE_DIR "data" "dnn_random_10k" "hw_outputs" "posit8_hw_outputs.txt"]]

set PART_NAME "xc7a100tcsg324-1"

close_project -quiet
create_project -force posit8_error_sim_project $PROJECT_DIR -part $PART_NAME

set posit8_main_files [glob -nocomplain [file join $SRC_DIR "posit8" "*.vhd"]]
set posit8_helper_files [glob -nocomplain [file join $SRC_DIR "posit8" "needed_flopoco_files" "*.vhd"]]

if {[llength $posit8_main_files] > 0} {
    add_files -fileset sources_1 -norecurse $posit8_main_files
    set_property library posit8_lib [get_files $posit8_main_files]
    set_property file_type {VHDL 2008} [get_files $posit8_main_files]
}

if {[llength $posit8_helper_files] > 0} {
    add_files -fileset sources_1 -norecurse $posit8_helper_files
    set_property library posit8_lib [get_files $posit8_helper_files]
    set_property file_type {VHDL 2008} [get_files $posit8_helper_files]
}

add_files -fileset sim_1 -norecurse [file join $TB_DIR "POSIT8DPU_error_TB.vhd"]
set_property file_type {VHDL 2008} [get_files [file join $TB_DIR "POSIT8DPU_error_TB.vhd"]]

set_property top POSIT8DPU_error_TB [get_filesets sim_1]

set_property generic "INPUT_FILE=$INPUT_FILE OUTPUT_FILE=$OUTPUT_FILE" [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

puts "Posit8 error-analysis simulation completed."
puts "Input file:"
puts "  $INPUT_FILE"
puts "Output file:"
puts "  $OUTPUT_FILE"