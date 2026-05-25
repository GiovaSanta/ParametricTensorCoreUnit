# TCU pipeline stall milestone

## Goal

Make the HMMA / TCU instruction behave as a blocking long-latency instruction while the tensor core wrapper is executing.

## Achieved behavior

The TCU branch now:

1. Collects the HMMA fragments from all 16 harts.
2. Uses `tcu_lane_valid_s` to track which harts have delivered their operand fragments.
3. Uses a predicted next-valid vector, `tcu_lane_valid_next_s`, to detect when the current HMMA request completes the full 16-lane group.
4. Asserts `core_busy_TCU` early enough to stall the pipeline before the instruction after HMMA enters IE.
5. Keeps `instr_word_IE`, `pc_IE`, and `harc_EXEC` stable during the TCU busy window.
6. Allows the next instruction to enter only after the TCU controller reaches release.

## Main signals

- `busy_TCU`: indicates that the TCU controller is active.
- `core_busy_TCU`: indicates that the core/pipeline must stall.
- `tcu_lane_valid_s`: registered valid-lane vector.
- `tcu_lane_valid_next_s`: predicted valid-lane vector including the current incoming HMMA request.
- `tcu_all_lanes_valid_next_s`: used to assert the stall early enough.
- `tcu_state_s`: TCU controller FSM state.

## Verified in waveform

The waveform confirmed that:

- `core_busy_TCU` rises when the final hart fragment is being collected.
- `busy_ID`, `halt_IE`, and `halt_LSU` react to the TCU stall.
- `instr_word_IE` remains on the HMMA instruction during TCU execution.
- The following instruction enters IE only after TCU release.
- The W0/W1 FP16 outputs remain consistent with the previous FlexGrip-compatible milestone.

## Current limitation

The TCU result is not yet written back to the register file.

Future work should add a TCU writeback phase, likely extending the FSM with states such as:

- `TCU_WRITEBACK`
- `TCU_WRITEBACK_DRAIN`
- `TCU_RELEASE`

The release phase should eventually happen after writeback, not immediately after wrapper done.
