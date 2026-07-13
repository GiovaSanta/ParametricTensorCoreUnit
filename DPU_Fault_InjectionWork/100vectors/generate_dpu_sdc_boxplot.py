#!/usr/bin/env python3
"""
Generate one boxplot containing the per-vector activated SDC-rate
distributions of all evaluated DPU formats.

Place this script in:

    DPU_Fault_InjectionWork/100vectors/

and run:

    python generate_dpu_sdc_boxplot.py

The script expects each campaign folder to contain its
fault_summary_by_vector.csv file.
"""

from pathlib import Path
import csv

import matplotlib.pyplot as plt


ROOT = Path(__file__).resolve().parent

CAMPAIGNS = [
    (
        "FP8",
        ROOT / "fp8_results_100"
        / "fault_summary_by_vector.csv",
    ),
    (
        "Posit8",
        ROOT / "posit8" / "posit8_results_100"
        / "fault_summary_by_vector.csv",
    ),
    (
        "FP16",
        ROOT / "fp16" / "fp16_results_100"
        / "fault_summary_by_vector.csv",
    ),
    (
        "Posit16",
        ROOT / "posit16" / "posit16_results_100"
        / "fault_summary_by_vector.csv",
    ),
    (
        "LNS16",
        ROOT / "lns16" / "lns16_results_100"
        / "fault_summary_by_vector.csv",
    ),
    (
        "FP32",
        ROOT / "fp32" / "fp32_results_100"
        / "fault_summary_by_vector.csv",
    ),
    (
        "Posit32",
        ROOT / "posit32" / "posit32_results_100"
        / "fault_summary_by_vector.csv",
    ),
    (
        "FXP8/16",
        ROOT / "fxp8_16" / "fxp8_16_results_100"
        / "fault_summary_by_vector.csv",
    ),
    (
        "FXP16/32",
        ROOT / "fxp16_32" / "fxp16_32_results_100"
        / "fault_summary_by_vector.csv",
    ),
]


def read_sdc_percentages(path: Path) -> list[float]:
    if not path.exists():
        raise FileNotFoundError(
            f"Missing file:\n{path}\n"
            "Check the folder name in the CAMPAIGNS mapping."
        )

    values: list[float] = []

    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)

        if "activated_sdc_percent" not in (reader.fieldnames or []):
            raise KeyError(
                f"{path} does not contain the column "
                "'activated_sdc_percent'."
            )

        for row in reader:
            values.append(float(row["activated_sdc_percent"]))

    if len(values) != 100:
        raise ValueError(
            f"{path} contains {len(values)} vectors; expected 100."
        )

    return values


def main() -> None:
    labels: list[str] = []
    distributions: list[list[float]] = []

    for label, path in CAMPAIGNS:
        labels.append(label)
        distributions.append(read_sdc_percentages(path))

    fig, ax = plt.subplots(figsize=(11, 6.5))

    ax.boxplot(
        distributions,
        labels=labels,
        showmeans=True,
        meanline=True,
        showfliers=True,
    )

    ax.set_title(
        "Per-Vector Activated SDC-Rate Distributions"
    )
    ax.set_xlabel("DPU format")
    ax.set_ylabel("Activated SDC rate per vector (%)")
    ax.set_ylim(45, 102)
    ax.grid(axis="y", linestyle="--", alpha=0.4)

    plt.setp(
        ax.get_xticklabels(),
        rotation=35,
        ha="right",
    )

    fig.tight_layout()

    output_path = ROOT / "dpu_sdc_boxplot.png"
    fig.savefig(
        output_path,
        dpi=300,
        bbox_inches="tight",
    )

    print(f"Created: {output_path}")


if __name__ == "__main__":
    main()
