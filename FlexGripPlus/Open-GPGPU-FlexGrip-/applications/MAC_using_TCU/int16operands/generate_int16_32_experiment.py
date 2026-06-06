#!/usr/bin/env python3
"""
Generate one FlexGrip INT16_32 16x16 TCU experiment.

Format:
  A/B: signed int16
  C/D: signed int32

Reference:
  D = A @ B + C, saturated to signed int32.

The generated file is intentionally compatible with the FlexGrip automation:
  - global_mem.mif generation reads #FULL_A_16x16 encoded,
    #FULL_B_16x16 encoded, and #FULL_C_16x16 encoded.
  - validation reads #FULL_D_16x16_one_shot_reference encoded.
"""

import os
import numpy as np

SEED = 42
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

OUTPUT_FILE_HUMAN = os.path.join(
    SCRIPT_DIR,
    "hmma_8instr_dualTC_4octects_int16int32_single_experiment.txt",
)
OUTPUT_FILE_TB = os.path.join(
    SCRIPT_DIR,
    "hmma_8instr_dualTC_4octects_int16int32_single_experiment_tb_input.txt",
)

# FlexGrip automated flow uses the human-readable experiment file plus
# global_mem.mif generation. The legacy standalone TB input file is optional.
GENERATE_TB_INPUT = False

FULL_SIZE = 16

# Conservative values avoid int32 saturation during 16-term dot products.
AB_VALUE_MIN = -256
AB_VALUE_MAX = 255
C_VALUE_MIN = -4096
C_VALUE_MAX = 4095

INT16_MIN, INT16_MAX = -32768, 32767
INT32_MIN, INT32_MAX = -2147483648, 2147483647


def clamp_int32(x: int) -> int:
    return max(INT32_MIN, min(INT32_MAX, int(x)))


def int16_to_hex(x: int) -> str:
    return f"{(int(x) & 0xFFFF):04X}"


def int32_to_hex(x: int) -> str:
    return f"{(int(x) & 0xFFFFFFFF):08X}"


def matrix_to_lines_decimal(mat: np.ndarray) -> str:
    return "\n".join(" ".join(str(int(v)) for v in row) for row in mat)


def matrix_to_lines_hex_int16(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(int16_to_hex(int(v)) for v in row)
        for row in mat
    )


def matrix_to_lines_hex_int32(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(int32_to_hex(int(v)) for v in row)
        for row in mat
    )


def random_int16_matrix(
    rng: np.random.Generator,
    low: int = AB_VALUE_MIN,
    high: int = AB_VALUE_MAX,
    shape=(FULL_SIZE, FULL_SIZE),
) -> np.ndarray:
    return rng.integers(low, high + 1, size=shape, dtype=np.int32)


def random_int32_matrix(
    rng: np.random.Generator,
    low: int = C_VALUE_MIN,
    high: int = C_VALUE_MAX,
    shape=(FULL_SIZE, FULL_SIZE),
) -> np.ndarray:
    return rng.integers(low, high + 1, size=shape, dtype=np.int64)


def is_safe_int32_matrix(mat: np.ndarray) -> bool:
    return np.all(mat >= INT32_MIN) and np.all(mat <= INT32_MAX)


def int16_int32_matmul_add(
    A: np.ndarray,
    B: np.ndarray,
    C: np.ndarray,
) -> np.ndarray:
    result_i64 = A.astype(np.int64) @ B.astype(np.int64) + C.astype(np.int64)

    out = np.empty(result_i64.shape, dtype=np.int64)
    for r in range(result_i64.shape[0]):
        for c in range(result_i64.shape[1]):
            out[r, c] = clamp_int32(int(result_i64[r, c]))

    return out


def write_matrix_with_encoded_int16(f, name: str, mat: np.ndarray) -> None:
    f.write(f"#{name}\n")
    f.write(matrix_to_lines_decimal(mat) + "\n")
    f.write(f"#{name} encoded\n")
    f.write(matrix_to_lines_hex_int16(mat) + "\n")


def write_matrix_with_encoded_int32(f, name: str, mat: np.ndarray) -> None:
    f.write(f"#{name}\n")
    f.write(matrix_to_lines_decimal(mat) + "\n")
    f.write(f"#{name} encoded\n")
    f.write(matrix_to_lines_hex_int32(mat) + "\n")


def build_experiment(rng: np.random.Generator, max_attempts: int = 20000) -> dict:
    for _ in range(max_attempts):
        A = random_int16_matrix(rng)
        B = random_int16_matrix(rng)
        C = random_int32_matrix(rng)

        D = int16_int32_matmul_add(A, B, C)
        if not is_safe_int32_matrix(D):
            continue

        return {
            "A": A,
            "B": B,
            "C": C,
            "D": D,
        }

    raise RuntimeError("Could not generate a safe INT16_32 16x16 experiment.")


def write_human_file(f, exp: dict) -> None:
    f.write("#FlexGrip INT16_32 experiment.\n")
    f.write("#Format: A/B signed int16, C/D signed int32.\n")
    f.write("#Golden math: D = A @ B + C, saturated to signed int32.\n")
    f.write("#Only B is transposed by the global_mem generator for hardware feeding.\n\n")

    write_matrix_with_encoded_int16(f, "FULL_A_16x16", exp["A"])
    write_matrix_with_encoded_int16(f, "FULL_B_16x16", exp["B"])
    write_matrix_with_encoded_int32(f, "FULL_C_16x16", exp["C"])
    write_matrix_with_encoded_int32(f, "FULL_D_16x16_one_shot_reference", exp["D"])


def main() -> None:
    print("Script started...")
    print(f"Writing human-readable file to: {OUTPUT_FILE_HUMAN}")

    if GENERATE_TB_INPUT:
        print(f"Writing TB input file to: {OUTPUT_FILE_TB}")
    else:
        print("Skipping legacy TB input file generation.")

    rng = np.random.default_rng(SEED)
    exp = build_experiment(rng)

    with open(OUTPUT_FILE_HUMAN, "w", encoding="utf-8") as f_human:
        write_human_file(f_human, exp)

    if GENERATE_TB_INPUT:
        with open(OUTPUT_FILE_TB, "w", encoding="utf-8") as f_tb:
            f_tb.write("# Legacy TB input file intentionally not implemented for this automated flow.\n")
        print(f"Generated TB input file: '{OUTPUT_FILE_TB}'")
    else:
        if os.path.exists(OUTPUT_FILE_TB):
            os.remove(OUTPUT_FILE_TB)
            print(f"Removed stale TB input file: '{OUTPUT_FILE_TB}'")

    print(f"Generated human-readable experiment file: '{OUTPUT_FILE_HUMAN}'")


if __name__ == "__main__":
    main()
