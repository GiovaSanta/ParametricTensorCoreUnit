import os
import math
import numpy as np

# ============================================================
# Configuration
# ============================================================
NUM_TESTS = 10
SEED = 42

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

OUTPUT_FILE_HUMAN = os.path.join(SCRIPT_DIR, "hmma_step0_fp8_tests.txt")
OUTPUT_FILE_TB = os.path.join(SCRIPT_DIR, "hmma_step0_tb_input_fp8.txt")

VALUE_MIN = -8.0
VALUE_MAX = 8.0

AVOID_SUBNORMAL_RESULTS = True

# FP8 E4M3 parameters
FP8_EXP_BITS = 4
FP8_MAN_BITS = 3
FP8_EXP_BIAS = 7


# ============================================================
# FP8 E4M3 encode / decode helpers
# ============================================================
def fp8e4m3_decode_byte(code: int) -> float:
    """
    Decode one 8-bit E4M3 value to Python float.
    Assumes IEEE-like layout:
      sign[7], exp[6:3], frac[2:0]
    exp=15 -> Inf/NaN
    exp=0  -> zero/subnormal
    """
    code &= 0xFF
    sign = -1.0 if (code & 0x80) else 1.0
    exp_field = (code >> 3) & 0xF
    frac_field = code & 0x7

    if exp_field == 0:
        if frac_field == 0:
            return -0.0 if sign < 0 else 0.0
        # subnormal
        mant = frac_field / (2 ** FP8_MAN_BITS)
        return sign * (2 ** (1 - FP8_EXP_BIAS)) * mant

    if exp_field == 0xF:
        if frac_field == 0:
            return math.copysign(math.inf, sign)
        return math.nan

    mant = 1.0 + frac_field / (2 ** FP8_MAN_BITS)
    exp_unbiased = exp_field - FP8_EXP_BIAS
    return sign * mant * (2 ** exp_unbiased)


def _build_fp8_finite_table():
    """
    Build a table of all finite FP8 E4M3 values.
    Used for nearest-value quantization.
    """
    table = []
    for code in range(256):
        val = fp8e4m3_decode_byte(code)
        if math.isfinite(val):
            table.append((code, float(val)))
    return table


FP8_FINITE_TABLE = _build_fp8_finite_table()

# largest finite representable magnitude
FP8_MAX = max(abs(v) for _, v in FP8_FINITE_TABLE if math.isfinite(v))

# smallest positive normal
FP8_TINY_NORMAL = min(
    v for code, v in FP8_FINITE_TABLE
    if v > 0.0 and ((code >> 3) & 0xF) != 0
)


def fp8e4m3_encode_nearest(x: float) -> int:
    """
    Quantize a Python float to the nearest finite FP8 E4M3 code.

    This is intentionally a high-level quantizer that stays coherent with the
    earlier FP16/FP32 scripts. It is not a bit-accurate FloPoCo reimplementation.
    """
    if math.isnan(x):
        return 0x79  # some quiet-NaN-like pattern
    if math.isinf(x):
        return 0x78 if x > 0 else 0xF8

    best_code = None
    best_dist = None
    best_absval = None

    for code, val in FP8_FINITE_TABLE:
        dist = abs(val - x)
        absval = abs(val)

        if best_dist is None or dist < best_dist:
            best_code = code
            best_dist = dist
            best_absval = absval
        elif dist == best_dist:
            # tie-break: prefer smaller magnitude, then smaller code
            if absval < best_absval or (absval == best_absval and code < best_code):
                best_code = code
                best_absval = absval

    return best_code


def fp8e4m3_quantize_value(x: float) -> float:
    """
    Quantize to FP8 E4M3, then decode back to Python float.
    """
    return fp8e4m3_decode_byte(fp8e4m3_encode_nearest(x))


def format_fp8_value(x: float) -> str:
    return f"{float(x):.6g}"


def format_fp8_hex(x: float) -> str:
    code = fp8e4m3_encode_nearest(float(x))
    return f"{code:02X}"


def quantize_matrix_to_fp8(mat: np.ndarray) -> np.ndarray:
    """
    Quantize every element of a matrix to FP8 E4M3, returning decoded float values.
    """
    out = np.empty(mat.shape, dtype=np.float32)
    for r in range(mat.shape[0]):
        for c in range(mat.shape[1]):
            out[r, c] = fp8e4m3_quantize_value(float(mat[r, c]))
    return out


