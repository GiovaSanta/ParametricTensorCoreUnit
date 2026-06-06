# FlexGrip Plus Automated TCU Validation Summary

This folder contains an automated validation flow for Tensor Core Unit experiments in the FlexGrip Plus environment.

The flow performs:

1. generation of a new numerical experiment;
2. generation of the corresponding `global_mem.mif`;
3. copying of the selected format configuration files into the FlexGrip testbench;
4. ModelSim simulation execution;
5. extraction of the hardware D matrix from `gpgpu_rdata.log`;
6. decoded numerical comparison against the generated golden reference.

## Validated formats

| Format | A/B width | C/D width | D start address | Reference type | Status |
|---|---:|---:|---:|---|---|
| FP8 | 8-bit | 8-bit | 0x300 | one-shot decoded reference | Validated |
| FP16 | 16-bit | 16-bit | 0x600 | one-shot decoded reference | Validated |
| FP32 | 32-bit | 32-bit | 0xC00 | one-shot decoded reference | Validated |
| Posit8 | 8-bit | 8-bit | 0x300 | one-shot decoded reference | Validated |
| Posit16 | 16-bit | 16-bit | 0x600 | one-shot decoded reference | Validated |
| Posit32 | 32-bit | 32-bit | 0xC00 | one-shot decoded reference | Validated |
| LNS16 | 16-bit | 16-bit | 0x600 | one-shot decoded reference | Validated |
| FXP8_16 | 8-bit | 16-bit | 0x400 | full-precision real reference before quantization | Validated |
| FXP16_32 | 16-bit | 32-bit | 0x800 | full-precision real reference before quantization | Validated |
| INT8_16 | 8-bit | 16-bit | 0x400 | one-shot integer reference | Validated |
| INT16_32 | 16-bit | 32-bit | 0x800 | one-shot integer reference | Validated |

## Main runner

The main script is:

```bash
tools/run_flexgrip_tcu_experiment.py