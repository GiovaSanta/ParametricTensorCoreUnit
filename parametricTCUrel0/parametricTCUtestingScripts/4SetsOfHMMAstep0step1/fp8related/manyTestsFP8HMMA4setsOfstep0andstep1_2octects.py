import os
import math
import numpy as np

# ============================================================
# Configuration
# ============================================================
SEED = 42

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

OUTPUT_FILE_HUMAN = os.path.join(
    SCRIPT_DIR,
    "hmma_8instr_2octects_fp8_single_experiment.txt"
)
OUTPUT_FILE_TB = os.path.join(
    SCRIPT_DIR,
    "hmma_8instr_2octects_fp8_single_experiment_tb_input.txt"
)

VALUE_MIN = -8.0
VALUE_MAX = 8.0

AVOID_SUBNORMAL_RESULTS = True

FULL_SIZE = 16
BLOCK = 4

# FP8 E4M3 parameters
FP8_EXP_BITS = 4
FP8_MAN_BITS = 3
FP8_EXP_BIAS = 7


# ============================================================
# FP8 E4M3 encode / decode helpers
# ============================================================
def fp8e4m3_decode_byte(code: int) -> float:
    code &= 0xFF
    sign = -1.0 if (code & 0x80) else 1.0
    exp_field = (code >> 3) & 0xF
    frac_field = code & 0x7

    if exp_field == 0:
        if frac_field == 0:
            return -0.0 if sign < 0 else 0.0
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
    table = []
    for code in range(256):
        val = fp8e4m3_decode_byte(code)
        if math.isfinite(val):
            table.append((code, float(val)))
    return table


FP8_FINITE_TABLE = _build_fp8_finite_table()

FP8_MAX = max(abs(v) for _, v in FP8_FINITE_TABLE if math.isfinite(v))

FP8_TINY_NORMAL = min(
    v for code, v in FP8_FINITE_TABLE
    if v > 0.0 and ((code >> 3) & 0xF) != 0
)


def fp8e4m3_encode_nearest(x: float) -> int:
    if math.isnan(x):
        return 0x79
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
            if absval < best_absval or (absval == best_absval and code < best_code):
                best_code = code
                best_absval = absval

    return best_code


def fp8e4m3_quantize_value(x: float) -> float:
    return fp8e4m3_decode_byte(fp8e4m3_encode_nearest(x))


def quantize_matrix_to_fp8(mat: np.ndarray) -> np.ndarray:
    out = np.empty(mat.shape, dtype=np.float32)
    for r in range(mat.shape[0]):
        for c in range(mat.shape[1]):
            out[r, c] = fp8e4m3_quantize_value(float(mat[r, c]))
    return out


# ============================================================
# Basic helpers
# ============================================================
def format_fp8_value(x: float) -> str:
    return f"{float(x):.6g}"


def format_fp8_hex(x: float) -> str:
    return f"{fp8e4m3_encode_nearest(float(x)):02X}"


def matrix_to_lines_decimal(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(format_fp8_value(v) for v in row)
        for row in mat
    )


def matrix_to_lines_hex(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(format_fp8_hex(v) for v in row)
        for row in mat
    )


def random_fp8_matrix(
    rng: np.random.Generator,
    low: float = VALUE_MIN,
    high: float = VALUE_MAX,
    shape=(FULL_SIZE, FULL_SIZE)
) -> np.ndarray:
    raw = rng.uniform(low, high, size=shape).astype(np.float32)
    return quantize_matrix_to_fp8(raw)


def is_safe_fp8_matrix(mat: np.ndarray) -> bool:
    if not np.all(np.isfinite(mat)):
        return False

    abs_m = np.abs(mat.astype(np.float32))

    if np.any(abs_m > FP8_MAX):
        return False

    if AVOID_SUBNORMAL_RESULTS:
        bad = (abs_m != 0.0) & (abs_m < FP8_TINY_NORMAL)
        if np.any(bad):
            return False

    return True


