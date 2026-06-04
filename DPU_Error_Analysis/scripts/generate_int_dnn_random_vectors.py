#!/usr/bin/env python3
"""
Generate integer-domain random test vectors for INT DPU error analysis.

Implemented:
  - int8_16:
      A/B: signed 8-bit integers
      C/R: signed 16-bit integers

  - int16_32:
      A/B: signed 16-bit integers
      C/R: signed 32-bit integers

Important:
  This is NOT a scaled-real quantization experiment.
  Python generates integer operands directly, computes the exact integer
  dot-product reference, then writes the two's-complement hex operands
  consumed by the VHDL DPU.

For each vector:
  reference_int = A0*B0 + A1*B1 + A2*B2 + A3*B3 + C0
"""

import argparse
import csv
import random
from pathlib import Path


REPO_EXPERIMENT_DIR = Path("DPU_Error_Analysis/data/dnn_random_10k")


FORMAT_CONFIG = {
    "int8_16": {
        "input_width": 8,
        "output_width": 16,
        "default_operand_range": 10,
        "default_c_range": 100,
    },
    "int16_32": {
        "input_width": 16,
        "output_width": 32,
        "default_operand_range": 1000,
        "default_c_range": 100000,
    },
}


def signed_limits(width: int) -> tuple[int, int]:
    return -(1 << (width - 1)), (1 << (width - 1)) - 1


def signed_int_to_hex(value: int, width: int) -> str:
    min_val, max_val = signed_limits(width)
    if not (min_val <= value <= max_val):
        raise ValueError(f"value {value} is outside signed {width}-bit range [{min_val}, {max_val}]")

    if value < 0:
        value = (1 << width) + value

    hex_digits = width // 4
    return f"{value & ((1 << width) - 1):0{hex_digits}X}"


def generate_int_format(
    fmt: str,
    num_tests: int,
    seed: int,
    operand_range: int | None,
    c_range: int | None,
) -> None:
    cfg = FORMAT_CONFIG[fmt]

    input_width = cfg["input_width"]
    output_width = cfg["output_width"]

    if operand_range is None:
        operand_range = cfg["default_operand_range"]
    if c_range is None:
        c_range = cfg["default_c_range"]

    input_min, input_max = signed_limits(input_width)
    output_min, output_max = signed_limits(output_width)

    if operand_range > max(abs(input_min), abs(input_max)):
        raise ValueError(f"operand_range={operand_range} is too large for signed {input_width}-bit input")

    if c_range > max(abs(output_min), abs(output_max)):
        raise ValueError(f"c_range={c_range} is too large for signed {output_width}-bit accumulator")

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
        "A0_int", "A1_int", "A2_int", "A3_int",
        "B0_int", "B1_int", "B2_int", "B3_int",
        "C0_int",
        "reference_int",
        "input_width",
        "output_width",
        "operand_range",
        "c_range",
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

            A = [random.randint(-operand_range, operand_range) for _ in range(4)]
            B = [random.randint(-operand_range, operand_range) for _ in range(4)]
            C0 = random.randint(-c_range, c_range)

            reference_int = sum(A[i] * B[i] for i in range(4)) + C0

            # Keep only safe, non-overflowing output-domain cases.
            if not (output_min <= reference_int <= output_max):
                continue

            A_hex = [signed_int_to_hex(x, input_width) for x in A]
            B_hex = [signed_int_to_hex(x, input_width) for x in B]
            C_hex = signed_int_to_hex(C0, output_width)

            vf.write(" ".join(A_hex + B_hex + [C_hex]) + "\n")

            writer.writerow({
                "test_id": kept,
                "A0_hex": A_hex[0], "A1_hex": A_hex[1], "A2_hex": A_hex[2], "A3_hex": A_hex[3],
                "B0_hex": B_hex[0], "B1_hex": B_hex[1], "B2_hex": B_hex[2], "B3_hex": B_hex[3],
                "C0_hex": C_hex,
                "A0_int": A[0], "A1_int": A[1], "A2_int": A[2], "A3_int": A[3],
                "B0_int": B[0], "B1_int": B[1], "B2_int": B[2], "B3_int": B[3],
                "C0_int": C0,
                "reference_int": reference_int,
                "input_width": input_width,
                "output_width": output_width,
                "operand_range": operand_range,
                "c_range": c_range,
            })

            kept += 1

    print(f"Generated {kept} {fmt.upper()} integer-domain vectors.")
    print(f"Attempts: {attempts}")
    print(f"Operand range:  [-{operand_range}, {operand_range}]")
    print(f"C0 range:       [-{c_range}, {c_range}]")
    print(f"Vector file:    {vector_path}")
    print(f"Reference file: {reference_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--format", required=True, choices=sorted(FORMAT_CONFIG.keys()))
    parser.add_argument("--num-tests", type=int, default=10000)
    parser.add_argument("--seed", type=int, default=12345)
    parser.add_argument("--operand-range", type=int, default=None)
    parser.add_argument("--c-range", type=int, default=None)
    args = parser.parse_args()

    generate_int_format(
        fmt=args.format,
        num_tests=args.num_tests,
        seed=args.seed,
        operand_range=args.operand_range,
        c_range=args.c_range,
    )


if __name__ == "__main__":
    main()
