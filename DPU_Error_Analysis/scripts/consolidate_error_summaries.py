#!/usr/bin/env python3
"""
Consolidate per-format DPU error summary CSV files into one global table.

Input folder:
  DPU_Error_Analysis/reports/dnn_random_10k/per_format/

Output file:
  DPU_Error_Analysis/reports/dnn_random_10k/dpu_error_summary_all_formats.csv

Notes:
  - Real-valued formats are reported with real-valued absolute/RMSE metrics.
  - Integer formats are reported with integer-domain absolute/RMSE metrics.
"""

import csv
from pathlib import Path


BASE_DIR = Path("DPU_Error_Analysis")
PER_FORMAT_DIR = BASE_DIR / "reports" / "dnn_random_10k" / "per_format"
OUTPUT_FILE = BASE_DIR / "reports" / "dnn_random_10k" / "dpu_error_summary_all_formats.csv"


FORMAT_ORDER = [
    "fp8",
    "fp16",
    "fp32",
    "posit8",
    "posit16",
    "posit32",
    "lns16",
    "fxp8_16",
    "fxp16_32",
    "int8_16",
    "int16_32",
]


def read_one_row(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    if len(rows) != 1:
        raise ValueError(f"Expected exactly one row in {path}, found {len(rows)}")
    return rows[0]


def pick(row: dict, *names: str, default: str = "") -> str:
    for name in names:
        value = row.get(name)
        if value not in (None, ""):
            return value
    return default


def normalize_summary(row: dict) -> dict:
    fmt = row["format"]

    is_integer = fmt.startswith("int")

    if is_integer:
        metric_domain = "integer_domain"
        error_unit = "integer_counts"
        exact_matches = pick(row, "exact_matches", "exact_matches_to_reference_rounded")
        mean_abs_error = pick(row, "mean_abs_error_int", "mean_abs_error")
        max_abs_error = pick(row, "max_abs_error_int", "max_abs_error")
        rmse = pick(row, "rmse_int", "rmse")
        reference_definition = "exact Python integer dot-product reference"
    else:
        metric_domain = "decoded_real_domain"
        error_unit = "real_value"
        exact_matches = pick(row, "exact_matches_to_reference_rounded", "exact_matches")
        mean_abs_error = pick(row, "mean_abs_error", "mean_abs_error_int")
        max_abs_error = pick(row, "max_abs_error", "max_abs_error_int")
        rmse = pick(row, "rmse", "rmse_int")
        reference_definition = "full-precision Python real-valued dot-product reference"

    return {
        "format": fmt,
        "metric_domain": metric_domain,
        "reference_definition": reference_definition,
        "error_unit": error_unit,
        "num_tests": pick(row, "num_tests"),
        "exact_matches": exact_matches,
        "exact_match_percent": pick(row, "exact_match_percent"),
        "mean_abs_error": mean_abs_error,
        "max_abs_error": max_abs_error,
        "mean_rel_error": pick(row, "mean_rel_error"),
        "max_rel_error": pick(row, "max_rel_error"),
        "rmse": rmse,
    }


def main() -> None:
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

    normalized_rows = []

    for fmt in FORMAT_ORDER:
        path = PER_FORMAT_DIR / f"{fmt}_error_summary.csv"
        if not path.exists():
            print(f"WARNING: missing summary file, skipping: {path}")
            continue

        row = read_one_row(path)
        normalized_rows.append(normalize_summary(row))

    fieldnames = [
        "format",
        "metric_domain",
        "reference_definition",
        "error_unit",
        "num_tests",
        "exact_matches",
        "exact_match_percent",
        "mean_abs_error",
        "max_abs_error",
        "mean_rel_error",
        "max_rel_error",
        "rmse",
    ]

    with OUTPUT_FILE.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(normalized_rows)

    print(f"Wrote consolidated summary:")
    print(f"  {OUTPUT_FILE}")
    print()
    print(f"Included {len(normalized_rows)} formats:")
    for row in normalized_rows:
        print(f"  - {row['format']} ({row['metric_domain']})")


if __name__ == "__main__":
    main()
