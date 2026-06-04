#!/usr/bin/env python3
"""
Generate DNN-like random test vectors for Posit DPU error analysis.

Implemented:
  - posit8
  - posit16
  - posit32

This script should be run from WSL because it uses sfpy.

Important:
  reference_real is the full-precision Python reference computed from the
  original random real operands, before quantization to the target Posit format.

  quantized_input_reference_real is also stored for debugging/secondary analysis.
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
    """Encode a Python float into Posit hex using sfpy."""
    p = posit_class(value)
    return format(p.bits, f"0{hex_digits}X")


def posit_hex_to_float(hex_string: str, posit_class) -> float:
    """Decode Posit hex into Python float using sfpy."""
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

        "A0_raw", "A1_raw", "A2_raw", "A3_raw",
        "B0_raw", "B1_raw", "B2_raw", "B3_raw",
        "C0_raw",

        "A0_quantized_real", "A1_quantized_real",
        "A2_quantized_real", "A3_quantized_real",
        "B0_quantized_real", "B1_quantized_real",
        "B2_quantized_real", "B3_quantized_real",
        "C0_quantized_real",

        "reference_real",
        "quantized_input_reference_real",
    ]

    kept = 0
    attempts = 0

    with vector_path.open("w", encoding="utf-8") as vf, reference_path.open(
        "w", newline="", encoding="utf-8"
    ) as rf:
        writer = csv.DictWriter(rf, fieldnames=fieldnames)
        writer.writeheader()

        while kept < num_tests:
            attempts += 1

            # Original full-precision Python operands.
            A_raw = [random.uniform(-value_range, value_range) for _ in range(4)]
            B_raw = [random.uniform(-value_range, value_range) for _ in range(4)]
            C_raw = random.uniform(-value_range, value_range)

            # Full-precision Python reference BEFORE Posit quantization.
            reference_real = sum(A_raw[i] * B_raw[i] for i in range(4)) + C_raw

            # Same safety range used for the DNN-like experiment.
            if abs(reference_real) > 5.0:
                continue

            # Quantized operands sent to the VHDL DPU.
            A_hex = [posit_to_hex(x, posit_class, hex_digits) for x in A_raw]
            B_hex = [posit_to_hex(x, posit_class, hex_digits) for x in B_raw]
            C_hex = posit_to_hex(C_raw, posit_class, hex_digits)

            # Decode quantized operands only for secondary/debug analysis.
            A_q = [posit_hex_to_float(x, posit_class) for x in A_hex]
            B_q = [posit_hex_to_float(x, posit_class) for x in B_hex]
            C_q = posit_hex_to_float(C_hex, posit_class)

            quantized_input_reference_real = sum(A_q[i] * B_q[i] for i in range(4)) + C_q

            # VHDL input vector: A0 A1 A2 A3 B0 B1 B2 B3 C0
            vf.write(" ".join(A_hex + B_hex + [C_hex]) + "\n")

            writer.writerow({
                "test_id": kept,

                "A0_hex": A_hex[0],
                "A1_hex": A_hex[1],
                "A2_hex": A_hex[2],
                "A3_hex": A_hex[3],
                "B0_hex": B_hex[0],
                "B1_hex": B_hex[1],
                "B2_hex": B_hex[2],
                "B3_hex": B_hex[3],
                "C0_hex": C_hex,

                "A0_raw": A_raw[0],
                "A1_raw": A_raw[1],
                "A2_raw": A_raw[2],
                "A3_raw": A_raw[3],
                "B0_raw": B_raw[0],
                "B1_raw": B_raw[1],
                "B2_raw": B_raw[2],
                "B3_raw": B_raw[3],
                "C0_raw": C_raw,

                "A0_quantized_real": A_q[0],
                "A1_quantized_real": A_q[1],
                "A2_quantized_real": A_q[2],
                "A3_quantized_real": A_q[3],
                "B0_quantized_real": B_q[0],
                "B1_quantized_real": B_q[1],
                "B2_quantized_real": B_q[2],
                "B3_quantized_real": B_q[3],
                "C0_quantized_real": C_q,

                "reference_real": reference_real,
                "quantized_input_reference_real": quantized_input_reference_real,
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