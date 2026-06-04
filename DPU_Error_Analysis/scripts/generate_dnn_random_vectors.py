#!/usr/bin/env python3
"""
Generate DNN-like random test vectors for floating-point DPU error analysis.

Implemented formats:
  - fp8  : float8_e4m3 using ml_dtypes
  - fp16 : IEEE-754 binary16
  - fp32 : IEEE-754 binary32

Important:
  reference_real is the full-precision Python reference computed from the
  original random real operands, before quantization to the target format.

  quantized_input_reference_real is also stored for debugging/secondary analysis.
"""

import argparse
import csv
import random
import struct
from pathlib import Path

import numpy as np
from ml_dtypes import float8_e4m3


REPO_EXPERIMENT_DIR = Path("DPU_Error_Analysis/data/dnn_random_10k")


# -----------------------------------------------------------------------------
# FP8 e4m3 helpers
# -----------------------------------------------------------------------------

def float_to_fp8_e4m3_hex(value: float) -> str:
    encoded = np.array([value], dtype=float8_e4m3)
    return format(encoded.view(np.uint8)[0], "02X")


def fp8_e4m3_hex_to_float(hex_string: str) -> float:
    raw = np.array([int(hex_string.strip(), 16)], dtype=np.uint8)
    decoded = raw.view(float8_e4m3)[0]
    return float(decoded)


# -----------------------------------------------------------------------------
# FP16 helpers
# -----------------------------------------------------------------------------

def float_to_fp16_hex(value: float) -> str:
    packed = struct.pack(">e", value)
    return packed.hex().upper()


def fp16_hex_to_float(hex_string: str) -> float:
    raw = bytes.fromhex(hex_string)
    return struct.unpack(">e", raw)[0]


# -----------------------------------------------------------------------------
# FP32 helpers
# -----------------------------------------------------------------------------

def float_to_fp32_hex(value: float) -> str:
    packed = struct.pack(">f", value)
    return packed.hex().upper()


def fp32_hex_to_float(hex_string: str) -> float:
    raw = bytes.fromhex(hex_string)
    return struct.unpack(">f", raw)[0]


# -----------------------------------------------------------------------------
# Generic generator
# -----------------------------------------------------------------------------

def generate_float_format(
    fmt: str,
    num_tests: int,
    seed: int,
    value_range: float,
    encoder,
    decoder,
) -> None:
    random.seed(seed)
    np.random.seed(seed)

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

            # Original full-precision Python random operands.
            A_raw = [random.uniform(-value_range, value_range) for _ in range(4)]
            B_raw = [random.uniform(-value_range, value_range) for _ in range(4)]
            C_raw = random.uniform(-value_range, value_range)

            # Full-precision Python reference BEFORE format quantization.
            reference_real = sum(A_raw[i] * B_raw[i] for i in range(4)) + C_raw

            # Keep same safe DNN-like output range.
            if abs(reference_real) > 5.0:
                continue

            # Quantize operands sent to hardware.
            A_hex = [encoder(x) for x in A_raw]
            B_hex = [encoder(x) for x in B_raw]
            C_hex = encoder(C_raw)

            # Decode quantized operands for secondary/debug reference.
            A_q = [decoder(x) for x in A_hex]
            B_q = [decoder(x) for x in B_hex]
            C_q = decoder(C_hex)

            quantized_input_reference_real = sum(A_q[i] * B_q[i] for i in range(4)) + C_q

            # VHDL vector file: 9 hexadecimal operands per line.
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
    parser.add_argument("--format", required=True, choices=["fp8", "fp16", "fp32"])
    parser.add_argument("--num-tests", type=int, default=10000)
    parser.add_argument("--seed", type=int, default=12345)
    parser.add_argument("--range", type=float, default=1.0, dest="value_range")
    args = parser.parse_args()

    if args.format == "fp8":
        generate_float_format(
            fmt="fp8",
            num_tests=args.num_tests,
            seed=args.seed,
            value_range=args.value_range,
            encoder=float_to_fp8_e4m3_hex,
            decoder=fp8_e4m3_hex_to_float,
        )

    elif args.format == "fp16":
        generate_float_format(
            fmt="fp16",
            num_tests=args.num_tests,
            seed=args.seed,
            value_range=args.value_range,
            encoder=float_to_fp16_hex,
            decoder=fp16_hex_to_float,
        )

    elif args.format == "fp32":
        generate_float_format(
            fmt="fp32",
            num_tests=args.num_tests,
            seed=args.seed,
            value_range=args.value_range,
            encoder=float_to_fp32_hex,
            decoder=fp32_hex_to_float,
        )


if __name__ == "__main__":
    main()