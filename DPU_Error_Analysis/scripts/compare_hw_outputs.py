#!/usr/bin/env python3
"""
Compare DPU hardware outputs against high-precision Python reference results.

Currently implemented:
  - fp16

Input files:
  data/dnn_random_10k/references/fp16_reference.csv
  data/dnn_random_10k/hw_outputs/fp16_hw_outputs.txt

Output files:
  data/dnn_random_10k/compared/fp16_compared.csv
  reports/dnn_random_10k/per_format/fp16_error_summary.csv
"""

import argparse
import csv
import math
import struct
from pathlib import Path


BASE_DIR = Path("DPU_Error_Analysis")
EXP_DIR = BASE_DIR / "data" / "dnn_random_10k"
REPORT_DIR = BASE_DIR / "reports" / "dnn_random_10k" / "per_format"


def fp16_hex_to_float(hex_string: str) -> float:
    hex_string = hex_string.strip()
    raw = bytes.fromhex(hex_string)
    return struct.unpack(">e", raw)[0]


def float_to_fp16_hex(value: float) -> str:
    packed = struct.pack(">e", value)
    return packed.hex().upper()


def safe_relative_error(abs_error: float, reference: float, epsilon: float = 1e-12) -> float:
    return abs_error / max(abs(reference), epsilon)


def compare_fp16() -> None:
    reference_path = EXP_DIR / "references" / "fp16_reference.csv"
    hw_path = EXP_DIR / "hw_outputs" / "fp16_hw_outputs.txt"
    compared_path = EXP_DIR / "compared" / "fp16_compared.csv"
    summary_path = REPORT_DIR / "fp16_error_summary.csv"

    compared_path.parent.mkdir(parents=True, exist_ok=True)
    summary_path.parent.mkdir(parents=True, exist_ok=True)

    with reference_path.open("r", encoding="utf-8") as rf:
        reference_rows = list(csv.DictReader(rf))

    with hw_path.open("r", encoding="utf-8") as hf:
        hw_hex_values = [line.strip().upper() for line in hf if line.strip()]

    if len(reference_rows) != len(hw_hex_values):
        raise ValueError(
            f"Line count mismatch: references={len(reference_rows)}, hardware={len(hw_hex_values)}"
        )

    fieldnames = [
        "test_id",
        "reference_real",
        "reference_rounded_fp16_hex",
        "reference_rounded_fp16_real",
        "hw_hex",
        "hw_real",
        "abs_error",
        "rel_error",
        "squared_error",
        "exact_match_to_reference_rounded_fp16",
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
            reference_real = float(row["reference_real"])

            hw_real = fp16_hex_to_float(hw_hex)

            # Useful strict comparison: round the mathematical reference to FP16
            # and check whether the HW result matches that rounded FP16 encoding.
            try:
                reference_rounded_hex = float_to_fp16_hex(reference_real)
                reference_rounded_real = fp16_hex_to_float(reference_rounded_hex)
            except OverflowError:
                reference_rounded_hex = "OVERFLOW"
                reference_rounded_real = math.inf if reference_real > 0 else -math.inf

            abs_error = abs(hw_real - reference_real)
            rel_error = safe_relative_error(abs_error, reference_real)
            squared_error = abs_error * abs_error

            exact_match = int(hw_hex == reference_rounded_hex)
            exact_matches += exact_match

            abs_errors.append(abs_error)
            rel_errors.append(rel_error)
            sq_errors.append(squared_error)

            writer.writerow({
                "test_id": test_id,
                "reference_real": reference_real,
                "reference_rounded_fp16_hex": reference_rounded_hex,
                "reference_rounded_fp16_real": reference_rounded_real,
                "hw_hex": hw_hex,
                "hw_real": hw_real,
                "abs_error": abs_error,
                "rel_error": rel_error,
                "squared_error": squared_error,
                "exact_match_to_reference_rounded_fp16": exact_match,
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
            "exact_matches_to_reference_rounded_fp16",
            "exact_match_percent",
            "mean_abs_error",
            "max_abs_error",
            "mean_rel_error",
            "max_rel_error",
            "rmse",
        ]
        writer = csv.DictWriter(sf, fieldnames=fieldnames_summary)
        writer.writeheader()
        writer.writerow({
            "format": "fp16",
            "num_tests": n,
            "exact_matches_to_reference_rounded_fp16": exact_matches,
            "exact_match_percent": exact_percent,
            "mean_abs_error": mean_abs_error,
            "max_abs_error": max_abs_error,
            "mean_rel_error": mean_rel_error,
            "max_rel_error": max_rel_error,
            "rmse": rmse,
        })

    print("FP16 comparison completed.")
    print(f"Compared file: {compared_path}")
    print(f"Summary file:  {summary_path}")
    print()
    print(f"num_tests          = {n}")
    print(f"exact_match_percent= {exact_percent:.4f}%")
    print(f"mean_abs_error     = {mean_abs_error}")
    print(f"max_abs_error      = {max_abs_error}")
    print(f"mean_rel_error     = {mean_rel_error}")
    print(f"max_rel_error      = {max_rel_error}")
    print(f"rmse               = {rmse}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--format", required=True, choices=["fp16"])
    args = parser.parse_args()

    if args.format == "fp16":
        compare_fp16()


if __name__ == "__main__":
    main()