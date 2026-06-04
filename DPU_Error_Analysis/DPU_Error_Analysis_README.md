# DPU Error Analysis

This folder contains the numerical error-analysis flow used to validate and compare several Dot Product Unit (DPU) implementations across different numerical formats.

The tested operation is the same for every DPU:

```text
R = A0*B0 + A1*B1 + A2*B2 + A3*B3 + C0
```

The experiment uses 10,000 DNN-like random test vectors for each format.

---

## Tested formats

The current set of evaluated formats is:

```text
real value:
FP8
FP16
FP32
Posit8
Posit16
Posit32
LNS16
FXP8_16
FXP16_32

integer:
INT8_16
INT16_32
```

The real-valued formats and integer formats are evaluated with slightly different reference definitions, because their numerical meaning is different.

---

## Reference definition

### Real-valued formats

For these formats:

```text
FP8, FP16, FP32
Posit8, Posit16, Posit32
LNS16
FXP8_16, FXP16_32
```

the error analysis follows this sequence:

```text
1. Python generates high-precision real operands in the selected range.
2. Python computes the ideal full-precision reference:
   reference_real = A0_raw*B0_raw + A1_raw*B1_raw + A2_raw*B2_raw + A3_raw*B3_raw + C0_raw
3. The same operands are encoded/quantized into the target numerical format.
4. The encoded operands are passed to the specific VHDL DPU.
5. The DPU produces an encoded output after simulation in Vivado (dpu src files used are under the folder "DPU_Performance_Area_Comparison/src/" of this repo ).
6. Python decodes the DPU output back into a real value.
7. The decoded hardware result is compared against reference_real value saved.
```

Therefore, the reported error includes the numerical loss due to input quantization, arithmetic rounding, and output representation.

The CSV reference files also store:

```text
quantized_input_reference_real
```

This is the ideal dot-product result computed after decoding the already-quantized inputs. It is useful for debugging implementation correctness, but it is not the main thesis-level numerical error reference.

### Integer-domain formats

For these formats:

```text
INT8_16
INT16_32
```

the error analysis is performed in the integer domain:

```text
1. Python generates integer operands directly.
2. Python computes the exact integer dot-product reference:
   reference_int = A0_int*B0_int + A1_int*B1_int + A2_int*B2_int + A3_int*B3_int + C0_int
3. The integer operands are encoded in two's-complement hexadecimal representation.
4. The encoded operands are passed to the VHDL DPU.
5. The DPU produces an encoded integer output.
6. Python decodes the hardware output back to a signed integer.
7. The decoded hardware integer result is compared against reference_int.
```

For integer formats, a 100% exact match means that the DPU correctly implements the expected integer arithmetic for all tested vectors.

---

## Folder structure

```text
DPU_Error_Analysis/
├── data/
│   └── dnn_random_10k/
│       ├── vectors/       # Input vectors used by VHDL testbenches
│       ├── references/    # Python reference values
│       ├── hw_outputs/    # Hardware simulation outputs
│       └── compared/      # Per-test comparison CSV files
│
├── plots/
│   └── dnn_random_10k/
│       ├── per_format/    # Individual plots for each format
│       └── final/         # Consolidated comparison plots
│
├── reports/
│   └── dnn_random_10k/
│       ├── per_format/    # One summary CSV per format
│       └── dpu_error_summary_all_formats.csv
│
├── scripts/               # Vector generation, comparison, plotting, consolidation
├── testbenches/           # VHDL testbenches for each format
└── vivado/
    └── scripts/           # Vivado Tcl simulation scripts
```

---

## Main scripts

### Vector generation

Real-valued floating-point formats: (fp8 requires ml_dtypes package which is compatible with windows)

```bash
python DPU_Error_Analysis/scripts/generate_dnn_random_vectors.py --format fp8  --num-tests 10000 --seed 12345 --range 1.0
python DPU_Error_Analysis/scripts/generate_dnn_random_vectors.py --format fp16 --num-tests 10000 --seed 12345 --range 1.0
python DPU_Error_Analysis/scripts/generate_dnn_random_vectors.py --format fp32 --num-tests 10000 --seed 12345 --range 1.0
```

Posit formats, executed in WSL because they require `sfpy`:

