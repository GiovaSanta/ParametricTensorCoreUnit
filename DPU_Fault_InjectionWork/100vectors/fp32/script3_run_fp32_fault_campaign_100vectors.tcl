# FP32 100-vector input stuck-at campaign

set SCRIPT_DIR [
    file dirname [
        file normalize [info script]
    ]
]

set TESI_ROOT [
    file normalize [
        file join $SCRIPT_DIR ../../..
    ]
]

set CAMPAIGN_DIR $SCRIPT_DIR

set RTL_DIR [
    file join \
        $TESI_ROOT \
        DPU_Performance_Area_Comparison \
        src \
        fp32
]

set FMA_FILE [
    file join \
        $RTL_DIR \
        needed_flopoco_files \
        FMA_FP32e8m23flopoco.vhd
]

set DPU_FILE [
    file join \
        $RTL_DIR \
        DPU_FP32e8m23flopoco.vhd
]

set TB_FILE [
    file join \
        $CAMPAIGN_DIR \
        FP32_fault_campaign_100vectors_TB.vhd
]

set GOLDEN_INPUT [
    file join \
        $CAMPAIGN_DIR \
        generated_fp32_vectors_100 \
        fp32_vectors.txt
]

set FAULT_INPUT [
    file join \
        $CAMPAIGN_DIR \
        fp32_input_faults_100 \
        fault_vectors.txt
]

set RESULTS_DIR [
    file join \
        $CAMPAIGN_DIR \
        fp32_results_100
]

set GOLDEN_OUTPUT [
    file join \
        $RESULTS_DIR \
        golden_results.txt
]

set FAULT_OUTPUT [
    file join \
        $RESULTS_DIR \
        faulty_results.txt
]

set PROJECT_DIR [
    file join \
        $CAMPAIGN_DIR \
        vivado \
        projects \
        fp32_100v_proj
]

set FPGA_PART "xc7z020clg400-1"


proc require_file {label path} {
    puts "$label: $path"

    if {![file exists $path]} {
        error "Required file not found: $path"
    }
}


puts ""
puts "Checking FP32 campaign paths..."
puts "SCRIPT_DIR: $SCRIPT_DIR"
puts "TESI_ROOT:  $TESI_ROOT"
puts "RTL_DIR:    $RTL_DIR"
puts ""

require_file "FMA_FILE"     $FMA_FILE
require_file "DPU_FILE"     $DPU_FILE
require_file "TB_FILE"      $TB_FILE
require_file "GOLDEN_INPUT" $GOLDEN_INPUT
require_file "FAULT_INPUT"  $FAULT_INPUT

file mkdir $RESULTS_DIR
file mkdir [file dirname $PROJECT_DIR]

create_project \
    -force \
    fp32_100v_proj \
    $PROJECT_DIR \
    -part $FPGA_PART

set_property target_language VHDL [current_project]

add_files -norecurse $FMA_FILE
add_files -norecurse $DPU_FILE

foreach source_file [
    list \
        $FMA_FILE \
        $DPU_FILE
] {
    set_property \
        library fp32_lib \
        [get_files $source_file]

    set_property \
        file_type {VHDL 2008} \
        [get_files $source_file]
}

add_files \
    -fileset sim_1 \
    -norecurse \
    $TB_FILE

set_property \
    file_type {VHDL 2008} \
    [get_files $TB_FILE]

set_property \
    top FP32_fault_campaign_100vectors_TB \
    [get_filesets sim_1]

set_property generic [
    join [
        list \
            "GOLDEN_INPUT_FILE=$GOLDEN_INPUT" \
            "FAULT_INPUT_FILE=$FAULT_INPUT" \
            "GOLDEN_OUTPUT_FILE=$GOLDEN_OUTPUT" \
            "FAULT_OUTPUT_FILE=$FAULT_OUTPUT"
    ] " "
] [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation \
    -simset sim_1 \
    -mode behavioral

run all

close_sim
close_project

puts ""
puts "FP32 100-vector campaign completed."
puts "Golden outputs: $GOLDEN_OUTPUT"
puts "Fault outputs:  $FAULT_OUTPUT"
