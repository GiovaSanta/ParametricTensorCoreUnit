# DPU Performance and Area Comparison

This folder contains the synthesis-based performance and area/resource evaluation of the implemented Dot Product Units (DPUs) (each DPU targeting a distinct numerical format).

Each DPU was evaluated using a registered wrapper with the following structure in the Vivado Project:

```text
input registers -> combinational DPU -> output register


