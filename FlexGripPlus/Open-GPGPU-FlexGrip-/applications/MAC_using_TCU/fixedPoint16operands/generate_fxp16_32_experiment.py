#!/usr/bin/env python3
"""
Generate one FlexGrip FXP16_32 16x16 TCU experiment.

Format:
  A/B: signed_6_M10  -> signed 16-bit, 10 fractional bits
  C/D: signed_11_M20 -> signed 32-bit, 20 fractional bits

The file includes two validation references:

1) Raw-domain fixed-point reference:
     D_raw = C_raw + A_raw @ B_raw
   This is the bit-correct hardware reference.

2) DPU-error-analysis-style reference:
     D_real = C_original_real + A_original_real @ B_original_real
   where original real operands are before fixed-point quantization.
   The rounded FXP32 encoding of this real reference is also written.
"""

import os
import numpy as np

SEED = 42

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

OUTPUT_FILE_HUMAN = os.path.join(
    SCRIPT_DIR,
    "hmma_8instr_dualTC_4octects_fxp16fxp32_single_experiment_compact.txt"
)
OUTPUT_FILE_TB = os.path.join(
    SCRIPT_DIR,
    "hmma_8instr_dualTC_4octects_fxp16fxp32_single_experiment_tb_input.txt"
)

# FlexGrip automated flow uses the compact human-readable experiment file plus
# global_mem.mif generation. The legacy standalone TB input file is optional.
GENERATE_TB_INPUT = False

FULL_SIZE = 16

# RTL-derived fixed-point formats:
#   X,Y : signed_6_M10  -> 16-bit, frac_bits = 10
#   A,R : signed_11_M20 -> 32-bit, frac_bits = 20
FXP16_FRAC_BITS = 10
FXP32_FRAC_BITS = 20

FXP16_MIN_RAW = -32768
FXP16_MAX_RAW = 32767
FXP32_MIN_RAW = -2147483648
FXP32_MAX_RAW = 2147483647

AB_REAL_MIN = -2.0
AB_REAL_MAX = 2.0
C_REAL_MIN = 0.0
C_REAL_MAX = 0.0


def clamp_int16(x: int) -> int:
    return max(FXP16_MIN_RAW, min(FXP16_MAX_RAW, int(x)))


def clamp_int32(x: int) -> int:
    return max(FXP32_MIN_RAW, min(FXP32_MAX_RAW, int(x)))


def fxp16_to_hex(raw: int) -> str:
    return f"{(int(raw) & 0xFFFF):04X}"


def fxp32_to_hex(raw: int) -> str:
    return f"{(int(raw) & 0xFFFFFFFF):08X}"


def raw_to_real(raw: int, frac_bits: int) -> float:
    return float(int(raw)) / float(1 << frac_bits)


def real_to_fxp_raw_sat(x: float, frac_bits: int, bits: int) -> int:
    scaled = int(round(x * (1 << frac_bits)))

    if bits == 16:
        return clamp_int16(scaled)
    if bits == 32:
        return clamp_int32(scaled)

    raise ValueError("Unsupported bit-width")


def random_fxp16_matrix_with_real(rng: np.random.Generator, shape=(FULL_SIZE, FULL_SIZE)):
    real = rng.uniform(AB_REAL_MIN, AB_REAL_MAX, size=shape).astype(np.float64)
    raw = np.empty(shape, dtype=np.int32)

    for r in range(shape[0]):
        for c in range(shape[1]):
            raw[r, c] = real_to_fxp_raw_sat(float(real[r, c]), FXP16_FRAC_BITS, 16)

    return raw, real


def random_fxp32_matrix_with_real(rng: np.random.Generator, shape=(FULL_SIZE, FULL_SIZE)):
    real = rng.uniform(C_REAL_MIN, C_REAL_MAX, size=shape).astype(np.float64)
    raw = np.empty(shape, dtype=np.int64)

    for r in range(shape[0]):
        for c in range(shape[1]):
            raw[r, c] = real_to_fxp_raw_sat(float(real[r, c]), FXP32_FRAC_BITS, 32)

    return raw, real


def is_safe_fxp32_matrix(mat: np.ndarray) -> bool:
    return np.all(mat >= FXP32_MIN_RAW) and np.all(mat <= FXP32_MAX_RAW)


def fxp16fxp32_matmul_add(A_raw: np.ndarray, B_raw: np.ndarray, C_raw: np.ndarray) -> np.ndarray:
    prod_acc = A_raw.astype(np.int64) @ B_raw.astype(np.int64)
    result = prod_acc + C_raw.astype(np.int64)

    out = np.empty(result.shape, dtype=np.int64)
    for r in range(result.shape[0]):
        for c in range(result.shape[1]):
            out[r, c] = clamp_int32(int(result[r, c]))

    return out


def quantize_real_matrix_to_fxp32_raw(mat: np.ndarray) -> np.ndarray:
    out = np.empty(mat.shape, dtype=np.int64)
    for r in range(mat.shape[0]):
        for c in range(mat.shape[1]):
            out[r, c] = real_to_fxp_raw_sat(float(mat[r, c]), FXP32_FRAC_BITS, 32)
    return out


def matrix_to_lines_real_from_raw(mat: np.ndarray, frac_bits: int) -> str:
    return "\n".join(
        " ".join(f"{raw_to_real(int(v), frac_bits):.8f}" for v in row)
        for row in mat
    )


