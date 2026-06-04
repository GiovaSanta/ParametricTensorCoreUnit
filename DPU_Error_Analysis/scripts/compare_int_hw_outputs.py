#!/usr/bin/env python3
"""
Compare integer DPU hardware outputs against exact integer Python references.

Implemented:
  - int8_16:
      hardware output: signed 16-bit integer

  - int16_32:
      hardware output: signed 32-bit integer

The comparison is performed in integer counts, not scaled real values.
"""

import argparse
import csv
import math
from pathlib import Path


BASE_DIR = Path("DPU_Error_Analysis")
EXP_DIR = BASE_DIR / "data" / "dnn_random_10k"
REPORT_DIR = BASE_DIR / "reports" / "dnn_random_10k" / "per_format"


FORMAT_CONFIG = {
    "int8_16": {
        "output_width": 16,
    },
    "int16_32": {
        "output_width": 32,
    },
}


def hex_to_signed_int(hex_string: str, width: int) -> int:
    value = int(hex_string.strip(), 16)
    if value & (1 << (width - 1)):
        value -= (1 << width)
    return value


def signed_int_to_hex(value: int, width: int) -> str:
    if value < 0:
        value = (1 << width) + value
    hex_digits = width // 4
    return f"{value & ((1 << width) - 1):0{hex_digits}X}"


def safe_relative_error(abs_error: float, reference: int, epsilon: float = 1.0) -> float:
    return abs_error / max(abs(reference), epsilon)


def compare_int_format(fmt: str) -> None:
    cfg = FORMAT_CONFIG[fmt]
    output_width = cfg["output_width"]

    reference_path = EXP_DIR / "references" / f"{fmt}_reference.csv"
    hw_path = EXP_DIR / "hw_outputs" / f"{fmt}_hw_outputs.txt"
    compared_path = EXP_DIR / "compared" / f"{fmt}_compared.csv"
    summary_path = REPORT_DIR / f"{fmt}_error_summary.csv"

    compared_path.parent.mkdir(parents=True, exist_ok=True)
    summary_path.parent.mkdir(parents=True, exist_ok=True)

    with reference_path.open("r", encoding="utf-8") as rf:
        reference_rows = list(csv.DictReader(rf))

    with hw_path.open("r", encoding="utf-8") as hf:
        hw_hex_values = [line.strip().upper() for line in hf if line.strip()]

    if len(reference_rows) != len(hw_hex_values):
        raise ValueError(
            f"Line count mismatch for {fmt}: references={len(reference_rows)}, hardware={len(hw_hex_values)}"
        )

    fieldnames = [
        "test_id",
        "reference_int",
        "reference_hex",
        "hw_hex",
        "hw_int",
        "abs_error_int",
        "rel_error",
        "squared_error",
        "exact_match",
    ]

    abs_errors = []
    rel_errors = []
    sq_errors = []
    exact_matches = 0

    with compared_path.open("w", newline="", encoding="utf-8") as cf:
        writer = csv.DictWriter(cf, fieldnames=fieldnames)
        writer.writeheader()

        for row, hw_hex in zip(reference_rows, hw_hex_values):
            test_id = int(row["test_id"])
            reference_int = int(row["reference_int"])
            reference_hex = signed_int_to_hex(reference_int, output_width)

            hw_int = hex_to_signed_int(hw_hex, output_width)

            abs_error = abs(hw_int - reference_int)
            rel_error = safe_relative_error(abs_error, reference_int)
            squared_error = abs_error * abs_error
            exact_match = int(hw_int == reference_int)

            exact_matches += exact_match
            abs_errors.append(abs_error)
            rel_errors.append(rel_error)
            sq_errors.append(squared_error)

            writer.writerow({
                "test_id": test_id,
                "reference_int": reference_int,
                "reference_hex": reference_hex,
                "hw_hex": hw_hex,
                "hw_int": hw_int,
                "abs_error_int": abs_error,
                "rel_error": rel_error,
                "squared_error": squared_error,
                "exact_match": exact_match,
            })

    n = len(abs_errors)
    mean_abs_error = sum(abs_errors) / n
    max_abs_error = max(abs_errors)
    mean_rel_error = sum(rel_errors) / n
    max_rel_error = max(rel_errors)
    rmse = math.sqrt(sum(sq_errors) / n)
    exact_percent = 100.0 * exact_matches / n

    with summary_path.open("w", newline="", encoding="utf-8") as sf:
        fieldnames_summary = [
            "format",
            "num_tests",
            "exact_matches",
            "exact_match_percent",
            "mean_abs_error_int",
            "max_abs_error_int",
            "mean_rel_error",
            "max_rel_error",
            "rmse_int",
        ]
        writer = csv.DictWriter(sf, fieldnames=fieldnames_summary)
        writer.writeheader()
        writer.writerow({
            "format": fmt,
            "num_tests": n,
            "exact_matches": exact_matches,
            "exact_match_percent": exact_percent,
            "mean_abs_error_int": mean_abs_error,
            "max_abs_error_int": max_abs_error,
            "mean_rel_error": mean_rel_error,
            "max_rel_error": max_rel_error,
            "rmse_int": rmse,
        })

    print(f"{fmt.upper()} integer-domain comparison completed.")
    print(f"Compared file: {compared_path}")
    print(f"Summary file:  {summary_path}")
    print()
    print(f"num_tests           = {n}")
    print(f"exact_match_percent = {exact_percent:.4f}%")
    print(f"mean_abs_error_int  = {mean_abs_error}")
    print(f"max_abs_error_int   = {max_abs_error}")
    print(f"mean_rel_error      = {mean_rel_error}")
    print(f"max_rel_error       = {max_rel_error}")
    print(f"rmse_int            = {rmse}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--format", required=True, choices=sorted(FORMAT_CONFIG.keys()))
    args = parser.parse_args()

    compare_int_format(args.format)


if __name__ == "__main__":
    main()
