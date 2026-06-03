#!/usr/bin/env python3
"""
Generate DNN-like random test vectors for Posit DPU error analysis.

Implemented:
  - posit16
  - posit32
  - posit8

This script should be run from WSL because it uses sfpy.
"""

import argparse
import csv
import random
from pathlib import Path

from sfpy import Posit8, Posit16, Posit32


REPO_EXPERIMENT_DIR = Path("DPU_Error_Analysis/data/dnn_random_10k")


FORMAT_CONFIG = {
    "posit8": {
        "class": Posit8,
        "hex_digits": 2,
    },
    "posit16": {
        "class": Posit16,
        "hex_digits": 4,
    },
    "posit32": {
        "class": Posit32,
        "hex_digits": 8,
    },
}


def posit_to_hex(value: float, posit_class, hex_digits: int) -> str:
    p = posit_class(value)
    return format(p.bits, f"0{hex_digits}X")


def posit_hex_to_float(hex_string: str, posit_class) -> float:
    bits = int(hex_string.strip(), 16)
    return float(posit_class.from_bits(bits))


def generate_posit_format(fmt: str, num_tests: int, seed: int, value_range: float) -> None:
    cfg = FORMAT_CONFIG[fmt]
    posit_class = cfg["class"]
    hex_digits = cfg["hex_digits"]

    random.seed(seed)

    vectors_dir = REPO_EXPERIMENT_DIR / "vectors"
    references_dir = REPO_EXPERIMENT_DIR / "references"

    vectors_dir.mkdir(parents=True, exist_ok=True)
    references_dir.mkdir(parents=True, exist_ok=True)

    vector_path = vectors_dir / f"{fmt}_vectors.txt"
    reference_path = references_dir / f"{fmt}_reference.csv"

    fieldnames = [
        "test_id",
        "A0_hex", "A1_hex", "A2_hex", "A3_hex",
        "B0_hex", "B1_hex", "B2_hex", "B3_hex",
        "C0_hex",
        "A0_real", "A1_real", "A2_real", "A3_real",
        "B0_real", "B1_real", "B2_real", "B3_real",
        "C0_real",
        "reference_real",
    ]

    kept = 0
    attempts = 0

    with vector_path.open("w", encoding="utf-8") as vf, reference_path.open("w", newline="", encoding="utf-8") as rf:
        writer = csv.DictWriter(rf, fieldnames=fieldnames)
        writer.writeheader()

        while kept < num_tests:
            attempts += 1

            A_raw = [random.uniform(-value_range, value_range) for _ in range(4)]
            B_raw = [random.uniform(-value_range, value_range) for _ in range(4)]
            C_raw = random.uniform(-value_range, value_range)

            A_hex = [posit_to_hex(x, posit_class, hex_digits) for x in A_raw]
            B_hex = [posit_to_hex(x, posit_class, hex_digits) for x in B_raw]
            C_hex = posit_to_hex(C_raw, posit_class, hex_digits)

            A = [posit_hex_to_float(x, posit_class) for x in A_hex]
            B = [posit_hex_to_float(x, posit_class) for x in B_hex]
            C = posit_hex_to_float(C_hex, posit_class)

            reference = sum(A[i] * B[i] for i in range(4)) + C

            if abs(reference) > 5.0:
                continue

            vf.write(" ".join(A_hex + B_hex + [C_hex]) + "\n")

            writer.writerow({
                "test_id": kept,
                "A0_hex": A_hex[0], "A1_hex": A_hex[1], "A2_hex": A_hex[2], "A3_hex": A_hex[3],
                "B0_hex": B_hex[0], "B1_hex": B_hex[1], "B2_hex": B_hex[2], "B3_hex": B_hex[3],
                "C0_hex": C_hex,
                "A0_real": A[0], "A1_real": A[1], "A2_real": A[2], "A3_real": A[3],
                "B0_real": B[0], "B1_real": B[1], "B2_real": B[2], "B3_real": B[3],
                "C0_real": C,
                "reference_real": reference,
            })

            kept += 1

    print(f"Generated {kept} {fmt.upper()} vectors.")
    print(f"Attempts: {attempts}")
    print(f"Vector file:    {vector_path}")
    print(f"Reference file: {reference_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--format", required=True, choices=sorted(FORMAT_CONFIG.keys()))
    parser.add_argument("--num-tests", type=int, default=10000)
    parser.add_argument("--seed", type=int, default=12345)
    parser.add_argument("--range", type=float, default=1.0, dest="value_range")
    args = parser.parse_args()

    generate_posit_format(args.format, args.num_tests, args.seed, args.value_range)


if __name__ == "__main__":
    main()
