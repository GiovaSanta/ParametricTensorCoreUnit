#!/usr/bin/env python3
"""
Compare LNS16 DPU hardware outputs against high-precision Python reference results.

LNS16 format:
  - bits 15:14 = 01 for normal finite values
  - bit 13 = sign
  - bits 12:0 = signed fixed-point log2 value
  - fractional log bits W_F = 9
"""

import argparse
import csv
import math
from pathlib import Path


W_F = 9
SCALE = 1 << W_F

BASE_DIR = Path("DPU_Error_Analysis")
EXP_DIR = BASE_DIR / "data" / "dnn_random_10k"
REPORT_DIR = BASE_DIR / "reports" / "dnn_random_10k" / "per_format"


def signed13_to_bits(x: int) -> int:
    if x < 0:
        x = (1 << 13) + x
    return x & 0x1FFF


def make_lns(sign: int, log_val: int) -> int:
    return 0x4000 | ((sign & 1) << 13) | signed13_to_bits(log_val)


def signed13_from_lns(x: int) -> int:
    v = x & 0x1FFF
    if v & 0x1000:
        v -= 0x2000
    return v


def sign_from_lns(x: int) -> int:
    return (x >> 13) & 1


def decode_lns_int(x: int) -> float:
    if x == 0x0000:
        return 0.0

    if (x >> 14) != 0b01:
        return 0.0

    sign = -1.0 if sign_from_lns(x) else 1.0
    log_val = signed13_from_lns(x) / SCALE
    return sign * (2.0 ** log_val)


def encode_lns_real(value: float) -> int:
    if abs(value) < 1e-30:
        return 0x0000

    sign = 1 if value < 0.0 else 0
    mag = abs(value)
    log_fixed = int(round(math.log2(mag) * SCALE))

    if not (-4096 <= log_fixed <= 4095):
        raise ValueError(
            f"LNS log field out of signed-13-bit range: value={value}, log_fixed={log_fixed}"
        )

    return make_lns(sign, log_fixed)


def lns_hex_to_float(hex_string: str) -> float:
    x = int(hex_string.strip(), 16)
    return decode_lns_int(x)


def float_to_lns_hex(value: float) -> str:
    x = encode_lns_real(value)
    return f"{x & 0xFFFF:04X}"


def safe_relative_error(abs_error: float, reference: float, epsilon: float = 1e-12) -> float:
    return abs_error / max(abs(reference), epsilon)


def compare_lns16() -> None:
    fmt = "lns16"

    reference_path = EXP_DIR / "references" / "lns16_reference.csv"
    hw_path = EXP_DIR / "hw_outputs" / "lns16_hw_outputs.txt"
    compared_path = EXP_DIR / "compared" / "lns16_compared.csv"
    summary_path = REPORT_DIR / "lns16_error_summary.csv"

    compared_path.parent.mkdir(parents=True, exist_ok=True)
    summary_path.parent.mkdir(parents=True, exist_ok=True)

    with reference_path.open("r", encoding="utf-8") as rf:
        reference_rows = list(csv.DictReader(rf))

    with hw_path.open("r", encoding="utf-8") as hf:
        hw_hex_values = [line.strip().upper() for line in hf if line.strip()]

    if len(reference_rows) != len(hw_hex_values):
        raise ValueError(
            f"Line count mismatch for LNS16: references={len(reference_rows)}, hardware={len(hw_hex_values)}"
        )

    fieldnames = [
        "test_id",
        "reference_real",
        "reference_rounded_lns16_hex",
        "reference_rounded_lns16_real",
        "hw_hex",
        "hw_real",
        "abs_error",
        "rel_error",
        "squared_error",
        "exact_match_to_reference_rounded_lns16",
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

            hw_real = lns_hex_to_float(hw_hex)

            try:
                reference_rounded_hex = float_to_lns_hex(reference_real)
                reference_rounded_real = lns_hex_to_float(reference_rounded_hex)
            except Exception:
                reference_rounded_hex = "ERROR"
                reference_rounded_real = math.nan

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
                "reference_rounded_lns16_hex": reference_rounded_hex,
                "reference_rounded_lns16_real": reference_rounded_real,
                "hw_hex": hw_hex,
                "hw_real": hw_real,
                "abs_error": abs_error,
                "rel_error": rel_error,
                "squared_error": squared_error,
                "exact_match_to_reference_rounded_lns16": exact_match,
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

    print("LNS16 comparison completed.")
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
    parser.add_argument("--format", required=True, choices=["lns16"])
    args = parser.parse_args()

    compare_lns16()


if __name__ == "__main__":
    main()