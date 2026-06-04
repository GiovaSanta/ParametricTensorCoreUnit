#!/usr/bin/env python3
"""
Generate DNN-like random test vectors for fixed-point DPU error analysis.

Implemented:
  - fxp16_32:
      A/B: signed 16-bit fixed point, 10 fractional bits
      C/R: signed 32-bit fixed point, 20 fractional bits

  - fxp8_16:
      A/B: signed 8-bit fixed point, 5 fractional bits
      C/R: signed 16-bit fixed point, 10 fractional bits

Important:
  The reference_real column is the full-precision Python reference computed
  from the original random real operands, before fixed-point quantization.
"""

import argparse
import csv
import random
from pathlib import Path

from fxpmath import Fxp


REPO_EXPERIMENT_DIR = Path("DPU_Error_Analysis/data/dnn_random_10k")


FORMAT_CONFIG = {
    "fxp16_32": {
        "input_width": 16,
        "input_frac": 10,
        "output_width": 32,
        "output_frac": 20,
    },
    "fxp8_16": {
        "input_width": 8,
        "input_frac": 5,
        "output_width": 16,
        "output_frac": 10,
    },
}


def fxp_quantize(value: float, width: int, frac: int) -> Fxp:
    return Fxp(value, signed=True, n_word=width, n_frac=frac)


def fxp_to_hex(x: Fxp, width: int) -> str:
    hex_digits = width // 4
    h = x.hex()[2:].upper()
    return h.zfill(hex_digits)[-hex_digits:]


def generate_fxp_format(fmt: str, num_tests: int, seed: int, value_range: float) -> None:
    cfg = FORMAT_CONFIG[fmt]

    input_width = cfg["input_width"]
    input_frac = cfg["input_frac"]
    output_width = cfg["output_width"]
    output_frac = cfg["output_frac"]

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

        "A0_quantized_real", "A1_quantized_real", "A2_quantized_real", "A3_quantized_real",
        "B0_quantized_real", "B1_quantized_real", "B2_quantized_real", "B3_quantized_real",
        "C0_quantized_real",

        "reference_real",
        "quantized_input_reference_real",
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

            # Full-precision Python reference from original real operands.
            reference_real = sum(A_raw[i] * B_raw[i] for i in range(4)) + C_raw

            # Keep same safe output range.
            if abs(reference_real) > 5.0:
                continue

            # Quantize operands sent to hardware.
            A_fxp = [fxp_quantize(x, input_width, input_frac) for x in A_raw]
            B_fxp = [fxp_quantize(x, input_width, input_frac) for x in B_raw]
            C_fxp = fxp_quantize(C_raw, output_width, output_frac)

            A_hex = [fxp_to_hex(x, input_width) for x in A_fxp]
            B_hex = [fxp_to_hex(x, input_width) for x in B_fxp]
            C_hex = fxp_to_hex(C_fxp, output_width)

            A_q = [float(x) for x in A_fxp]
            B_q = [float(x) for x in B_fxp]
            C_q = float(C_fxp)

            # This is kept only for debugging/secondary analysis.
            quantized_input_reference_real = sum(A_q[i] * B_q[i] for i in range(4)) + C_q

            vf.write(" ".join(A_hex + B_hex + [C_hex]) + "\n")

            writer.writerow({
                "test_id": kept,

                "A0_hex": A_hex[0], "A1_hex": A_hex[1], "A2_hex": A_hex[2], "A3_hex": A_hex[3],
                "B0_hex": B_hex[0], "B1_hex": B_hex[1], "B2_hex": B_hex[2], "B3_hex": B_hex[3],
                "C0_hex": C_hex,

                "A0_raw": A_raw[0], "A1_raw": A_raw[1], "A2_raw": A_raw[2], "A3_raw": A_raw[3],
                "B0_raw": B_raw[0], "B1_raw": B_raw[1], "B2_raw": B_raw[2], "B3_raw": B_raw[3],
                "C0_raw": C_raw,

                "A0_quantized_real": A_q[0], "A1_quantized_real": A_q[1],
                "A2_quantized_real": A_q[2], "A3_quantized_real": A_q[3],
                "B0_quantized_real": B_q[0], "B1_quantized_real": B_q[1],
                "B2_quantized_real": B_q[2], "B3_quantized_real": B_q[3],
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

    generate_fxp_format(args.format, args.num_tests, args.seed, args.value_range)


if __name__ == "__main__":
    main()