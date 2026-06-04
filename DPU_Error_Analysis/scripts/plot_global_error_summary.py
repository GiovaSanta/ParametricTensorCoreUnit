#!/usr/bin/env python3
"""
Create final comparison plots from the consolidated DPU error summary table.

Input:
  DPU_Error_Analysis/reports/dnn_random_10k/dpu_error_summary_all_formats.csv

Outputs:
  DPU_Error_Analysis/plots/dnn_random_10k/final/real_mean_abs_error_by_format.png
  DPU_Error_Analysis/plots/dnn_random_10k/final/real_rmse_by_format.png
  DPU_Error_Analysis/plots/dnn_random_10k/final/exact_match_percent_by_format.png

Notes:
  - Mean absolute error and RMSE plots include only decoded-real-domain formats.
  - Integer formats are excluded from real-error plots because their error unit is integer counts.
  - Exact-match percentage is plotted for all formats.
"""

import csv
from pathlib import Path

import matplotlib.pyplot as plt


BASE_DIR = Path("DPU_Error_Analysis")
SUMMARY_PATH = BASE_DIR / "reports" / "dnn_random_10k" / "dpu_error_summary_all_formats.csv"
OUTPUT_DIR = BASE_DIR / "plots" / "dnn_random_10k" / "final"


def read_rows():
    with SUMMARY_PATH.open("r", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def to_float(value: str) -> float:
    return float(value) if value not in ("", None) else 0.0


def save_bar_plot(formats, values, title, ylabel, output_path, log_y=False):
    plt.figure(figsize=(11, 6))
    plt.bar(formats, values)
    plt.title(title)
    plt.ylabel(ylabel)
    plt.xlabel("DPU format")
    plt.xticks(rotation=45, ha="right")

    if log_y:
        positive_values = [v for v in values if v > 0]
        if positive_values:
            plt.yscale("log")

    plt.tight_layout()
    plt.savefig(output_path, dpi=200)
    plt.close()


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    rows = read_rows()
    real_rows = [r for r in rows if r["metric_domain"] == "decoded_real_domain"]

    real_formats = [r["format"] for r in real_rows]
    real_mean_abs = [to_float(r["mean_abs_error"]) for r in real_rows]
    real_rmse = [to_float(r["rmse"]) for r in real_rows]

    all_formats = [r["format"] for r in rows]
    exact_match = [to_float(r["exact_match_percent"]) for r in rows]

    save_bar_plot(
        real_formats,
        real_mean_abs,
        "Mean Absolute Error by Format (Decoded Real Domain)",
        "Mean absolute error",
        OUTPUT_DIR / "real_mean_abs_error_by_format.png",
        log_y=True,
    )

    save_bar_plot(
        real_formats,
        real_rmse,
        "RMSE by Format (Decoded Real Domain)",
        "RMSE",
        OUTPUT_DIR / "real_rmse_by_format.png",
        log_y=True,
    )

    save_bar_plot(
        all_formats,
        exact_match,
        "Exact Match Percentage by Format",
        "Exact match (%)",
        OUTPUT_DIR / "exact_match_percent_by_format.png",
        log_y=False,
    )

    print("Generated final plots:")
    print(f"  {OUTPUT_DIR / 'real_mean_abs_error_by_format.png'}")
    print(f"  {OUTPUT_DIR / 'real_rmse_by_format.png'}")
    print(f"  {OUTPUT_DIR / 'exact_match_percent_by_format.png'}")


if __name__ == "__main__":
    main()
