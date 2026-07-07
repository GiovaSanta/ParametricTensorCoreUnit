# DPU Fault Simulation Methodology

This folder contains the DPU-level fault simulation campaign used
for the resiliency evaluation of the numerical datapaths.

The structure is inspired by the supervisor-provided
Klessydra / FlexGripPlus fault simulation scripts.

The reference flow is based on:

1. golden simulation;
2. fault-list driven injection;
3. faulty simulation;
4. comparison against the golden output;
5. classification of fault effects;
6. final result reporting.

The adapted DPU flow applies the same structure to standalone
numerical DPUs, starting from FP16, Posit16, and LNS16.

Target operation:

R = A0*B0 + A1*B1 + A2*B2 + A3*B3 + C0

Initial fault model:

single-bit transient bit flip.

Initial injection targets:

- final DPU output word;
- input operand words;
- intermediate datapath words, if available.