```bash
python3 DPU_Error_Analysis/scripts/generate_posit_dnn_random_vectors.py --format posit8  --num-tests 10000 --seed 12345 --range 1.0
python3 DPU_Error_Analysis/scripts/generate_posit_dnn_random_vectors.py --format posit16 --num-tests 10000 --seed 12345 --range 1.0
python3 DPU_Error_Analysis/scripts/generate_posit_dnn_random_vectors.py --format posit32 --num-tests 10000 --seed 12345 --range 1.0
```

LNS16:

```bash
python DPU_Error_Analysis/scripts/generate_lns16_dnn_random_vectors.py --num-tests 10000 --seed 12345 --range 1.0
```

Fixed-point formats:

```bash
python DPU_Error_Analysis/scripts/generate_fxp_dnn_random_vectors.py --format fxp8_16  --num-tests 10000 --seed 12345 --range 1.0
python DPU_Error_Analysis/scripts/generate_fxp_dnn_random_vectors.py --format fxp16_32 --num-tests 10000 --seed 12345 --range 1.0
```

Integer-domain formats:

```bash
python DPU_Error_Analysis/scripts/generate_int_dnn_random_vectors.py --format int8_16  --num-tests 10000 --seed 12345
python DPU_Error_Analysis/scripts/generate_int_dnn_random_vectors.py --format int16_32 --num-tests 10000 --seed 12345
```

---

## Hardware simulation

Each format has a Vivado Tcl script in:

```text
DPU_Error_Analysis/vivado/scripts/
```

Typical usage inside the Vivado Tcl Console:

```tcl
cd C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/DPU_Error_Analysis
source vivado/scripts/run_sim_fp16.tcl
```

The hardware output is written into:

```text
DPU_Error_Analysis/data/dnn_random_10k/hw_outputs/
```

---

## Comparison scripts

Floating-point formats:

```bash
python DPU_Error_Analysis/scripts/compare_hw_outputs.py --format fp8
python DPU_Error_Analysis/scripts/compare_hw_outputs.py --format fp16
python DPU_Error_Analysis/scripts/compare_hw_outputs.py --format fp32
```

Posit formats, executed in WSL:

```bash
python3 DPU_Error_Analysis/scripts/compare_posit_hw_outputs.py --format posit8
python3 DPU_Error_Analysis/scripts/compare_posit_hw_outputs.py --format posit16
python3 DPU_Error_Analysis/scripts/compare_posit_hw_outputs.py --format posit32
```

LNS16:

```bash
python DPU_Error_Analysis/scripts/compare_lns16_hw_outputs.py --format lns16
```

Fixed-point formats:

```bash
python DPU_Error_Analysis/scripts/compare_fxp_hw_outputs.py --format fxp8_16
python DPU_Error_Analysis/scripts/compare_fxp_hw_outputs.py --format fxp16_32
```

Integer-domain formats:

```bash
python DPU_Error_Analysis/scripts/compare_int_hw_outputs.py --format int8_16
python DPU_Error_Analysis/scripts/compare_int_hw_outputs.py --format int16_32
```

---

## Error metrics

The per-format summary files report:

```text
num_tests
exact_match_percent
mean_abs_error
max_abs_error
mean_rel_error
max_rel_error
rmse
```

For integer-domain formats, the corresponding absolute error and RMSE are expressed in integer counts:

```text
mean_abs_error_int
max_abs_error_int
rmse_int
```

The consolidated table normalizes these names into common columns while preserving the metric domain and error unit.

The consolidated summary is:

```text
DPU_Error_Analysis/reports/dnn_random_10k/dpu_error_summary_all_formats.csv
```

---

## Consolidated plots

The final comparison plots are generated from the consolidated summary using:

```bash
python DPU_Error_Analysis/scripts/plot_global_error_summary.py
```

The most useful final plots are:

```text
DPU_Error_Analysis/plots/dnn_random_10k/final/real_mean_abs_error_by_format.png
DPU_Error_Analysis/plots/dnn_random_10k/final/real_rmse_by_format.png
```

## Current consolidated result

The consolidated summary currently includes all evaluated formats:

```text
FP8, FP16, FP32
Posit8, Posit16, Posit32
LNS16
FXP8_16, FXP16_32
INT8_16, INT16_32
```

At the end of the current flow, all individual per-format simulations, comparisons, and summary files have been generated.
