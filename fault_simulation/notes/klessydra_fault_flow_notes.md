# Klessydra / FlexGripPlus Fault Simulation Flow Notes

The supervisor-provided fault simulation flow is used as
methodological reference for the DPU-level resiliency evaluation.

## Reference scripts

- Script_Fault_Simulator_2021.py
  Main fault campaign driver.

- import_project.py
  Golden simulation execution and per-fault simulation logic.

- afs_func.py
  Generation of simulator commands for fault injection.

- fault_analysis.py
  Post-processing and classification of fault effects.

- filter_fault_file.sh
  Filtering/reduction of fault-list entries.

## Original conceptual flow

1. Select application and simulation environment.
2. Load a fault list.
3. Run golden simulation.
4. Run one faulty simulation per fault.
5. Compare faulty output with golden output.
6. Classify fault effects.
7. Generate final result files.

## Classification idea

The original flow uses categories such as:

- ND
- SDC
- Halt
- Time out

## DPU-level adaptation

In this thesis work, the same methodology is adapted to
standalone numerical DPUs.

The DPU-level flow is:

1. Select numerical format.
2. Load DPU input vectors.
3. Run golden DPU evaluation.
4. Generate DPU-level bit-flip fault list.
5. Run faulty DPU evaluations.
6. Compare golden and faulty outputs.
7. Classify faults as:
   - ND / masked
   - SDC
   - catastrophic numerical error
   - simulation error / timeout
8. Export CSV files and summary tables.

The purpose is not to reproduce the full processor-level
fault campaign, but to preserve the same golden-run,
fault-list, faulty-run, comparison, and classification structure
at DPU level.