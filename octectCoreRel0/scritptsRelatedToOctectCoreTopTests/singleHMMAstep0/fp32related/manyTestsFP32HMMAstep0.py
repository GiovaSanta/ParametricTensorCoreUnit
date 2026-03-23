import os
import numpy as np

# ============================================================
# Configuration
# ============================================================
NUM_TESTS = 10
SEED = 42

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

OUTPUT_FILE_HUMAN = os.path.join(SCRIPT_DIR, "hmma_step0_fp32_tests.txt")
OUTPUT_FILE_TB = os.path.join(SCRIPT_DIR, "hmma_step0_tb_input_fp32.txt")

VALUE_MIN = -32.0
VALUE_MAX = 32.0

AVOID_SUBNORMAL_RESULTS = True

FP32_MAX = np.finfo(np.float32).max
FP32_TINY = np.finfo(np.float32).tiny


# ============================================================
# Helpers
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


def format_fp32_value(x: np.float32) -> str:
    return f"{float(np.float32(x)):.9g}"


def format_fp32_hex(x: np.float32) -> str:
    bits = np.array([x], dtype=np.float32).view(np.uint32)[0]
    return f"{int(bits):08X}"


def matrix_to_lines_decimal(mat: np.ndarray) -> str:
    lines = []
    for row in mat:
        lines.append(" ".join(format_fp32_value(v) for v in row))
    return "\n".join(lines)


def matrix_to_lines_hex(mat: np.ndarray) -> str:
    lines = []
    for row in mat:
        lines.append(" ".join(format_fp32_hex(np.float32(v)) for v in row))
    return "\n".join(lines)


def random_fp32_matrix(rng: np.random.Generator,
                       low: float = VALUE_MIN,
                       high: float = VALUE_MAX,
                       shape=(4, 4)) -> np.ndarray:
    return rng.uniform(low, high, size=shape).astype(np.float32)


def is_safe_fp32_result(result: np.ndarray) -> bool:
    if not np.all(np.isfinite(result)):
        return False

    abs_r = np.abs(result.astype(np.float64))

    if np.any(abs_r > FP32_MAX):
        return False

    if AVOID_SUBNORMAL_RESULTS:
        bad = (abs_r != 0.0) & (abs_r < FP32_TINY)
        if np.any(bad):
            return False

    return True


def compute_fp32_matmul_add(A: np.ndarray, B: np.ndarray, C: np.ndarray) -> np.ndarray:
    result_fp32 = A.astype(np.float32) @ B.astype(np.float32) + C.astype(np.float32)
    return result_fp32.astype(np.float32)


def generate_safe_triplet(rng: np.random.Generator, max_attempts: int = 10000):
    for _ in range(max_attempts):
        A = random_fp32_matrix(rng)
        B = random_fp32_matrix(rng)
        C = random_fp32_matrix(rng)

        R = compute_fp32_matmul_add(A, B.T, C)

        if is_safe_fp32_result(R):
            return A, B, C, R

    raise RuntimeError("Could not generate a safe FP32 triplet within max_attempts.")


def generate_safe_aux_pair_with_fixed_B(rng: np.random.Generator,
                                        B_fixed: np.ndarray,
                                        max_attempts: int = 10000):
    for _ in range(max_attempts):
        A = random_fp32_matrix(rng)
        C = random_fp32_matrix(rng)

        R = compute_fp32_matmul_add(A, B_fixed.T, C)

        if is_safe_fp32_result(R):
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
    f.write(f"#{title_word} HMMAstep0 test related values(FP32)\n")

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
# Testbench file writers (FP32, aligned with RTL load_pair behavior)
# ============================================================
def encode_fp32_hex(x: np.float32) -> str:
    return format_fp32_hex(np.float32(x))


def write_tb_pair_block_fp32(f, label: str, mat_tg0: np.ndarray, mat_tg4: np.ndarray, pair_idx: int):
    """
    Writes one 8-lane load pass for FP32.

    pair_idx = 0  -> columns 0,1 -> load_pair = "00"
    pair_idx = 1  -> columns 2,3 -> load_pair = "01"

    Lanes:
      0..3 -> tg0 rows 0..3
      4..7 -> tg4 rows 0..3

    This matches the RTL:
      A_buf(lane)(s0)   <= regA_lane
      A_buf(lane)(s0+1) <= regB_lane
    """
    assert pair_idx in (0, 1)

    c0 = 2 * pair_idx
    c1 = c0 + 1
    pair_name = "pair00" if pair_idx == 0 else "pair01"

    f.write(f"#{label} {pair_name}\n")

    # lanes 0..3 = tg0 rows
    for r in range(4):
        portA = encode_fp32_hex(mat_tg0[r, c0])
        portB = encode_fp32_hex(mat_tg0[r, c1])
        f.write(f"#lane{r} tg0 row{r} cols{c0}{c1}\n")
        f.write(f"{portA} {portB}\n")

    # lanes 4..7 = tg4 rows
    for r in range(4):
        lane = r + 4
        portA = encode_fp32_hex(mat_tg4[r, c0])
        portB = encode_fp32_hex(mat_tg4[r, c1])
        f.write(f"#lane{lane} tg4 row{r} cols{c0}{c1}\n")
        f.write(f"{portA} {portB}\n")


def write_tb_test_block_fp32(f,
                             test_idx: int,
                             A00: np.ndarray,
                             A10: np.ndarray,
                             B00: np.ndarray,
                             B01: np.ndarray,
                             C00: np.ndarray,
                             C10: np.ndarray):
    f.write(f"#{ordinal_word(test_idx)} TEST VALUES OF HMMAstep0 (FP32)\n")

    # A loads: pair00 then pair01
    write_tb_pair_block_fp32(f, "A block", A00, A10, pair_idx=0)
    write_tb_pair_block_fp32(f, "A block", A00, A10, pair_idx=1)

    # B loads: pair00 then pair01
    write_tb_pair_block_fp32(f, "B block", B00, B01, pair_idx=0)
    write_tb_pair_block_fp32(f, "B block", B00, B01, pair_idx=1)

    # C loads: pair00 then pair01
    write_tb_pair_block_fp32(f, "C block", C00, C10, pair_idx=0)
    write_tb_pair_block_fp32(f, "C block", C00, C10, pair_idx=1)


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

        f_tb.write("#register file ports content for FP32\n")
        f_tb.write("#<portA> <portB>\n")
        f_tb.write("#For each A/B/C block:\n")
        f_tb.write("#  pair00 loads columns 0,1 into slots 0,1 (load_pair = 00)\n")
        f_tb.write("#  pair01 loads columns 2,3 into slots 2,3 (load_pair = 01)\n")

        for test_idx in range(1, NUM_TESTS + 1):
            A00, B00, C00, D00 = generate_safe_triplet(rng)
            A10, C10, D10 = generate_safe_aux_pair_with_fixed_B(rng, B00)
            _, B01, _, _ = generate_safe_triplet(rng)

            write_human_test_block(
                f_human, test_idx,
                A00, A10, B00, B01, C00, C10, D00, D10
            )

            write_tb_test_block_fp32(
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
