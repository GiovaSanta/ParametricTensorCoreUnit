# --------------------------------------------------------------------
# run_sim_lns16.tcl
#
# Run behavioral simulation for LNS16 4_9 DPU error analysis.
# --------------------------------------------------------------------

set BASE_DIR [file normalize [file join [file dirname [info script]] ".." ".."]]
set REPO_DIR [file normalize [file join $BASE_DIR ".."]]

set SRC_DIR        [file join $REPO_DIR "DPU_Performance_Area_Comparison" "src"]
set TB_DIR         [file join $BASE_DIR "testbenches" "lns16"]
set PROJECT_DIR    [file join $BASE_DIR "vivado" "projects" "lns16_error_sim_project"]

set INPUT_FILE     [file normalize [file join $BASE_DIR "data" "dnn_random_10k" "vectors" "lns16_vectors.txt"]]
set OUTPUT_FILE    [file normalize [file join $BASE_DIR "data" "dnn_random_10k" "hw_outputs" "lns16_hw_outputs.txt"]]

set PART_NAME "xc7a100tcsg324-1"

close_project -quiet
create_project -force lns16_error_sim_project $PROJECT_DIR -part $PART_NAME

# For LNS16, compile everything into default work library.
# This is intentional because LNS16_4_9_DPU internally instantiates:
#   entity work.LNSMul_4_9_comb
#   entity work.LNSAddSub_4_9_comb

set lns16_helper_files [glob -nocomplain [file join $SRC_DIR "lns16" "needed_flopoco_files" "*.vhd"]]
set lns16_main_files   [glob -nocomplain [file join $SRC_DIR "lns16" "*.vhd"]]

if {[llength $lns16_helper_files] > 0} {
    add_files -fileset sources_1 -norecurse $lns16_helper_files
    set_property file_type {VHDL 2008} [get_files $lns16_helper_files]
}

if {[llength $lns16_main_files] > 0} {
    add_files -fileset sources_1 -norecurse $lns16_main_files
    set_property file_type {VHDL 2008} [get_files $lns16_main_files]
}

add_files -fileset sim_1 -norecurse [file join $TB_DIR "LNS16DPU_error_TB.vhd"]
set_property file_type {VHDL 2008} [get_files [file join $TB_DIR "LNS16DPU_error_TB.vhd"]]

set_property top LNS16DPU_error_TB [get_filesets sim_1]

set_property generic "INPUT_FILE=$INPUT_FILE OUTPUT_FILE=$OUTPUT_FILE" [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

puts "LNS16 error-analysis simulation completed."
puts "Input file:"
puts "  $INPUT_FILE"
puts "Output file:"
puts "  $OUTPUT_FILE"