#!/usr/bin/env python3
"""
Compare DPU hardware outputs against high-precision Python reference results.

Currently implemented:
  - fp8  : float8_e4m3 using ml_dtypes
  - fp16 : IEEE-754 binary16
  - fp32 : IEEE-754 binary32
"""

import argparse
import csv
import math
import struct
from pathlib import Path

import numpy as np
from ml_dtypes import float8_e4m3


BASE_DIR = Path("DPU_Error_Analysis")
EXP_DIR = BASE_DIR / "data" / "dnn_random_10k"
REPORT_DIR = BASE_DIR / "reports" / "dnn_random_10k" / "per_format"


def fp8_e4m3_hex_to_float(hex_string: str) -> float:
    raw = np.array([int(hex_string.strip(), 16)], dtype=np.uint8)
    decoded = raw.view(float8_e4m3)[0]
    return float(decoded)


def float_to_fp8_e4m3_hex(value: float) -> str:
    encoded = np.array([value], dtype=float8_e4m3)
    return format(encoded.view(np.uint8)[0], "02X")


def fp16_hex_to_float(hex_string: str) -> float:
    return struct.unpack(">e", bytes.fromhex(hex_string.strip()))[0]


def float_to_fp16_hex(value: float) -> str:
    return struct.pack(">e", value).hex().upper()


def fp32_hex_to_float(hex_string: str) -> float:
    return struct.unpack(">f", bytes.fromhex(hex_string.strip()))[0]


def float_to_fp32_hex(value: float) -> str:
    return struct.pack(">f", value).hex().upper()


FORMAT_CONFIG = {
    "fp8": {
        "decode": fp8_e4m3_hex_to_float,
        "encode": float_to_fp8_e4m3_hex,
        "rounded_label": "reference_rounded_fp8",
    },
    "fp16": {
        "decode": fp16_hex_to_float,
        "encode": float_to_fp16_hex,
        "rounded_label": "reference_rounded_fp16",
    },
    "fp32": {
        "decode": fp32_hex_to_float,
        "encode": float_to_fp32_hex,
        "rounded_label": "reference_rounded_fp32",
    },
}


def safe_relative_error(abs_error: float, reference: float, epsilon: float = 1e-12) -> float:
    return abs_error / max(abs(reference), epsilon)


def compare_format(fmt: str) -> None:
    cfg = FORMAT_CONFIG[fmt]

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

    rounded_hex_col = f"{cfg['rounded_label']}_hex"
    rounded_real_col = f"{cfg['rounded_label']}_real"
    exact_col = f"exact_match_to_{cfg['rounded_label']}"

    fieldnames = [
        "test_id",
        "reference_real",
        rounded_hex_col,
        rounded_real_col,
        "hw_hex",
        "hw_real",
        "abs_error",
        "rel_error",
        "squared_error",
        exact_col,
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

            hw_real = cfg["decode"](hw_hex)

            try:
                reference_rounded_hex = cfg["encode"](reference_real)
                reference_rounded_real = cfg["decode"](reference_rounded_hex)
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
                rounded_hex_col: reference_rounded_hex,
                rounded_real_col: reference_rounded_real,
                "hw_hex": hw_hex,
                "hw_real": hw_real,
                "abs_error": abs_error,
                "rel_error": rel_error,
                "squared_error": squared_error,
                exact_col: exact_match,
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
            "exact_matches_to_reference_rounded",
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
            "format": fmt,
            "num_tests": n,
            "exact_matches_to_reference_rounded": exact_matches,
            "exact_match_percent": exact_percent,
            "mean_abs_error": mean_abs_error,
            "max_abs_error": max_abs_error,
            "mean_rel_error": mean_rel_error,
            "max_rel_error": max_rel_error,
            "rmse": rmse,
        })

    print(f"{fmt.upper()} comparison completed.")
    print(f"Compared file: {compared_path}")
    print(f"Summary file:  {summary_path}")
    print()
    print(f"num_tests           = {n}")
    print(f"exact_match_percent = {exact_percent:.4f}%")
    print(f"mean_abs_error      = {mean_abs_error}")
    print(f"max_abs_error       = {max_abs_error}")
    print(f"mean_rel_error      = {mean_rel_error}")
    print(f"max_rel_error       = {max_rel_error}")
    print(f"rmse                = {rmse}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--format", required=True, choices=sorted(FORMAT_CONFIG.keys()))
    args = parser.parse_args()

    compare_format(args.format)


if __name__ == "__main__":
    main()