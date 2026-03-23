import os
import numpy as np

# ============================================================
# Configuration
# ============================================================
NUM_TESTS = 10
SEED = 42

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

OUTPUT_FILE_HUMAN = os.path.join(SCRIPT_DIR, "hmma_step0_fp16_tests.txt")
OUTPUT_FILE_TB = os.path.join(SCRIPT_DIR, "hmma_step0_tb_input.txt")

VALUE_MIN = -32.0
VALUE_MAX = 32.0

AVOID_SUBNORMAL_RESULTS = True

FP16_MAX = np.finfo(np.float16).max
FP16_TINY = np.finfo(np.float16).tiny


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


def format_fp16_value(x: np.float16) -> str:
    return f"{float(np.float16(x)):.6g}"


def format_fp16_hex(x: np.float16) -> str:
    bits = np.array([x], dtype=np.float16).view(np.uint16)[0]
    return f"{int(bits):04X}"


def matrix_to_lines_decimal(mat: np.ndarray) -> str:
    lines = []
    for row in mat:
        lines.append(" ".join(format_fp16_value(v) for v in row))
    return "\n".join(lines)


def matrix_to_lines_hex(mat: np.ndarray) -> str:
    lines = []
    for row in mat:
        lines.append(" ".join(format_fp16_hex(np.float16(v)) for v in row))
    return "\n".join(lines)


def random_fp16_matrix(rng: np.random.Generator,
                       low: float = VALUE_MIN,
                       high: float = VALUE_MAX,
                       shape=(4, 4)) -> np.ndarray:
    return rng.uniform(low, high, size=shape).astype(np.float16)


def is_safe_fp16_result(result: np.ndarray) -> bool:
    if not np.all(np.isfinite(result)):
        return False

    abs_r = np.abs(result.astype(np.float32))

    if np.any(abs_r > FP16_MAX):
        return False

    if AVOID_SUBNORMAL_RESULTS:
        bad = (abs_r != 0.0) & (abs_r < FP16_TINY)
        if np.any(bad):
            return False

    return True


def compute_fp16_matmul_add(A: np.ndarray, B: np.ndarray, C: np.ndarray) -> np.ndarray:
    result_fp32 = A.astype(np.float32) @ B.astype(np.float32) + C.astype(np.float32)
    result_fp16 = result_fp32.astype(np.float16)
    return result_fp16


def generate_safe_triplet(rng: np.random.Generator, max_attempts: int = 10000):
    for _ in range(max_attempts):
        A = random_fp16_matrix(rng)
        B = random_fp16_matrix(rng)
        C = random_fp16_matrix(rng)

        R = compute_fp16_matmul_add(A, B.T, C)

        if is_safe_fp16_result(R):
            return A, B, C, R

    raise RuntimeError("Could not generate a safe FP16 triplet within max_attempts.")


def generate_safe_aux_pair_with_fixed_B(rng: np.random.Generator,
                                        B_fixed: np.ndarray,
                                        max_attempts: int = 10000):
    for _ in range(max_attempts):
        A = random_fp16_matrix(rng)
        C = random_fp16_matrix(rng)

        R = compute_fp16_matmul_add(A, B_fixed.T, C)

        if is_safe_fp16_result(R):
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
    f.write(f"#{title_word} HMMAstep0 test related values(FP16)\n")

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
def encode_row_fp16_hex(row: np.ndarray):
    return [format_fp16_hex(np.float16(v)) for v in row]


def pack_row_into_ports(row: np.ndarray):
    """
    Input row: [v0, v1, v2, v3]
    Output:
      portA = enc(v1) + enc(v0)
      portB = enc(v3) + enc(v2)
    Example:
      [0001,0002,0003,0004] -> 00020001 00040003
    """
    h = encode_row_fp16_hex(row)
    portA = h[1] + h[0]
    portB = h[3] + h[2]
    return portA, portB


def write_tb_matrix_block(f, label: str, mat: np.ndarray, base_thread: int):
    f.write(f"#{label}\n")
    for i in range(4):
        thread_id = base_thread + i
        portA, portB = pack_row_into_ports(mat[i])
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
    f.write(f"#{ordinal_word(test_idx)} TEST VALUES OF HMMAstep0 (FP16)\n")

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

        f_tb.write("#register file ports content\n")
        f_tb.write("#<portA> <portB>\n")

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