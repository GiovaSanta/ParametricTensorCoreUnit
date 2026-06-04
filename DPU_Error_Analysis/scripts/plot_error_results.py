#!/usr/bin/env python3
"""
Generate plots for DPU error analysis.

Currently implemented:
  - fp16

Input:
  data/dnn_random_10k/compared/fp16_compared.csv

Outputs:
  plots/dnn_random_10k/per_format/fp16_ref_vs_hw.png
  plots/dnn_random_10k/per_format/fp16_abs_error_hist.png
  plots/dnn_random_10k/per_format/fp16_rel_error_hist.png
  plots/dnn_random_10k/per_format/fp16_error_vs_reference.png
"""

import argparse
import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


BASE_DIR = Path("DPU_Error_Analysis")
EXP_NAME = "dnn_random_10k"

COMPARED_DIR = BASE_DIR / "data" / EXP_NAME / "compared"
PLOTS_DIR = BASE_DIR / "plots" / EXP_NAME / "per_format"


def read_compared_csv(path: Path):
    reference = []
    hardware = []
    abs_error = []
    rel_error = []

    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)

        for row in reader:
            reference.append(float(row["reference_real"]))
            hardware.append(float(row["hw_real"]))
            abs_error.append(float(row["abs_error"]))
            rel_error.append(float(row["rel_error"]))

    return reference, hardware, abs_error, rel_error


def plot_ref_vs_hw(fmt: str, reference, hardware):
    output_path = PLOTS_DIR / f"{fmt}_ref_vs_hw.png"

    min_val = min(min(reference), min(hardware))
    max_val = max(max(reference), max(hardware))

    plt.figure(figsize=(7, 6))
    plt.scatter(reference, hardware, s=6, alpha=0.45)
    plt.plot([min_val, max_val], [min_val, max_val], linestyle="--", linewidth=1)

    plt.xlabel("Python reference result")
    plt.ylabel("Hardware decoded result")
    plt.title(f"{fmt.upper()} reference vs hardware output")
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path, dpi=200)
    plt.close()

    print(f"Saved {output_path}")


def plot_abs_error_hist(fmt: str, abs_error):
    output_path = PLOTS_DIR / f"{fmt}_abs_error_hist.png"

    plt.figure(figsize=(7, 5))
    plt.hist(abs_error, bins=80)

    plt.xlabel("Absolute error")
    plt.ylabel("Number of test cases")
    plt.title(f"{fmt.upper()} absolute error distribution")
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path, dpi=200)
    plt.close()

    print(f"Saved {output_path}")


def plot_rel_error_hist(fmt: str, rel_error):
    output_path = PLOTS_DIR / f"{fmt}_rel_error_hist.png"

    # Avoid plotting extreme infinite-like artifacts if any appear.
    finite_rel_error = [x for x in rel_error if x == x and x != float("inf") and x != float("-inf")]

    plt.figure(figsize=(7, 5))
    plt.hist(finite_rel_error, bins=80)

    plt.xlabel("Relative error")
    plt.ylabel("Number of test cases")
    plt.title(f"{fmt.upper()} relative error distribution")
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path, dpi=200)
    plt.close()

    print(f"Saved {output_path}")


def plot_error_vs_reference(fmt: str, reference, abs_error):
    output_path = PLOTS_DIR / f"{fmt}_error_vs_reference.png"

    plt.figure(figsize=(7, 5))
    plt.scatter(reference, abs_error, s=6, alpha=0.45)

    plt.xlabel("Python reference result")
    plt.ylabel("Absolute error")
    plt.title(f"{fmt.upper()} absolute error vs reference magnitude")
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path, dpi=200)
    plt.close()

    print(f"Saved {output_path}")


def plot_format(fmt: str):
    compared_path = COMPARED_DIR / f"{fmt}_compared.csv"

    if not compared_path.exists():
        raise FileNotFoundError(f"Compared CSV not found: {compared_path}")

    PLOTS_DIR.mkdir(parents=True, exist_ok=True)

    reference, hardware, abs_error, rel_error = read_compared_csv(compared_path)

    plot_ref_vs_hw(fmt, reference, hardware)
    plot_abs_error_hist(fmt, abs_error)
    plot_rel_error_hist(fmt, rel_error)
    plot_error_vs_reference(fmt, reference, abs_error)

    print()
    print(f"{fmt.upper()} plotting completed.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--format", required=True, choices=["fp8", "fp16", "fp32", "posit8", "posit16", "posit32", "lns16", "fxp16_32", "fxp8_16"])
    args = parser.parse_args()

    plot_format(args.format)


if __name__ == "__main__":
    main()