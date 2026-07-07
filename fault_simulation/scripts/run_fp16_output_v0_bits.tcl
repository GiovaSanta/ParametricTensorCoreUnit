# --------------------------------------------------------------------
# run_fp16_output_v0_bits.tcl
#
# Mini-campaign:
#   1 golden run
#   16 faulty runs
#
# Faults:
#   vector_id = 0
#   target_id = 0  ;# R output
#   bit_id    = 0..15
# --------------------------------------------------------------------

cd C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi

puts "============================================================"
puts "FP16 mini fault campaign: vector 0, output R, bits 0..15"
puts "============================================================"

# Golden run
set argc 4
set argv {golden -1 -1 -1}
source fault_simulation/scripts/run_sim_fp16_single.tcl

# Fault runs
for {set bit 0} {$bit < 16} {incr bit} {
    puts "============================================================"
    puts "Running fault: vector=0 target=R bit=$bit"
    puts "============================================================"

    set argc 4
    set argv [list fault 0 0 $bit]
    source fault_simulation/scripts/run_sim_fp16_single.tcl
}

puts "============================================================"
puts "FP16 mini fault campaign completed."
puts "============================================================"