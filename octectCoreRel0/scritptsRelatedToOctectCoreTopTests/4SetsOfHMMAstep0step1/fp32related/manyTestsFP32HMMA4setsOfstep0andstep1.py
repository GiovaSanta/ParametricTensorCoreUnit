import os
import numpy as np

# ============================================================
# Configuration
# ============================================================
SEED = 42

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

OUTPUT_FILE_HUMAN = os.path.join(
    SCRIPT_DIR,
    "hmma_8instr_fp32_single_experiment.txt"
)
OUTPUT_FILE_TB = os.path.join(
    SCRIPT_DIR,
    "hmma_8instr_fp32_single_experiment_tb_input.txt"
)

VALUE_MIN = -32.0
VALUE_MAX = 32.0

AVOID_SUBNORMAL_RESULTS = True

FP32_MAX = np.finfo(np.float32).max
FP32_TINY = np.finfo(np.float32).tiny

FULL_SIZE = 16
BLOCK = 4


# ============================================================
# Basic helpers
# ============================================================
def format_fp32_value(x: np.float32) -> str:
    return f"{float(np.float32(x)):.9g}"


def format_fp32_hex(x: np.float32) -> str:
    bits = np.array([x], dtype=np.float32).view(np.uint32)[0]
    return f"{int(bits):08X}"


def matrix_to_lines_decimal(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(format_fp32_value(v) for v in row)
        for row in mat
    )


def matrix_to_lines_hex(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(format_fp32_hex(np.float32(v)) for v in row)
        for row in mat
    )


def random_fp32_matrix(
    rng: np.random.Generator,
    low: float = VALUE_MIN,
    high: float = VALUE_MAX,
    shape=(FULL_SIZE, FULL_SIZE)
) -> np.ndarray:
    return rng.uniform(low, high, size=shape).astype(np.float32)


def is_safe_fp32_matrix(mat: np.ndarray) -> bool:
    if not np.all(np.isfinite(mat)):
        return False

    abs_m = np.abs(mat.astype(np.float64))

    if np.any(abs_m > FP32_MAX):
        return False

    if AVOID_SUBNORMAL_RESULTS:
        bad = (abs_m != 0.0) & (abs_m < FP32_TINY)
        if np.any(bad):
            return False

    return True


def fp32_matmul_add(A: np.ndarray, B: np.ndarray, C: np.ndarray) -> np.ndarray:
    """
    Golden/reference model:
      compute A @ B + C in fp32
    """
    result = A.astype(np.float32) @ B.astype(np.float32) + C.astype(np.float32)
    return result.astype(np.float32)


def get_block(M: np.ndarray, br: int, bc: int) -> np.ndarray:
    r0 = br * BLOCK
    c0 = bc * BLOCK
    return M[r0:r0 + BLOCK, c0:c0 + BLOCK].copy()


# ============================================================
# Human-readable file writers
# ============================================================
def write_matrix_with_encoded(f, name: str, mat: np.ndarray):
    f.write(f"#{name}\n")
    f.write(matrix_to_lines_decimal(mat) + "\n")
    f.write(f"#{name} encoded\n")
    f.write(matrix_to_lines_hex(mat) + "\n")


