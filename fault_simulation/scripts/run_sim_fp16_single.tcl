# --------------------------------------------------------------------
# run_sim_fp16_single.tcl
#
# Run one FP16 DPU simulation.
#
# Usage:
#
# Golden:
#   source fault_simulation/scripts/run_sim_fp16_single.tcl
#   with argv = {golden -1 -1 -1}
#
# Fault:
#   source fault_simulation/scripts/run_sim_fp16_single.tcl
#   with argv = {fault 0 0 0}
#
# argv:
#   MODE FAULT_VECTOR FAULT_TARGET_ID FAULT_BIT
#
# MODE:
#   golden
#   fault
# --------------------------------------------------------------------

if {$argc != 4} {
    puts "ERROR: expected 4 arguments:"
    puts "  MODE FAULT_VECTOR FAULT_TARGET_ID FAULT_BIT"
    puts ""
    puts "Examples:"
    puts "  golden -1 -1 -1"
    puts "  fault 0 0 0"
    return -code error "Stopping script without closing Vivado"
}

set MODE            [lindex $argv 0]
set FAULT_VECTOR    [lindex $argv 1]
set FAULT_TARGET_ID [lindex $argv 2]
set FAULT_BIT       [lindex $argv 3]

if {$MODE eq "golden"} {
    set FAULT_ENABLE false
} elseif {$MODE eq "fault"} {
    set FAULT_ENABLE true
} else {
    puts "ERROR: MODE must be golden or fault"
    return -code error "Stopping script without closing Vivado"
}

# --------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------

set SCRIPT_DIR [file normalize [file dirname [info script]]]
set FAULT_ROOT [file normalize [file join $SCRIPT_DIR ".."]]
set REPO_DIR   [file normalize [file join $FAULT_ROOT ".."]]

set SRC_DIR [file join $REPO_DIR \
    "DPU_Performance_Area_Comparison" "src"]

set TB_DIR [file join $FAULT_ROOT "rtl" "fp16"]

set PROJECT_DIR [file join $FAULT_ROOT \
    "vivado" "fp16_single_sim_project"]

set INPUT_FILE [file normalize \
    [file join $FAULT_ROOT \
    "data" "fp16" "fp16_vectors_100.txt"]]

set GOLDEN_OUTPUT_DIR [file normalize \
    [file join $FAULT_ROOT \
    "results" "fp16_golden_outputs"]]

set FAULT_OUTPUT_DIR [file normalize \
    [file join $FAULT_ROOT \
    "results" "fp16_fault_outputs"]]

file mkdir $GOLDEN_OUTPUT_DIR
file mkdir $FAULT_OUTPUT_DIR

if {$MODE eq "golden"} {
    set OUTPUT_FILE [file normalize \
        [file join $GOLDEN_OUTPUT_DIR \
        "fp16_golden_100.txt"]]
} else {
    set OUTPUT_FILE [file normalize \
        [file join $FAULT_OUTPUT_DIR \
        "fp16_fault_v${FAULT_VECTOR}_t${FAULT_TARGET_ID}_b${FAULT_BIT}.txt"]]
}

set PART_NAME "xc7a100tcsg324-1"

# --------------------------------------------------------------------
# Create project
# --------------------------------------------------------------------

close_project -quiet

create_project -force fp16_single_sim_project \
    $PROJECT_DIR \
    -part $PART_NAME

# --------------------------------------------------------------------
# Add FP16 DPU and helper files
# --------------------------------------------------------------------

set fp16_main_files [glob -nocomplain \
    [file join $SRC_DIR "fp16" "*.vhd"]]

set fp16_helper_files [glob -nocomplain \
    [file join $SRC_DIR "fp16" "needed_flopoco_files" "*.vhd"]]

if {[llength $fp16_main_files] == 0} {
    puts "ERROR: no FP16 main VHDL files found in:"
    puts "  [file join $SRC_DIR fp16]"
    return -code error "Stopping script without closing Vivado"
}

add_files -fileset sources_1 -norecurse $fp16_main_files
set_property library fp16_lib [get_files $fp16_main_files]
set_property file_type {VHDL 2008} [get_files $fp16_main_files]

if {[llength $fp16_helper_files] > 0} {
    add_files -fileset sources_1 -norecurse $fp16_helper_files
    set_property library fp16_lib [get_files $fp16_helper_files]
    set_property file_type {VHDL 2008} [get_files $fp16_helper_files]
}

# --------------------------------------------------------------------
# Add testbench
# --------------------------------------------------------------------

set FAULT_TB_FILE [file join $TB_DIR "FP16_fault_tb.vhd"]

if {![file exists $FAULT_TB_FILE]} {
    puts "ERROR: missing testbench:"
    puts "  $FAULT_TB_FILE"
    return -code error "Stopping script without closing Vivado"
}

add_files -fileset sim_1 -norecurse $FAULT_TB_FILE
set_property file_type {VHDL 2008} [get_files $FAULT_TB_FILE]
set_property top FP16_fault_tb [get_filesets sim_1]

set_property generic "\
INPUT_FILE=$INPUT_FILE \
OUTPUT_FILE=$OUTPUT_FILE \
FAULT_ENABLE=$FAULT_ENABLE \
FAULT_VECTOR=$FAULT_VECTOR \
FAULT_TARGET_ID=$FAULT_TARGET_ID \
FAULT_BIT=$FAULT_BIT" \
[get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "------------------------------------------------------------"
puts "Running FP16 single simulation"
puts "  MODE            = $MODE"
puts "  INPUT_FILE      = $INPUT_FILE"
puts "  OUTPUT_FILE     = $OUTPUT_FILE"
puts "  FAULT_ENABLE    = $FAULT_ENABLE"
puts "  FAULT_VECTOR    = $FAULT_VECTOR"
puts "  FAULT_TARGET_ID = $FAULT_TARGET_ID"
puts "  FAULT_BIT       = $FAULT_BIT"
puts "------------------------------------------------------------"

launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

puts "------------------------------------------------------------"
puts "Simulation completed."
puts "Output:"
puts "  $OUTPUT_FILE"
puts "------------------------------------------------------------"