def fp8_matmul_add(A: np.ndarray, B: np.ndarray, C: np.ndarray) -> np.ndarray:
    """
    Golden/reference model:
      compute in fp32, quantize to FP8 E4M3 at the end.
    """
    result_fp32 = A.astype(np.float32) @ B.astype(np.float32) + C.astype(np.float32)
    return quantize_matrix_to_fp8(result_fp32)


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
    A00: np.ndarray,
    A10: np.ndarray,
    A20: np.ndarray,
    A30: np.ndarray,
    B_left: np.ndarray,
    B_right: np.ndarray,
    B_left_T: np.ndarray,
    B_right_T: np.ndarray,
    C00: np.ndarray,
    C10: np.ndarray,
    C01: np.ndarray,
    C11: np.ndarray,
    C20: np.ndarray,
    C30: np.ndarray,
    C21: np.ndarray,
    C31: np.ndarray,
    D00: np.ndarray,
    D10: np.ndarray,
    D01: np.ndarray,
    D11: np.ndarray,
    D20: np.ndarray,
    D30: np.ndarray,
    D21: np.ndarray,
    D31: np.ndarray,
):
    f.write(f"#================ SET {set_idx} ================\n")

    write_matrix_with_encoded(f, f"A0{set_idx}", A00)
    write_matrix_with_encoded(f, f"A1{set_idx}", A10)
    write_matrix_with_encoded(f, f"A2{set_idx}", A20)
    write_matrix_with_encoded(f, f"A3{set_idx}", A30)

    write_matrix_with_encoded(f, f"B{set_idx}0", B_left)
    write_matrix_with_encoded(f, f"B{set_idx}1", B_right)

    write_matrix_with_encoded(f, f"B{set_idx}0_T_for_HMMA", B_left_T)
    write_matrix_with_encoded(f, f"B{set_idx}1_T_for_HMMA", B_right_T)

    write_matrix_with_encoded(f, f"C00_set{set_idx}", C00)
    write_matrix_with_encoded(f, f"C10_set{set_idx}", C10)
    write_matrix_with_encoded(f, f"C01_set{set_idx}", C01)
    write_matrix_with_encoded(f, f"C11_set{set_idx}", C11)

    write_matrix_with_encoded(f, f"C20_set{set_idx}", C20)
    write_matrix_with_encoded(f, f"C30_set{set_idx}", C30)
    write_matrix_with_encoded(f, f"C21_set{set_idx}", C21)
    write_matrix_with_encoded(f, f"C31_set{set_idx}", C31)

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

    f.write(f"#golden STEP0_D20_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D20) + "\n")
    f.write(f"#golden STEP0_D20_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D20) + "\n")

    f.write(f"#golden STEP0_D30_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D30) + "\n")
    f.write(f"#golden STEP0_D30_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D30) + "\n")

    f.write(f"#golden STEP1_D21_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D21) + "\n")
    f.write(f"#golden STEP1_D21_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D21) + "\n")

    f.write(f"#golden STEP1_D31_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D31) + "\n")
    f.write(f"#golden STEP1_D31_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D31) + "\n")


# ============================================================
# Testbench file writers
# ============================================================
def encode_row_fp8_hex(row: np.ndarray):
    return [format_fp8_hex(v) for v in row]


def pack_row_into_ports_fp8(row: np.ndarray):
    """
    row = [v0, v1, v2, v3]

    pack 4 FP8 values into one 32-bit port:
      portA = enc(v3) + enc(v2) + enc(v1) + enc(v0)

    portB stays zero.
    """
    h = encode_row_fp8_hex(row)
    portA = h[3] + h[2] + h[1] + h[0]
    portB = "00000000"
    return portA, portB


def write_tb_matrix_block(f, label: str, mat: np.ndarray, base_lane: int):
    f.write(f"#{label}\n")
    for i in range(4):
        lane_id = base_lane + i
        portA, portB = pack_row_into_ports_fp8(mat[i])
        f.write(f"#lane{lane_id}\n")
        f.write(f"{portA} {portB}\n")


def write_tb_set0(
    f,
    A00, A10, A20, A30,
    B00T, B01T,
    C00, C10, C01, C11,
    C20, C30, C21, C31
):
    f.write("#================ SET 0 ================\n")

    write_tb_matrix_block(f, "oct0 A00", A00, 0)
    write_tb_matrix_block(f, "oct0 A10", A10, 4)
    write_tb_matrix_block(f, "oct1 A20", A20, 8)
    write_tb_matrix_block(f, "oct1 A30", A30, 12)

    write_tb_matrix_block(f, "oct0 B00_T_for_HMMA", B00T, 0)
    write_tb_matrix_block(f, "oct0 B01_T_for_HMMA", B01T, 4)
    write_tb_matrix_block(f, "oct1 B00_T_for_HMMA", B00T, 8)
    write_tb_matrix_block(f, "oct1 B01_T_for_HMMA", B01T, 12)

    write_tb_matrix_block(f, "oct0 C00", C00, 0)
    write_tb_matrix_block(f, "oct0 C10", C10, 4)
    write_tb_matrix_block(f, "oct1 C20", C20, 8)
    write_tb_matrix_block(f, "oct1 C30", C30, 12)

    write_tb_matrix_block(f, "oct0 C01", C01, 0)
    write_tb_matrix_block(f, "oct0 C11", C11, 4)
    write_tb_matrix_block(f, "oct1 C21", C21, 8)
    write_tb_matrix_block(f, "oct1 C31", C31, 12)


def write_tb_later_set(
    f,
    set_idx: int,
    A00, A10, A20, A30,
    B_left_T, B_right_T
):
    f.write(f"#================ SET {set_idx} ================\n")

    write_tb_matrix_block(f, f"oct0 A0{set_idx}", A00, 0)
    write_tb_matrix_block(f, f"oct0 A1{set_idx}", A10, 4)
    write_tb_matrix_block(f, f"oct1 A2{set_idx}", A20, 8)
    write_tb_matrix_block(f, f"oct1 A3{set_idx}", A30, 12)

    write_tb_matrix_block(f, f"oct0 B{set_idx}0_T_for_HMMA", B_left_T, 0)
    write_tb_matrix_block(f, f"oct0 B{set_idx}1_T_for_HMMA", B_right_T, 4)
    write_tb_matrix_block(f, f"oct1 B{set_idx}0_T_for_HMMA", B_left_T, 8)
    write_tb_matrix_block(f, f"oct1 B{set_idx}1_T_for_HMMA", B_right_T, 12)


# ============================================================
# Experiment builder
# ============================================================
def build_two_octect_safe_experiment(
    rng: np.random.Generator,
    max_attempts: int = 20000
):
    for _ in range(max_attempts):
        A = random_fp8_matrix(rng)
        B = random_fp8_matrix(rng)
        C = random_fp8_matrix(rng)

        D_full_one_shot = fp8_matmul_add(A, B, C)

        if not is_safe_fp8_matrix(D_full_one_shot):
            continue

        staged = {}

        prev_D00 = prev_D10 = prev_D01 = prev_D11 = None
        prev_D20 = prev_D30 = prev_D21 = prev_D31 = None

        ok = True

        for s in range(4):
            A00 = get_block(A, 0, s)
            A10 = get_block(A, 1, s)
            A20 = get_block(A, 2, s)
            A30 = get_block(A, 3, s)

            B_left_full = get_block(B, s, 0)
            B_right_full = get_block(B, s, 1)

            B_left_T = B_left_full.T.astype(np.float32)
            B_right_T = B_right_full.T.astype(np.float32)

            if s == 0:
                C00 = get_block(C, 0, 0)
                C10 = get_block(C, 1, 0)
                C01 = get_block(C, 0, 1)
                C11 = get_block(C, 1, 1)

                C20 = get_block(C, 2, 0)
                C30 = get_block(C, 3, 0)
                C21 = get_block(C, 2, 1)
                C31 = get_block(C, 3, 1)
            else:
                C00 = prev_D00.copy()
                C10 = prev_D10.copy()
                C01 = prev_D01.copy()
                C11 = prev_D11.copy()

                C20 = prev_D20.copy()
                C30 = prev_D30.copy()
                C21 = prev_D21.copy()
                C31 = prev_D31.copy()

            D00 = fp8_matmul_add(A00, B_left_full, C00)
            D10 = fp8_matmul_add(A10, B_left_full, C10)
            D01 = fp8_matmul_add(A00, B_right_full, C01)
            D11 = fp8_matmul_add(A10, B_right_full, C11)

            D20 = fp8_matmul_add(A20, B_left_full, C20)
            D30 = fp8_matmul_add(A30, B_left_full, C30)
            D21 = fp8_matmul_add(A20, B_right_full, C21)
            D31 = fp8_matmul_add(A30, B_right_full, C31)

            for M in (
                A00, A10, A20, A30,
                B_left_full, B_right_full,
                B_left_T, B_right_T,
                C00, C10, C01, C11,
                C20, C30, C21, C31,
                D00, D10, D01, D11,
                D20, D30, D21, D31
            ):
                if not is_safe_fp8_matrix(M):
                    ok = False
                    break

            if not ok:
                break

            staged[s] = {
                "A00": A00, "A10": A10, "A20": A20, "A30": A30,
                "B_left_full": B_left_full,
                "B_right_full": B_right_full,
                "B_left_T": B_left_T,
                "B_right_T": B_right_T,
                "C00": C00, "C10": C10, "C01": C01, "C11": C11,
                "C20": C20, "C30": C30, "C21": C21, "C31": C31,
                "D00": D00, "D10": D10, "D01": D01, "D11": D11,
                "D20": D20, "D30": D30, "D21": D21, "D31": D31,
            }

            prev_D00, prev_D10, prev_D01, prev_D11 = D00, D10, D01, D11
            prev_D20, prev_D30, prev_D21, prev_D31 = D20, D30, D21, D31

        if not ok:
            continue

        D_chained_top_left_16x8 = np.block([
            [staged[3]["D00"], staged[3]["D01"]],
            [staged[3]["D10"], staged[3]["D11"]],
            [staged[3]["D20"], staged[3]["D21"]],
            [staged[3]["D30"], staged[3]["D31"]],
        ]).astype(np.float32)

        if not is_safe_fp8_matrix(D_chained_top_left_16x8):
            continue

        return {
            "A": A,
            "B": B,
            "C": C,
            "D_full_one_shot": D_full_one_shot,
            "staged": staged,
            "D_chained_top_left_16x8": D_chained_top_left_16x8,
            "D_expected_top_left_16x8": D_full_one_shot[:, :8].copy(),
        }

    raise RuntimeError("Could not generate a safe two-octect FP8 16x16 experiment.")


# ============================================================
# Main writers
# ============================================================
def write_human_file(f, exp):
    f.write("#Single 16x16 GEMM-ACC experiment decomposed into 4 HMMA step0/step1 sets (FP8-E4M3, 2 octects)\n")
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
            blk["A00"], blk["A10"], blk["A20"], blk["A30"],
            blk["B_left_full"], blk["B_right_full"],
            blk["B_left_T"], blk["B_right_T"],
            blk["C00"], blk["C10"], blk["C01"], blk["C11"],
            blk["C20"], blk["C30"], blk["C21"], blk["C31"],
            blk["D00"], blk["D10"], blk["D01"], blk["D11"],
            blk["D20"], blk["D30"], blk["D21"], blk["D31"],
        )

    f.write("\n#FINAL_CHAINED_16x8_FROM_STAGED_FP8\n")
    for name in ("D00", "D01", "D10", "D11", "D20", "D21", "D30", "D31"):
        f.write(f"#{name}_final encoded\n")
        f.write(matrix_to_lines_hex(exp["staged"][3][name]) + "\n")

    f.write("\n#FINAL_IDEAL_16x8_ONE_SHOT_REFERENCE\n")
    f.write("#D_expected_top_left_16x8 decoded\n")
    f.write(matrix_to_lines_decimal(exp["D_expected_top_left_16x8"]) + "\n")
    f.write("#D_expected_top_left_16x8 encoded\n")
    f.write(matrix_to_lines_hex(exp["D_expected_top_left_16x8"]) + "\n")


def write_tb_file(f, exp):
    f.write("#register file ports content for FP8 E4M3, 2 octects\n")
    f.write("#<portA> <portB>\n")
    f.write("#Each 32-bit portA contains one packed 1x4 FP8 row\n")
    f.write("#Byte order: [v3 v2 v1 v0], so v0 is the least significant byte\n")
    f.write("#portB is written as 00000000\n")
    f.write("#Single experiment = 4 HMMA set pairs (step0 + step1)\n")
    f.write("#16 lanes total:\n")
    f.write("#  lanes 0..3   -> octect0 top tg\n")
    f.write("#  lanes 4..7   -> octect0 bottom tg\n")
    f.write("#  lanes 8..11  -> octect1 top tg\n")
    f.write("#  lanes 12..15 -> octect1 bottom tg\n")
    f.write("#Only set0 contains external C inputs.\n")
    f.write("#For sets 1..3 accumulator inputs must be provided by previous computed results inside the TB.\n\n")

    s0 = exp["staged"][0]
    write_tb_set0(
        f,
        s0["A00"], s0["A10"], s0["A20"], s0["A30"],
        s0["B_left_T"], s0["B_right_T"],
        s0["C00"], s0["C10"], s0["C01"], s0["C11"],
        s0["C20"], s0["C30"], s0["C21"], s0["C31"]
    )

    for s in range(1, 4):
        f.write("\n")
        blk = exp["staged"][s]
        write_tb_later_set(
            f,
            s,
            blk["A00"], blk["A10"], blk["A20"], blk["A30"],
            blk["B_left_T"], blk["B_right_T"]
        )


# ============================================================
# Main
# ============================================================
def main():
    print("Script started...")
    print(f"Writing human-readable file to: {OUTPUT_FILE_HUMAN}")
    print(f"Writing TB input file to: {OUTPUT_FILE_TB}")

    rng = np.random.default_rng(SEED)

    exp = build_two_octect_safe_experiment(rng)

    with open(OUTPUT_FILE_HUMAN, "w", encoding="utf-8") as f_human:
        write_human_file(f_human, exp)

    with open(OUTPUT_FILE_TB, "w", encoding="utf-8") as f_tb:
        write_tb_file(f_tb, exp)

    print(f"Generated human-readable experiment file: '{OUTPUT_FILE_HUMAN}'")
    print(f"Generated TB input file: '{OUTPUT_FILE_TB}'")


if __name__ == "__main__":
    main()