def write_set_block(
    f,
    set_idx: int,
    A_top: np.ndarray,
    A_bot: np.ndarray,
    B_left: np.ndarray,
    B_right: np.ndarray,
    B_left_T_for_HMMA: np.ndarray,
    B_right_T_for_HMMA: np.ndarray,
    C_top: np.ndarray,
    C_bot: np.ndarray,
    C_right_top: np.ndarray,
    C_right_bot: np.ndarray,
    D00: np.ndarray,
    D10: np.ndarray,
    D01: np.ndarray,
    D11: np.ndarray
):
    a_top_name = f"A0{set_idx}"
    a_bot_name = f"A1{set_idx}"
    b_left_name = f"B{set_idx}0"
    b_right_name = f"B{set_idx}1"

    c00_name = f"C00_set{set_idx}"
    c10_name = f"C10_set{set_idx}"
    c01_name = f"C01_set{set_idx}"
    c11_name = f"C11_set{set_idx}"

    f.write(f"#================ SET {set_idx} ================\n")

    write_matrix_with_encoded(f, a_top_name, A_top)
    write_matrix_with_encoded(f, a_bot_name, A_bot)

    write_matrix_with_encoded(f, b_left_name, B_left)
    write_matrix_with_encoded(f, b_right_name, B_right)

    write_matrix_with_encoded(f, f"{b_left_name}_T_for_HMMA", B_left_T_for_HMMA)
    write_matrix_with_encoded(f, f"{b_right_name}_T_for_HMMA", B_right_T_for_HMMA)

    write_matrix_with_encoded(f, c00_name, C_top)
    write_matrix_with_encoded(f, c10_name, C_bot)
    write_matrix_with_encoded(f, c01_name, C_right_top)
    write_matrix_with_encoded(f, c11_name, C_right_bot)

    f.write(f"#golden STEP0_D00_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D00) + "\n")
    f.write(f"#golden STEP0_D00_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D00) + "\n")

    f.write(f"#golden STEP0_D10_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D10) + "\n")
    f.write(f"#golden STEP0_D10_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D10) + "\n")

    f.write(f"#golden STEP1_D01_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D01) + "\n")
    f.write(f"#golden STEP1_D01_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D01) + "\n")

    f.write(f"#golden STEP1_D11_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D11) + "\n")
    f.write(f"#golden STEP1_D11_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D11) + "\n")


# ============================================================
# Testbench file writers
# FP32 needs pair00 / pair01 sequencing.
# For B only, the rows sent to TB are rows of B^T, because hardware
# expects the B buffer in column-major / transposed-fed form.
# ============================================================
def encode_row_fp32_hex(row: np.ndarray):
    return [format_fp32_hex(np.float32(v)) for v in row]


def pack_row_pair00(row: np.ndarray):
    """
    pair00 -> columns 0 and 1
    portA = enc(v0)
    portB = enc(v1)
    """
    h = encode_row_fp32_hex(row)
    return h[0], h[1]


def pack_row_pair01(row: np.ndarray):
    """
    pair01 -> columns 2 and 3
    portA = enc(v2)
    portB = enc(v3)
    """
    h = encode_row_fp32_hex(row)
    return h[2], h[3]


def write_tb_matrix_block_pair00(f, label: str, mat: np.ndarray, base_thread: int):
    f.write(f"#{label}\n")
    for i in range(4):
        thread_id = base_thread + i
        portA, portB = pack_row_pair00(mat[i])
        f.write(f"#thread{thread_id}\n")
        f.write(f"{portA} {portB}\n")


def write_tb_matrix_block_pair01(f, label: str, mat: np.ndarray, base_thread: int):
    f.write(f"#{label}\n")
    for i in range(4):
        thread_id = base_thread + i
        portA, portB = pack_row_pair01(mat[i])
        f.write(f"#thread{thread_id}\n")
        f.write(f"{portA} {portB}\n")


def write_tb_set0(
    f,
    A00: np.ndarray,
    A10: np.ndarray,
    B00T: np.ndarray,
    B01T: np.ndarray,
    C00: np.ndarray,
    C10: np.ndarray,
    C01: np.ndarray,
    C11: np.ndarray
):
    f.write("#================ SET 0 ================\n")

    # A: 2 cycles
    write_tb_matrix_block_pair00(f, "tg0 A00 submatrix pair00", A00, 0)
    write_tb_matrix_block_pair00(f, "tg4 A10 submatrix pair00", A10, 16)
    write_tb_matrix_block_pair01(f, "tg0 A00 submatrix pair01", A00, 0)
    write_tb_matrix_block_pair01(f, "tg4 A10 submatrix pair01", A10, 16)

    # B fed as transpose-layout for hardware
    write_tb_matrix_block_pair00(f, "tg0 B00_T_for_HMMA pair00", B00T, 0)
    write_tb_matrix_block_pair00(f, "tg4 B01_T_for_HMMA pair00", B01T, 16)
    write_tb_matrix_block_pair01(f, "tg0 B00_T_for_HMMA pair01", B00T, 0)
    write_tb_matrix_block_pair01(f, "tg4 B01_T_for_HMMA pair01", B01T, 16)

    # step0 accumulators
    write_tb_matrix_block_pair00(f, "tg0 C00 submatrix pair00", C00, 0)
    write_tb_matrix_block_pair00(f, "tg4 C10 submatrix pair00", C10, 16)
    write_tb_matrix_block_pair01(f, "tg0 C00 submatrix pair01", C00, 0)
    write_tb_matrix_block_pair01(f, "tg4 C10 submatrix pair01", C10, 16)

    # step1 accumulators
    write_tb_matrix_block_pair00(f, "tg0 C01 submatrix pair00", C01, 0)
    write_tb_matrix_block_pair00(f, "tg4 C11 submatrix pair00", C11, 16)
    write_tb_matrix_block_pair01(f, "tg0 C01 submatrix pair01", C01, 0)
    write_tb_matrix_block_pair01(f, "tg4 C11 submatrix pair01", C11, 16)


def write_tb_later_set(
    f,
    set_idx: int,
    A_top_name: str,
    A_top: np.ndarray,
    A_bot_name: str,
    A_bot: np.ndarray,
    B_left_t_name: str,
    B_left_t: np.ndarray,
    B_right_t_name: str,
    B_right_t: np.ndarray,
):
    f.write(f"#================ SET {set_idx} ================\n")

    # A
    write_tb_matrix_block_pair00(f, f"{A_top_name} pair00", A_top, 0)
    write_tb_matrix_block_pair00(f, f"{A_bot_name} pair00", A_bot, 16)
    write_tb_matrix_block_pair01(f, f"{A_top_name} pair01", A_top, 0)
    write_tb_matrix_block_pair01(f, f"{A_bot_name} pair01", A_bot, 16)

    # B fed transposed
    write_tb_matrix_block_pair00(f, f"{B_left_t_name} pair00", B_left_t, 0)
    write_tb_matrix_block_pair00(f, f"{B_right_t_name} pair00", B_right_t, 16)
    write_tb_matrix_block_pair01(f, f"{B_left_t_name} pair01", B_left_t, 0)
    write_tb_matrix_block_pair01(f, f"{B_right_t_name} pair01", B_right_t, 16)


# ============================================================
# Experiment builder
# ============================================================
def build_single_safe_experiment(rng: np.random.Generator, max_attempts: int = 20000):
    for _ in range(max_attempts):
        A = random_fp32_matrix(rng)
        B = random_fp32_matrix(rng)
        C = random_fp32_matrix(rng)

        # one-shot full reference with NORMAL math, no transpose
        D_full_one_shot = fp32_matmul_add(A, B, C)

        if not is_safe_fp32_matrix(D_full_one_shot):
            continue

        staged = {}

        prev_D00 = None
        prev_D10 = None
        prev_D01 = None
        prev_D11 = None

        ok = True

        for s in range(4):
            # A blocks
            A_top = get_block(A, 0, s)   # A0s
            A_bot = get_block(A, 1, s)   # A1s

            # B blocks in normal mathematical orientation
            B_left = get_block(B, s, 0)   # Bs0
            B_right = get_block(B, s, 1)  # Bs1

            # What the TB feeds to hardware for B
            B_left_T_for_HMMA = B_left.T.astype(np.float32)
            B_right_T_for_HMMA = B_right.T.astype(np.float32)

            # Accumulator inputs
            if s == 0:
                C_top = get_block(C, 0, 0)        # C00
                C_bot = get_block(C, 1, 0)        # C10
                C_right_top = get_block(C, 0, 1)  # C01
                C_right_bot = get_block(C, 1, 1)  # C11
            else:
                C_top = prev_D00.copy()
                C_bot = prev_D10.copy()
                C_right_top = prev_D01.copy()
                C_right_bot = prev_D11.copy()

            # Golden math uses NON-transposed B
            D00 = fp32_matmul_add(A_top, B_left, C_top)
            D10 = fp32_matmul_add(A_bot, B_left, C_bot)

            D01 = fp32_matmul_add(A_top, B_right, C_right_top)
            D11 = fp32_matmul_add(A_bot, B_right, C_right_bot)

            for M in (
                A_top, A_bot,
                B_left, B_right,
                B_left_T_for_HMMA, B_right_T_for_HMMA,
                C_top, C_bot, C_right_top, C_right_bot,
                D00, D10, D01, D11
            ):
                if not is_safe_fp32_matrix(M):
                    ok = False
                    break

            if not ok:
                break

            staged[s] = {
                "A_top": A_top,
                "A_bot": A_bot,
                "B_left": B_left,
                "B_right": B_right,
                "B_left_T_for_HMMA": B_left_T_for_HMMA,
                "B_right_T_for_HMMA": B_right_T_for_HMMA,
                "C_top": C_top,
                "C_bot": C_bot,
                "C_right_top": C_right_top,
                "C_right_bot": C_right_bot,
                "D00": D00,
                "D10": D10,
                "D01": D01,
                "D11": D11,
            }

            prev_D00 = D00
            prev_D10 = D10
            prev_D01 = D01
            prev_D11 = D11

        if not ok:
            continue

        D_chained_top_left_8x8 = np.block([
            [staged[3]["D00"], staged[3]["D01"]],
            [staged[3]["D10"], staged[3]["D11"]],
        ]).astype(np.float32)

        if not is_safe_fp32_matrix(D_chained_top_left_8x8):
            continue

        return {
            "A": A,
            "B": B,
            "C": C,
            "D_full_one_shot": D_full_one_shot,
            "staged": staged,
            "D_chained_top_left_8x8": D_chained_top_left_8x8,
            "D_expected_top_left_8x8": D_full_one_shot[:8, :8].copy(),
        }

    raise RuntimeError("Could not generate a safe single FP32 16x16 experiment.")


# ============================================================
# Main writers
# ============================================================
def write_human_file(f, exp):
    f.write("#Single 16x16 GEMM-ACC experiment decomposed into 4 HMMA step0/step1 sets (FP32)\n")
    f.write("#Golden math uses standard A @ B + C.\n")
    f.write("#Only the B payload written to the TB file is transposed for hardware feeding.\n\n")

    write_matrix_with_encoded(f, "FULL_A_16x16", exp["A"])
    write_matrix_with_encoded(f, "FULL_B_16x16", exp["B"])
    write_matrix_with_encoded(f, "FULL_C_16x16", exp["C"])
    write_matrix_with_encoded(f, "FULL_D_16x16_one_shot_reference", exp["D_full_one_shot"])

    for s in range(4):
        f.write("\n")
        blk = exp["staged"][s]
        write_set_block(
            f,
            s,
            blk["A_top"],
            blk["A_bot"],
            blk["B_left"],
            blk["B_right"],
            blk["B_left_T_for_HMMA"],
            blk["B_right_T_for_HMMA"],
            blk["C_top"],
            blk["C_bot"],
            blk["C_right_top"],
            blk["C_right_bot"],
            blk["D00"],
            blk["D10"],
            blk["D01"],
            blk["D11"],
        )

    f.write("\n#FINAL_CHAINED_8x8_FROM_STAGED_FP32\n")
    f.write("#D00_final encoded\n")
    f.write(matrix_to_lines_hex(exp["staged"][3]["D00"]) + "\n")
    f.write("#D01_final encoded\n")
    f.write(matrix_to_lines_hex(exp["staged"][3]["D01"]) + "\n")
    f.write("#D10_final encoded\n")
    f.write(matrix_to_lines_hex(exp["staged"][3]["D10"]) + "\n")
    f.write("#D11_final encoded\n")
    f.write(matrix_to_lines_hex(exp["staged"][3]["D11"]) + "\n")

    f.write("\n#FINAL_IDEAL_8x8_ONE_SHOT_REFERENCE\n")
    f.write("#D_expected_top_left_8x8 decoded\n")
    f.write(matrix_to_lines_decimal(exp["D_expected_top_left_8x8"]) + "\n")
    f.write("#D_expected_top_left_8x8 encoded\n")
    f.write(matrix_to_lines_hex(exp["D_expected_top_left_8x8"]) + "\n")


def write_tb_file(f, exp):
    f.write("#register file ports content for FP32\n")
    f.write("#<portA> <portB>\n")
    f.write("#pair00 -> cols 0,1 ; pair01 -> cols 2,3\n")
    f.write("#Single experiment = 4 HMMA set pairs (step0 + step1)\n")
    f.write("#For FP32, A/B/C loads are split over two cycles: pair00 then pair01.\n")
    f.write("#B is written in transposed form for the hardware feed only.\n")
    f.write("#Only set0 contains external C inputs.\n")
    f.write("#For sets 1..3 accumulator inputs must be provided by previous computed results inside the TB.\n\n")

    s0 = exp["staged"][0]
    write_tb_set0(
        f,
        s0["A_top"],
        s0["A_bot"],
        s0["B_left_T_for_HMMA"],
        s0["B_right_T_for_HMMA"],
        s0["C_top"],
        s0["C_bot"],
        s0["C_right_top"],
        s0["C_right_bot"],
    )

    f.write("\n")
    s1 = exp["staged"][1]
    write_tb_later_set(
        f,
        1,
        "A01", s1["A_top"],
        "A11", s1["A_bot"],
        "B10_T_for_HMMA", s1["B_left_T_for_HMMA"],
        "B11_T_for_HMMA", s1["B_right_T_for_HMMA"],
    )

    f.write("\n")
    s2 = exp["staged"][2]
    write_tb_later_set(
        f,
        2,
        "A02", s2["A_top"],
        "A12", s2["A_bot"],
        "B20_T_for_HMMA", s2["B_left_T_for_HMMA"],
        "B21_T_for_HMMA", s2["B_right_T_for_HMMA"],
    )

    f.write("\n")
    s3 = exp["staged"][3]
    write_tb_later_set(
        f,
        3,
        "A03", s3["A_top"],
        "A13", s3["A_bot"],
        "B30_T_for_HMMA", s3["B_left_T_for_HMMA"],
        "B31_T_for_HMMA", s3["B_right_T_for_HMMA"],
    )


# ============================================================
# Main
# ============================================================
def main():
    print("Script started...")
    print(f"Writing human-readable file to: {OUTPUT_FILE_HUMAN}")
    print(f"Writing TB input file to: {OUTPUT_FILE_TB}")

    rng = np.random.default_rng(SEED)

    exp = build_single_safe_experiment(rng)

    with open(OUTPUT_FILE_HUMAN, "w", encoding="utf-8") as f_human:
        write_human_file(f_human, exp)

    with open(OUTPUT_FILE_TB, "w", encoding="utf-8") as f_tb:
        write_tb_file(f_tb, exp)

    print(f"Generated human-readable experiment file: '{OUTPUT_FILE_HUMAN}'")
    print(f"Generated TB input file: '{OUTPUT_FILE_TB}'")


if __name__ == "__main__":
    main()