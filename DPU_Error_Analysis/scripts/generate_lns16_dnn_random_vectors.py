#!/usr/bin/env python3
"""
Generate DNN-like random test vectors for LNS16 4_9 DPU error analysis.

Format:
  - 16-bit LNS
  - bits 15:14 = 01 for normal finite values
  - bit 13 = sign
  - bits 12:0 = signed fixed-point log2 value
  - fractional log bits W_F = 9

For each vector:
  R = A0*B0 + A1*B1 + A2*B2 + A3*B3 + C0

The vector file stores encoded LNS16 hexadecimal operands.
The reference CSV stores decoded real operands and the high-precision Python
reference computed from those decoded operands.
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


def lns_hex_to_float(hex_string: str) -> float:
    return decode_lns_int(int(hex_string.strip(), 16))


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

            # Avoid values too close to zero because log encoding becomes extreme.
            # Still DNN-like: small values around zero, but with a minimum magnitude.
            def rand_nonzero():
                sign = -1.0 if random.random() < 0.5 else 1.0
                mag = random.uniform(0.05, value_range)
                return sign * mag

            A_raw = [rand_nonzero() for _ in range(4)]
            B_raw = [rand_nonzero() for _ in range(4)]

            if random.random() < 0.10:
                C_raw = 0.0
            else:
                C_raw = rand_nonzero()

            try:
                A_int = [encode_lns_real(x) for x in A_raw]
                B_int = [encode_lns_real(x) for x in B_raw]
                C_int = encode_lns_real(C_raw)
            except ValueError:
                continue

            A_hex = [lns_int_to_hex(x) for x in A_int]
            B_hex = [lns_int_to_hex(x) for x in B_int]
            C_hex = lns_int_to_hex(C_int)

            A = [decode_lns_int(x) for x in A_int]
            B = [decode_lns_int(x) for x in B_int]
            C = decode_lns_int(C_int)

            reference = sum(A[i] * B[i] for i in range(4)) + C

            # Same safe DNN-like output range used for other formats.
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