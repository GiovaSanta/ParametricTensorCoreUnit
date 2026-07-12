# LNS16 100-vector input stuck-at campaign

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set TESI_ROOT [file normalize [file join $SCRIPT_DIR ../../..]]
set CAMPAIGN_DIR $SCRIPT_DIR

set RTL_DIR [file join $TESI_ROOT DPU_Performance_Area_Comparison src lns16]
set SUBCORR_FILE [file join $RTL_DIR needed_flopoco_files LNSSubCorrectionPkg.vhd]
set ADD_FILE [file join $RTL_DIR needed_flopoco_files LNSAddSub_4_9_comb.vhd]
set MUL_FILE [file join $RTL_DIR needed_flopoco_files LNSMul_4_9_comb.vhd]
set DPU_FILE [file join $RTL_DIR LNS16_4_9_DPU.vhd]
set TB_FILE [file join $CAMPAIGN_DIR LNS16_fault_campaign_100vectors_TB.vhd]

set GOLDEN_INPUT [file join $CAMPAIGN_DIR generated_lns16_vectors_100 lns16_vectors.txt]
set FAULT_INPUT [file join $CAMPAIGN_DIR lns16_input_faults_100 fault_vectors.txt]

set RESULTS_DIR [file join $CAMPAIGN_DIR lns16_results_100]
set GOLDEN_OUTPUT [file join $RESULTS_DIR golden_results.txt]
set FAULT_OUTPUT [file join $RESULTS_DIR faulty_results.txt]

set PROJECT_DIR [file join $CAMPAIGN_DIR vivado projects lns16_100v_proj]
set FPGA_PART "xc7z020clg400-1"

proc require_file {label path} {
    puts "$label: $path"
    if {![file exists $path]} {
        error "Required file not found: $path"
    }
}

puts ""
puts "Checking LNS16 100-vector campaign paths..."
puts "SCRIPT_DIR: $SCRIPT_DIR"
puts "TESI_ROOT:  $TESI_ROOT"
puts "RTL_DIR:    $RTL_DIR"
puts ""

require_file "SUBCORR_FILE" $SUBCORR_FILE
require_file "ADD_FILE" $ADD_FILE
require_file "MUL_FILE" $MUL_FILE
require_file "DPU_FILE" $DPU_FILE
require_file "TB_FILE" $TB_FILE
require_file "GOLDEN_INPUT" $GOLDEN_INPUT
require_file "FAULT_INPUT" $FAULT_INPUT

file mkdir $RESULTS_DIR
file mkdir [file dirname $PROJECT_DIR]

create_project -force lns16_100v_proj $PROJECT_DIR -part $FPGA_PART
set_property target_language VHDL [current_project]

add_files -norecurse $SUBCORR_FILE
add_files -norecurse $ADD_FILE
add_files -norecurse $MUL_FILE
add_files -norecurse $DPU_FILE

foreach source_file [list $SUBCORR_FILE $ADD_FILE $MUL_FILE $DPU_FILE] {
    set_property library lns16_lib [get_files $source_file]
    set_property file_type {VHDL 2008} [get_files $source_file]
}

add_files -fileset sim_1 -norecurse $TB_FILE
set_property file_type {VHDL 2008} [get_files $TB_FILE]
set_property top LNS16_fault_campaign_100vectors_TB [get_filesets sim_1]

set_property generic [join [list \
    "GOLDEN_INPUT_FILE=$GOLDEN_INPUT" \
    "FAULT_INPUT_FILE=$FAULT_INPUT" \
    "GOLDEN_OUTPUT_FILE=$GOLDEN_OUTPUT" \
    "FAULT_OUTPUT_FILE=$FAULT_OUTPUT"] " "] [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -simset sim_1 -mode behavioral
run all

close_sim
close_project

puts ""
puts "LNS16 100-vector campaign completed."
puts "Golden outputs: $GOLDEN_OUTPUT"
puts "Fault outputs:  $FAULT_OUTPUT"
