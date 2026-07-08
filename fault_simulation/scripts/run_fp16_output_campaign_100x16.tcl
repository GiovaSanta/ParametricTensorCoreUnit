# --------------------------------------------------------------------
# run_fp16_output_campaign_100x16.tcl
#
# Klessydra-like FP16 DPU output-fault campaign.
#
# Flow:
#   1. generate fault list
#   2. run golden simulation once
#   3. run one faulty simulation per fault
#
# Campaign:
#   vectors = 0..99
#   target  = R output, target_id = 0
#   bits    = 0..15
#   total   = 1600 faults
#
# Run from Vivado Tcl Console:
#
#   cd C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi
#   source fault_simulation/scripts/run_fp16_output_campaign_100x16.tcl
# --------------------------------------------------------------------

set REPO_DIR [file normalize "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi"]
cd $REPO_DIR

set FAULT_ROOT [file join $REPO_DIR "fault_simulation"]

set SINGLE_SCRIPT [file join $FAULT_ROOT "scripts" "run_sim_fp16_single.tcl"]

set FAULT_LIST_DIR [file join $FAULT_ROOT "fault_lists"]
set GOLDEN_OUTPUT_DIR [file join $FAULT_ROOT "results" "fp16_golden_outputs"]
set FAULT_OUTPUT_DIR [file join $FAULT_ROOT "results" "fp16_fault_outputs"]

file mkdir $FAULT_LIST_DIR
file mkdir $GOLDEN_OUTPUT_DIR
file mkdir $FAULT_OUTPUT_DIR

set FAULT_LIST_FILE [file join $FAULT_LIST_DIR "fp16_output_faults_100x16.csv"]
set GOLDEN_FILE [file join $GOLDEN_OUTPUT_DIR "fp16_golden_100.txt"]

set NUM_VECTORS 100
set TARGET_ID 0
set TARGET_NAME "R"
set NUM_BITS 16

puts "============================================================"
puts "FP16 output-fault campaign"
puts "  vectors      = 0..[expr {$NUM_VECTORS - 1}]"
puts "  target       = $TARGET_NAME"
puts "  target_id    = $TARGET_ID"
puts "  bits         = 0..[expr {$NUM_BITS - 1}]"
puts "  total faults = [expr {$NUM_VECTORS * $NUM_BITS}]"
puts "============================================================"

# --------------------------------------------------------------------
# 1. Generate fault list
# --------------------------------------------------------------------

set fl [open $FAULT_LIST_FILE "w"]
puts $fl "fault_id,format,target_id,target_name,vector_id,bit_id,fault_type"

set fault_id 0

for {set vector_id 0} {$vector_id < $NUM_VECTORS} {incr vector_id} {
    for {set bit_id 0} {$bit_id < $NUM_BITS} {incr bit_id} {
        puts $fl "$fault_id,FP16,$TARGET_ID,$TARGET_NAME,$vector_id,$bit_id,bflip"
        incr fault_id
    }
}

close $fl

puts "Fault list generated:"
puts "  $FAULT_LIST_FILE"

# --------------------------------------------------------------------
# 2. Golden run
# --------------------------------------------------------------------

if {[file exists $GOLDEN_FILE]} {
    puts "Golden output already exists, skipping golden run:"
    puts "  $GOLDEN_FILE"
} else {
    puts "Running golden simulation..."

    set argc 4
    set argv {golden -1 -1 -1}

    if {[catch {source $SINGLE_SCRIPT} err]} {
        puts "ERROR during golden simulation:"
        puts $err
        return -code error $err
    }
}

# --------------------------------------------------------------------
# 3. Fault campaign
# --------------------------------------------------------------------

set completed 0
set skipped 0
set failed 0

for {set vector_id 0} {$vector_id < $NUM_VECTORS} {incr vector_id} {
    for {set bit_id 0} {$bit_id < $NUM_BITS} {incr bit_id} {

        set output_file [file join $FAULT_OUTPUT_DIR \
            "fp16_fault_v${vector_id}_t${TARGET_ID}_b${bit_id}.txt"]

        if {[file exists $output_file]} {
            incr skipped
            continue
        }

        puts "------------------------------------------------------------"
        puts "Fault experiment:"
        puts "  vector_id = $vector_id"
        puts "  target    = $TARGET_NAME"
        puts "  bit_id    = $bit_id"
        puts "  output    = $output_file"
        puts "------------------------------------------------------------"

        set argc 4
        set argv [list fault $vector_id $TARGET_ID $bit_id]

        if {[catch {source $SINGLE_SCRIPT} err]} {
            puts "ERROR during faulty simulation:"
            puts "  vector_id = $vector_id"
            puts "  bit_id    = $bit_id"
            puts $err
            incr failed
            return -code error $err
        }

        incr completed
    }
}

puts "============================================================"
puts "FP16 output-fault campaign finished."
puts "  completed newly = $completed"
puts "  skipped existing = $skipped"
puts "  failed           = $failed"
puts "  fault list       = $FAULT_LIST_FILE"
puts "============================================================"