# ============================================================
# General helpers
# ============================================================
def ordinal_word(n: int) -> str:
    words = {
        1: "FIRST",
        2: "SECOND",
        3: "THIRD",
        4: "FOURTH",
        5: "FIFTH",
        6: "SIXTH",
        7: "SEVENTH",
        8: "EIGHTH",
        9: "NINTH",
        10: "TENTH",
        11: "ELEVENTH",
        12: "TWELFTH",
        13: "THIRTEENTH",
        14: "FOURTEENTH",
        15: "FIFTEENTH",
        16: "SIXTEENTH",
        17: "SEVENTEENTH",
        18: "EIGHTEENTH",
        19: "NINETEENTH",
        20: "TWENTIETH",
    }
    return words.get(n, f"TEST_{n}TH")


def matrix_to_lines_decimal(mat: np.ndarray) -> str:
    lines = []
    for row in mat:
        lines.append(" ".join(format_fp8_value(v) for v in row))
    return "\n".join(lines)


def matrix_to_lines_hex(mat: np.ndarray) -> str:
    lines = []
    for row in mat:
        lines.append(" ".join(format_fp8_hex(v) for v in row))
    return "\n".join(lines)


def random_fp8_matrix(rng: np.random.Generator,
                      low: float = VALUE_MIN,
                      high: float = VALUE_MAX,
                      shape=(4, 4)) -> np.ndarray:
    raw = rng.uniform(low, high, size=shape).astype(np.float32)
    return quantize_matrix_to_fp8(raw)


def is_safe_fp8_result(result: np.ndarray) -> bool:
    if not np.all(np.isfinite(result)):
        return False

    abs_r = np.abs(result.astype(np.float32))

    if np.any(abs_r > FP8_MAX):
        return False

    if AVOID_SUBNORMAL_RESULTS:
        bad = (abs_r != 0.0) & (abs_r < FP8_TINY_NORMAL)
        if np.any(bad):
            return False

    return True


# ============================================================
# Golden model (same philosophy as your FP16 / FP32 scripts)
# ============================================================
def compute_fp8_matmul_add(A: np.ndarray, B: np.ndarray, C: np.ndarray) -> np.ndarray:
    """
    High-level reference, coherent with the FP16 / FP32 scripts:
      - inputs are already quantized to FP8 values
      - math is performed in float32
      - result is quantized to FP8 only at the end

    This is NOT the hardware-faithful chained-FMA model.
    """
    result_fp32 = A.astype(np.float32) @ B.astype(np.float32) + C.astype(np.float32)
    result_fp8 = quantize_matrix_to_fp8(result_fp32)
    return result_fp8


def generate_safe_triplet(rng: np.random.Generator, max_attempts: int = 10000):
    for _ in range(max_attempts):
        A = random_fp8_matrix(rng)
        B = random_fp8_matrix(rng)
        C = random_fp8_matrix(rng)

        R = compute_fp8_matmul_add(A, B.T, C)

        if is_safe_fp8_result(R):
            return A, B, C, R

    raise RuntimeError("Could not generate a safe FP8 triplet within max_attempts.")


def generate_safe_aux_pair_with_fixed_B(rng: np.random.Generator,
                                        B_fixed: np.ndarray,
                                        max_attempts: int = 10000):
    for _ in range(max_attempts):
        A = random_fp8_matrix(rng)
        C = random_fp8_matrix(rng)

        R = compute_fp8_matmul_add(A, B_fixed.T, C)

        if is_safe_fp8_result(R):
            return A, C, R

    raise RuntimeError("Could not generate a safe (A,C) pair for fixed B within max_attempts.")


# ============================================================
# Human-readable file writers
# ============================================================
def write_matrix_with_encoded(f, name: str, mat: np.ndarray):
    f.write(f"#{name}\n")
    f.write(matrix_to_lines_decimal(mat) + "\n")
    f.write(f"#{name} encoded\n")
    f.write(matrix_to_lines_hex(mat) + "\n")


def write_human_test_block(f,
                           test_idx: int,
                           A00: np.ndarray,
                           A10: np.ndarray,
                           B00: np.ndarray,
                           B01: np.ndarray,
                           C00: np.ndarray,
                           C10: np.ndarray,
                           D00: np.ndarray,
                           D10: np.ndarray):
    title_word = ordinal_word(test_idx).lower().capitalize()
    f.write(f"#{title_word} HMMAstep0 test related values(FP8-E4M3)\n")

    write_matrix_with_encoded(f, "A00", A00)
    write_matrix_with_encoded(f, "A10", A10)
    write_matrix_with_encoded(f, "B00", B00)
    write_matrix_with_encoded(f, "B01", B01)
    write_matrix_with_encoded(f, "C00", C00)
    write_matrix_with_encoded(f, "C10", C10)

    f.write("#golden D00 decoded (<4 by 4> result submatrix (A00 * B00 + C00 ) )\n")
    f.write(matrix_to_lines_decimal(D00) + "\n")

    f.write("#golden D00 encoded\n")
    f.write(matrix_to_lines_hex(D00) + "\n")

    f.write("#golden D10 decoded (<4 by 4> result submatrix (A10 * B00 + C10 ) )\n")
    f.write(matrix_to_lines_decimal(D10) + "\n")

    f.write("#golden encoded D10\n")
    f.write(matrix_to_lines_hex(D10) + "\n")