def matrix_to_lines_full_precision_real(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(f"{float(v):.12g}" for v in row)
        for row in mat
    )


def matrix_to_lines_hex_fxp16(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(fxp16_to_hex(int(v)) for v in row)
        for row in mat
    )


def matrix_to_lines_hex_fxp32(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(fxp32_to_hex(int(v)) for v in row)
        for row in mat
    )


def write_matrix_with_encoded_fxp16(f, name: str, mat: np.ndarray):
    f.write(f"#{name} decoded_real_signed_6_M10\n")
    f.write(matrix_to_lines_real_from_raw(mat, FXP16_FRAC_BITS) + "\n")
    f.write(f"#{name} encoded\n")
    f.write(matrix_to_lines_hex_fxp16(mat) + "\n")


def write_matrix_with_encoded_fxp32(f, name: str, mat: np.ndarray):
    f.write(f"#{name} decoded_real_signed_11_M20\n")
    f.write(matrix_to_lines_real_from_raw(mat, FXP32_FRAC_BITS) + "\n")
    f.write(f"#{name} encoded\n")
    f.write(matrix_to_lines_hex_fxp32(mat) + "\n")


def build_experiment(rng: np.random.Generator, max_attempts: int = 20000) -> dict:
    for _ in range(max_attempts):
        A_raw, A_original_real = random_fxp16_matrix_with_real(rng)
        B_raw, B_original_real = random_fxp16_matrix_with_real(rng)
        C_raw, C_original_real = random_fxp32_matrix_with_real(rng)

        # Raw-domain reference: what the fixed-point hardware should reproduce exactly
        # from the quantized operands.
        D_raw_reference = fxp16fxp32_matmul_add(A_raw, B_raw, C_raw)
        if not is_safe_fxp32_matrix(D_raw_reference):
            continue

        # DPU-error-analysis-style reference from original real operands.
        D_full_precision_real_reference = (
            A_original_real.astype(np.float64) @ B_original_real.astype(np.float64)
            + C_original_real.astype(np.float64)
        )

        D_full_precision_real_reference_rounded = quantize_real_matrix_to_fxp32_raw(
            D_full_precision_real_reference
        )
        if not is_safe_fxp32_matrix(D_full_precision_real_reference_rounded):
            continue

        return {
            "A_raw": A_raw,
            "B_raw": B_raw,
            "C_raw": C_raw,
            "A_original_real": A_original_real,
            "B_original_real": B_original_real,
            "C_original_real": C_original_real,
            "D_raw_reference": D_raw_reference,
            "D_full_precision_real_reference": D_full_precision_real_reference,
            "D_full_precision_real_reference_rounded": D_full_precision_real_reference_rounded,
        }

    raise RuntimeError("Could not generate a safe FXP16_32 16x16 experiment.")


def write_human_file(f, exp: dict) -> None:
    f.write("#Compact FlexGrip FXP16_32 experiment.\n")
    f.write("#RTL-derived fixed-point interpretation:\n")
    f.write("#  X,Y : signed_6_M10  -> 16-bit with 10 fractional bits\n")
    f.write("#  A,R : signed_11_M20 -> 32-bit with 20 fractional bits\n")
    f.write("#Raw-domain fixed-point reference: D_raw = C_raw + A_raw @ B_raw, saturated to signed 32-bit.\n")
    f.write("#DPU-like error reference uses original random real operands before fixed-point quantization.\n")
    f.write("#Only B is transposed by the global_mem generator for hardware feeding.\n\n")

    write_matrix_with_encoded_fxp16(f, "FULL_A_16x16", exp["A_raw"])
    write_matrix_with_encoded_fxp16(f, "FULL_B_16x16", exp["B_raw"])
    write_matrix_with_encoded_fxp32(f, "FULL_C_16x16", exp["C_raw"])

    # Exact hardware-correctness reference: raw-domain quantized-input fixed-point math.
    write_matrix_with_encoded_fxp32(f, "FULL_D_16x16_one_shot_reference", exp["D_raw_reference"])

    # DPU-error-analysis-style reference: original random real operands before quantization.
    f.write("\n#FULL_A_16x16_original_real_before_fxp_quantization\n")
    f.write(matrix_to_lines_full_precision_real(exp["A_original_real"]) + "\n")
    f.write("#FULL_B_16x16_original_real_before_fxp_quantization\n")
    f.write(matrix_to_lines_full_precision_real(exp["B_original_real"]) + "\n")
    f.write("#FULL_C_16x16_original_real_before_fxp_quantization\n")
    f.write(matrix_to_lines_full_precision_real(exp["C_original_real"]) + "\n")

    f.write("#FULL_D_16x16_full_precision_real_reference decoded_real\n")
    f.write(matrix_to_lines_full_precision_real(exp["D_full_precision_real_reference"]) + "\n")
    f.write("#FULL_D_16x16_full_precision_real_reference_rounded_fxp32 encoded\n")
    f.write(matrix_to_lines_hex_fxp32(exp["D_full_precision_real_reference_rounded"]) + "\n")


def main() -> None:
    print("Script started...")
    print(f"Writing compact human-readable file to: {OUTPUT_FILE_HUMAN}")

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

    print(f"Generated compact human-readable experiment file: '{OUTPUT_FILE_HUMAN}'")


if __name__ == "__main__":
    main()
