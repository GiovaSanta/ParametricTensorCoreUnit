#!/usr/bin/env python3
"""
Generate DNN-like random test vectors for LNS16 4_9 DPU error analysis.

LNS16 format:
  - bits 15:14 = 01 for normal finite values
  - bit 13 = sign
  - bits 12:0 = signed fixed-point log2 value
  - fractional log bits W_F = 9

Important:
  reference_real is the full-precision Python reference computed from the
  original random real operands, before quantization to LNS16.

  quantized_input_reference_real is also stored for debugging/secondary analysis.
"""

import argparse
import csv
import math
import random
from pathlib import Path


W_F = 9
SCALE = 1 << W_F

REPO_EXPERIMENT_DIR = Path("DPU_Error_Analysis/data/dnn_random_10k")


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


def lns_int_to_hex(x: int) -> str:
    return f"{x & 0xFFFF:04X}"


def generate_lns16(num_tests: int, seed: int, value_range: float) -> None:
    random.seed(seed)

    vectors_dir = REPO_EXPERIMENT_DIR / "vectors"
    references_dir = REPO_EXPERIMENT_DIR / "references"

    vectors_dir.mkdir(parents=True, exist_ok=True)
    references_dir.mkdir(parents=True, exist_ok=True)

    vector_path = vectors_dir / "lns16_vectors.txt"
    reference_path = references_dir / "lns16_reference.csv"

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

            # LNS cannot represent arbitrary tiny values well, because it stores log2(|x|).
            # So we use DNN-like values around zero but avoid magnitudes too close to zero.
            def rand_nonzero() -> float:
                sign = -1.0 if random.random() < 0.5 else 1.0
                mag = random.uniform(0.05, value_range)
                return sign * mag

            A_raw = [rand_nonzero() for _ in range(4)]
            B_raw = [rand_nonzero() for _ in range(4)]

            if random.random() < 0.10:
                C_raw = 0.0
            else:
                C_raw = rand_nonzero()

            # Full-precision Python reference BEFORE LNS16 quantization.
            reference_real = sum(A_raw[i] * B_raw[i] for i in range(4)) + C_raw

            # Same safe DNN-like output range used for the other formats.
            if abs(reference_real) > 5.0:
                continue

            try:
                A_int = [encode_lns_real(x) for x in A_raw]
                B_int = [encode_lns_real(x) for x in B_raw]
                C_int = encode_lns_real(C_raw)
            except ValueError:
                continue

            A_hex = [lns_int_to_hex(x) for x in A_int]
            B_hex = [lns_int_to_hex(x) for x in B_int]
            C_hex = lns_int_to_hex(C_int)

            # Decode quantized LNS values only for secondary/debug reference.
            A_q = [decode_lns_int(x) for x in A_int]
            B_q = [decode_lns_int(x) for x in B_int]
            C_q = decode_lns_int(C_int)

            quantized_input_reference_real = sum(A_q[i] * B_q[i] for i in range(4)) + C_q

            # VHDL vector file: A0 A1 A2 A3 B0 B1 B2 B3 C0
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

    print(f"Generated {kept} LNS16 vectors.")
    print(f"Attempts: {attempts}")
    print(f"Vector file:    {vector_path}")
    print(f"Reference file: {reference_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--num-tests", type=int, default=10000)
    parser.add_argument("--seed", type=int, default=12345)
    parser.add_argument("--range", type=float, default=1.0, dest="value_range")
    args = parser.parse_args()

    generate_lns16(args.num_tests, args.seed, args.value_range)


if __name__ == "__main__":
    main()