# ============================================================
# Testbench file writers
# ============================================================
def encode_row_fp8_hex(row: np.ndarray):
    return [format_fp8_hex(v) for v in row]


def pack_row_into_ports_fp8(row: np.ndarray):
    """
    Coherent packing assumption for FP8:
      row = [v0, v1, v2, v3]

    Pack the 4 FP8 elements into one 32-bit word so that v0 is the least
    significant byte, analogous to how the FP16 script kept the first element
    in the least significant position.

      portA = enc(v3) + enc(v2) + enc(v1) + enc(v0)
      portB = 00000000

    If later your FP8 RTL expects a different byte order or uses portB too,
    only this helper needs to change.
    """
    h = encode_row_fp8_hex(row)
    portA = h[3] + h[2] + h[1] + h[0]
    portB = "00000000"
    return portA, portB


def write_tb_matrix_block(f, label: str, mat: np.ndarray, base_thread: int):
    f.write(f"#{label}\n")
    for i in range(4):
        thread_id = base_thread + i
        portA, portB = pack_row_into_ports_fp8(mat[i])
        f.write(f"#thread{thread_id}\n")
        f.write(f"{portA} {portB}\n")


def write_tb_test_block(f,
                        test_idx: int,
                        A00: np.ndarray,
                        A10: np.ndarray,
                        B00: np.ndarray,
                        B01: np.ndarray,
                        C00: np.ndarray,
                        C10: np.ndarray):
    f.write(f"#{ordinal_word(test_idx)} TEST VALUES OF HMMAstep0 (FP8-E4M3)\n")

    write_tb_matrix_block(f, "tg0 A00 submatrix", A00, 0)
    write_tb_matrix_block(f, "tg4 A10 submatrix", A10, 16)
    write_tb_matrix_block(f, "tg0 B00 submatrix", B00, 0)
    write_tb_matrix_block(f, "tg4 B01 submatrix", B01, 16)
    write_tb_matrix_block(f, "tg0 C00 submatrix", C00, 0)
    write_tb_matrix_block(f, "tg4 C10 submatrix", C10, 16)


# ============================================================
# Main
# ============================================================
def main():
    print("Script started...")
    print(f"Writing human-readable file to: {OUTPUT_FILE_HUMAN}")
    print(f"Writing testbench input file to: {OUTPUT_FILE_TB}")

    rng = np.random.default_rng(SEED)

    with open(OUTPUT_FILE_HUMAN, "w", encoding="utf-8") as f_human, \
         open(OUTPUT_FILE_TB, "w", encoding="utf-8") as f_tb:

        f_tb.write("#register file ports content for FP8 E4M3\n")
        f_tb.write("#<portA> <portB>\n")
        f_tb.write("#Each 32-bit portA contains one packed 1x4 FP8 row\n")
        f_tb.write("#Byte order: [v3 v2 v1 v0], so v0 is the least significant byte\n")
        f_tb.write("#portB is currently written as 00000000\n")

        for test_idx in range(1, NUM_TESTS + 1):
            A00, B00, C00, D00 = generate_safe_triplet(rng)
            A10, C10, D10 = generate_safe_aux_pair_with_fixed_B(rng, B00)
            _, B01, _, _ = generate_safe_triplet(rng)

            write_human_test_block(
                f_human, test_idx,
                A00, A10, B00, B01, C00, C10, D00, D10
            )

            write_tb_test_block(
                f_tb, test_idx,
                A00, A10, B00, B01, C00, C10
            )

            if test_idx != NUM_TESTS:
                f_human.write("\n")
                f_tb.write("\n")

    print(f"Generated {NUM_TESTS} test blocks in '{OUTPUT_FILE_HUMAN}'.")
    print(f"Generated {NUM_TESTS} test blocks in '{OUTPUT_FILE_TB}'.")


if __name__ == "__main__":
    main()
