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
    "hmma_8instr_dualTC_4octects_posit32_single_experiment.txt"
)
OUTPUT_FILE_TB = os.path.join(
    SCRIPT_DIR,
    "hmma_8instr_dualTC_4octects_posit32_single_experiment_tb_input.txt"
)

VALUE_MIN = -32.0
VALUE_MAX = 32.0

FULL_SIZE = 16
BLOCK = 4

# Standard posit32 commonly uses es=2.
# If your RTL uses a different posit32 flavor, only change POSIT_ES.
POSIT_NBITS = 32
POSIT_ES = 2
POSIT_NAR = 1 << (POSIT_NBITS - 1)
POSIT_MASK = (1 << POSIT_NBITS) - 1

# This mirrors the spirit of the prior scripts:
# compute matmul-add in a wider reference type, then round once to posit32
# at the end of each 4x4 D block.
GOLDEN_MODE = "single_round"


# ============================================================
# Posit helpers
# ============================================================
def posit_useed(es: int) -> float:
    return float(2 ** (2 ** es))


def posit_bits_to_float(ui: int, nbits: int = POSIT_NBITS, es: int = POSIT_ES) -> float:
    ui &= (1 << nbits) - 1

    if ui == 0:
        return 0.0

    nar = 1 << (nbits - 1)
    if ui == nar:
        return float("nan")

    sign = bool(ui & nar)
    if sign:
        ui = ((~ui) + 1) & ((1 << nbits) - 1)

    body_len = nbits - 1
    body = ui & ((1 << body_len) - 1)
    bits = [(body >> i) & 1 for i in range(body_len - 1, -1, -1)]

    reg_bit = bits[0]
    run = 0
    idx = 0
    while idx < len(bits) and bits[idx] == reg_bit:
        run += 1
        idx += 1

    if idx < len(bits):
        idx += 1  # skip regime termination bit

    k = run - 1 if reg_bit == 1 else -run

    exp = 0
    for _ in range(es):
        exp <<= 1
        if idx < len(bits):
            exp |= bits[idx]
            idx += 1

    frac = 1.0
    scale = 0.5
    while idx < len(bits):
        if bits[idx]:
            frac += scale
        scale *= 0.5
        idx += 1

    value = (2.0 ** (k * (1 << es) + exp)) * frac
    return -value if sign else value


def float_to_posit_bits(x: float, nbits: int = POSIT_NBITS, es: int = POSIT_ES) -> int:
    mask = (1 << nbits) - 1
    nar = 1 << (nbits - 1)

    if math.isnan(x) or math.isinf(x):
        return nar
    if x == 0.0:
        return 0

    sign = x < 0.0
    y = abs(float(x))

    useed_exp = 1 << es
    useed = posit_useed(es)

    log2y = math.log2(y)
    k = math.floor(log2y / useed_exp)
    scaled = y / (2.0 ** (k * useed_exp))

    while scaled >= useed:
        k += 1
        scaled /= useed
    while scaled < 1.0:
        k -= 1
        scaled *= useed

    exp = int(math.floor(math.log2(scaled))) if scaled != 1.0 else 0
    if exp >= (1 << es):
        k += 1
        exp = 0

    frac = scaled / (2.0 ** exp) - 1.0

    bits = []
    if k >= 0:
        bits.extend([1] * (k + 1))
        bits.append(0)
    else:
        bits.extend([0] * (-k))
        bits.append(1)

    for i in range(es - 1, -1, -1):
        bits.append((exp >> i) & 1)

    for _ in range(nbits * 2):
        frac *= 2.0
        if frac >= 1.0:
            bits.append(1)
            frac -= 1.0
        else:
            bits.append(0)

    signless_width = nbits - 1

    if len(bits) <= signless_width:
        ui = 0
        for b in bits:
            ui = (ui << 1) | b
        ui <<= (signless_width - len(bits))
    else:
        kept = bits[:signless_width]
        guard = bits[signless_width]
        rest = bits[signless_width + 1:]
        sticky = 1 if any(rest) else 0

        ui = 0
        for b in kept:
            ui = (ui << 1) | b

        lsb = ui & 1
        if guard and (sticky or lsb):
            ui += 1
            if ui >= (1 << signless_width):
                ui = (1 << signless_width) - 1

    ui &= (1 << signless_width) - 1

    if sign:
        ui = ((~ui) + 1) & mask

    return ui


def posit32_quantize_scalar(x: float) -> float:
    bits = float_to_posit_bits(float(x), POSIT_NBITS, POSIT_ES)
    if bits == POSIT_NAR:
        return float("nan")
    return posit_bits_to_float(bits, POSIT_NBITS, POSIT_ES)


def posit32_encode_hex(x: float) -> str:
    bits = float_to_posit_bits(float(x), POSIT_NBITS, POSIT_ES)
    return f"{bits:08X}"


def format_posit32_value(x: float) -> str:
    return f"{float(x):.9g}"


def matrix_to_lines_decimal(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(format_posit32_value(v) for v in row)
        for row in mat
    )


def matrix_to_lines_hex(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(posit32_encode_hex(float(v)) for v in row)
        for row in mat
    )


def quantize_matrix_posit32(mat: np.ndarray) -> np.ndarray:
    out = np.empty(mat.shape, dtype=np.float64)
    it = np.nditer(mat, flags=["multi_index"])
    for x in it:
        out[it.multi_index] = posit32_quantize_scalar(float(x))
    return out


def random_posit32_matrix(
    rng: np.random.Generator,
    low: float = VALUE_MIN,
    high: float = VALUE_MAX,
    shape=(FULL_SIZE, FULL_SIZE)
) -> np.ndarray:
    raw = rng.uniform(low, high, size=shape).astype(np.float64)
    return quantize_matrix_posit32(raw)


def is_safe_posit32_matrix(mat: np.ndarray) -> bool:
    if np.any(np.isnan(mat)):
        return False
    if np.any(np.isinf(mat)):
        return False

    it = np.nditer(mat, flags=["multi_index"])
    for x in it:
        bits = float_to_posit_bits(float(x), POSIT_NBITS, POSIT_ES)
        if bits == POSIT_NAR:
            return False
    return True


def posit32_matmul_add(A: np.ndarray, B: np.ndarray, C: np.ndarray) -> np.ndarray:
    if GOLDEN_MODE != "single_round":
        raise ValueError(f"Unsupported GOLDEN_MODE={GOLDEN_MODE}")

    result_fp64 = A.astype(np.float64) @ B.astype(np.float64) + C.astype(np.float64)
    return quantize_matrix_posit32(result_fp64)


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
    prefix: str,
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
    f.write(f"#================ {prefix} SET {set_idx} ================\n")

    write_matrix_with_encoded(f, f"{prefix}_A0{set_idx}", A00)
    write_matrix_with_encoded(f, f"{prefix}_A1{set_idx}", A10)
    write_matrix_with_encoded(f, f"{prefix}_A2{set_idx}", A20)
    write_matrix_with_encoded(f, f"{prefix}_A3{set_idx}", A30)

    write_matrix_with_encoded(f, f"{prefix}_B{set_idx}L", B_left)
    write_matrix_with_encoded(f, f"{prefix}_B{set_idx}R", B_right)

    write_matrix_with_encoded(f, f"{prefix}_B{set_idx}L_T_for_HMMA", B_left_T)
    write_matrix_with_encoded(f, f"{prefix}_B{set_idx}R_T_for_HMMA", B_right_T)

    write_matrix_with_encoded(f, f"{prefix}_C00_set{set_idx}", C00)
    write_matrix_with_encoded(f, f"{prefix}_C10_set{set_idx}", C10)
    write_matrix_with_encoded(f, f"{prefix}_C01_set{set_idx}", C01)
    write_matrix_with_encoded(f, f"{prefix}_C11_set{set_idx}", C11)

    write_matrix_with_encoded(f, f"{prefix}_C20_set{set_idx}", C20)
    write_matrix_with_encoded(f, f"{prefix}_C30_set{set_idx}", C30)
    write_matrix_with_encoded(f, f"{prefix}_C21_set{set_idx}", C21)
    write_matrix_with_encoded(f, f"{prefix}_C31_set{set_idx}", C31)

    f.write(f"#golden {prefix} STEP0_D00_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D00) + "\n")
    f.write(f"#golden {prefix} STEP0_D00_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D00) + "\n")

    f.write(f"#golden {prefix} STEP0_D10_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D10) + "\n")
    f.write(f"#golden {prefix} STEP0_D10_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D10) + "\n")

    f.write(f"#golden {prefix} STEP1_D01_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D01) + "\n")
    f.write(f"#golden {prefix} STEP1_D01_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D01) + "\n")

    f.write(f"#golden {prefix} STEP1_D11_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D11) + "\n")
    f.write(f"#golden {prefix} STEP1_D11_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D11) + "\n")

    f.write(f"#golden {prefix} STEP0_D20_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D20) + "\n")
    f.write(f"#golden {prefix} STEP0_D20_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D20) + "\n")

    f.write(f"#golden {prefix} STEP0_D30_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D30) + "\n")
    f.write(f"#golden {prefix} STEP0_D30_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D30) + "\n")

    f.write(f"#golden {prefix} STEP1_D21_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D21) + "\n")
    f.write(f"#golden {prefix} STEP1_D21_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D21) + "\n")

    f.write(f"#golden {prefix} STEP1_D31_set{set_idx} decoded\n")
    f.write(matrix_to_lines_decimal(D31) + "\n")
    f.write(f"#golden {prefix} STEP1_D31_set{set_idx} encoded\n")
    f.write(matrix_to_lines_hex(D31) + "\n")


# ============================================================
# Testbench file writers
# Posit32 follows the FP32 flow:
# each 4-wide row [v0 v1 v2 v3] is loaded in two phases:
#   pair00 -> portA=v0, portB=v1
#   pair01 -> portA=v2, portB=v3
# ============================================================
def encode_row_posit32_hex(row: np.ndarray):
    return [posit32_encode_hex(float(v)) for v in row]


def pack_row_pair00(row: np.ndarray):
    h = encode_row_posit32_hex(row)
    return h[0], h[1]


def pack_row_pair01(row: np.ndarray):
    h = encode_row_posit32_hex(row)
    return h[2], h[3]


def write_tb_matrix_block_pair00(f, label: str, mat: np.ndarray, base_lane: int):
    f.write(f"#{label}\n")
    for i in range(4):
        lane_id = base_lane + i
        portA, portB = pack_row_pair00(mat[i])
        f.write(f"#lane{lane_id}\n")
        f.write(f"{portA} {portB}\n")


def write_tb_matrix_block_pair01(f, label: str, mat: np.ndarray, base_lane: int):
    f.write(f"#{label}\n")
    for i in range(4):
        lane_id = base_lane + i
        portA, portB = pack_row_pair01(mat[i])
        f.write(f"#lane{lane_id}\n")
        f.write(f"{portA} {portB}\n")


def write_tb_set0_dual_tc_phase_ordered(f, s0_tc0: dict, s0_tc1: dict):
    f.write("#================ SET 0 ================\n")

    f.write("#---- A payloads for both tensor cores (pair00) ----\n")
    write_tb_matrix_block_pair00(f, "tc0 oct0 A00 pair00", s0_tc0["A00"], 0)
    write_tb_matrix_block_pair00(f, "tc0 oct1 A10 pair00", s0_tc0["A10"], 4)
    write_tb_matrix_block_pair00(f, "tc0 oct2 A20 pair00", s0_tc0["A20"], 8)
    write_tb_matrix_block_pair00(f, "tc0 oct3 A30 pair00", s0_tc0["A30"], 12)

    write_tb_matrix_block_pair00(f, "tc1 oct0 A00 pair00", s0_tc1["A00"], 0)
    write_tb_matrix_block_pair00(f, "tc1 oct1 A10 pair00", s0_tc1["A10"], 4)
    write_tb_matrix_block_pair00(f, "tc1 oct2 A20 pair00", s0_tc1["A20"], 8)
    write_tb_matrix_block_pair00(f, "tc1 oct3 A30 pair00", s0_tc1["A30"], 12)

    f.write("#---- A payloads for both tensor cores (pair01) ----\n")
    write_tb_matrix_block_pair01(f, "tc0 oct0 A00 pair01", s0_tc0["A00"], 0)
    write_tb_matrix_block_pair01(f, "tc0 oct1 A10 pair01", s0_tc0["A10"], 4)
    write_tb_matrix_block_pair01(f, "tc0 oct2 A20 pair01", s0_tc0["A20"], 8)
    write_tb_matrix_block_pair01(f, "tc0 oct3 A30 pair01", s0_tc0["A30"], 12)

    write_tb_matrix_block_pair01(f, "tc1 oct0 A00 pair01", s0_tc1["A00"], 0)
    write_tb_matrix_block_pair01(f, "tc1 oct1 A10 pair01", s0_tc1["A10"], 4)
    write_tb_matrix_block_pair01(f, "tc1 oct2 A20 pair01", s0_tc1["A20"], 8)
    write_tb_matrix_block_pair01(f, "tc1 oct3 A30 pair01", s0_tc1["A30"], 12)

    f.write("#---- B payloads for both tensor cores (pair00) ----\n")
    write_tb_matrix_block_pair00(f, "tc0 oct0 B00_T_for_HMMA pair00", s0_tc0["B_left_T"], 0)
    write_tb_matrix_block_pair00(f, "tc0 oct1 B01_T_for_HMMA pair00", s0_tc0["B_right_T"], 4)
    write_tb_matrix_block_pair00(f, "tc0 oct2 B00_T_for_HMMA pair00", s0_tc0["B_left_T"], 8)
    write_tb_matrix_block_pair00(f, "tc0 oct3 B01_T_for_HMMA pair00", s0_tc0["B_right_T"], 12)

    write_tb_matrix_block_pair00(f, "tc1 oct0 B02_T_for_HMMA pair00", s0_tc1["B_left_T"], 0)
    write_tb_matrix_block_pair00(f, "tc1 oct1 B03_T_for_HMMA pair00", s0_tc1["B_right_T"], 4)
    write_tb_matrix_block_pair00(f, "tc1 oct2 B02_T_for_HMMA pair00", s0_tc1["B_left_T"], 8)
    write_tb_matrix_block_pair00(f, "tc1 oct3 B03_T_for_HMMA pair00", s0_tc1["B_right_T"], 12)

    f.write("#---- B payloads for both tensor cores (pair01) ----\n")
    write_tb_matrix_block_pair01(f, "tc0 oct0 B00_T_for_HMMA pair01", s0_tc0["B_left_T"], 0)
    write_tb_matrix_block_pair01(f, "tc0 oct1 B01_T_for_HMMA pair01", s0_tc0["B_right_T"], 4)
    write_tb_matrix_block_pair01(f, "tc0 oct2 B00_T_for_HMMA pair01", s0_tc0["B_left_T"], 8)
    write_tb_matrix_block_pair01(f, "tc0 oct3 B01_T_for_HMMA pair01", s0_tc0["B_right_T"], 12)

    write_tb_matrix_block_pair01(f, "tc1 oct0 B02_T_for_HMMA pair01", s0_tc1["B_left_T"], 0)
    write_tb_matrix_block_pair01(f, "tc1 oct1 B03_T_for_HMMA pair01", s0_tc1["B_right_T"], 4)
    write_tb_matrix_block_pair01(f, "tc1 oct2 B02_T_for_HMMA pair01", s0_tc1["B_left_T"], 8)
    write_tb_matrix_block_pair01(f, "tc1 oct3 B03_T_for_HMMA pair01", s0_tc1["B_right_T"], 12)

    f.write("#---- C step0 payloads for both tensor cores (pair00) ----\n")
    write_tb_matrix_block_pair00(f, "tc0 oct0 C00 pair00", s0_tc0["C00"], 0)
    write_tb_matrix_block_pair00(f, "tc0 oct1 C10 pair00", s0_tc0["C10"], 4)
    write_tb_matrix_block_pair00(f, "tc0 oct2 C20 pair00", s0_tc0["C20"], 8)
    write_tb_matrix_block_pair00(f, "tc0 oct3 C30 pair00", s0_tc0["C30"], 12)

    write_tb_matrix_block_pair00(f, "tc1 oct0 C02 pair00", s0_tc1["C00"], 0)
    write_tb_matrix_block_pair00(f, "tc1 oct1 C12 pair00", s0_tc1["C10"], 4)
    write_tb_matrix_block_pair00(f, "tc1 oct2 C22 pair00", s0_tc1["C20"], 8)
    write_tb_matrix_block_pair00(f, "tc1 oct3 C32 pair00", s0_tc1["C30"], 12)

    f.write("#---- C step0 payloads for both tensor cores (pair01) ----\n")
    write_tb_matrix_block_pair01(f, "tc0 oct0 C00 pair01", s0_tc0["C00"], 0)
    write_tb_matrix_block_pair01(f, "tc0 oct1 C10 pair01", s0_tc0["C10"], 4)
    write_tb_matrix_block_pair01(f, "tc0 oct2 C20 pair01", s0_tc0["C20"], 8)
    write_tb_matrix_block_pair01(f, "tc0 oct3 C30 pair01", s0_tc0["C30"], 12)

    write_tb_matrix_block_pair01(f, "tc1 oct0 C02 pair01", s0_tc1["C00"], 0)
    write_tb_matrix_block_pair01(f, "tc1 oct1 C12 pair01", s0_tc1["C10"], 4)
    write_tb_matrix_block_pair01(f, "tc1 oct2 C22 pair01", s0_tc1["C20"], 8)
    write_tb_matrix_block_pair01(f, "tc1 oct3 C32 pair01", s0_tc1["C30"], 12)

    f.write("#---- C step1 payloads for both tensor cores (pair00) ----\n")
    write_tb_matrix_block_pair00(f, "tc0 oct0 C01 pair00", s0_tc0["C01"], 0)
    write_tb_matrix_block_pair00(f, "tc0 oct1 C11 pair00", s0_tc0["C11"], 4)
    write_tb_matrix_block_pair00(f, "tc0 oct2 C21 pair00", s0_tc0["C21"], 8)
    write_tb_matrix_block_pair00(f, "tc0 oct3 C31 pair00", s0_tc0["C31"], 12)

    write_tb_matrix_block_pair00(f, "tc1 oct0 C03 pair00", s0_tc1["C01"], 0)
    write_tb_matrix_block_pair00(f, "tc1 oct1 C13 pair00", s0_tc1["C11"], 4)
    write_tb_matrix_block_pair00(f, "tc1 oct2 C23 pair00", s0_tc1["C21"], 8)
    write_tb_matrix_block_pair00(f, "tc1 oct3 C33 pair00", s0_tc1["C31"], 12)

    f.write("#---- C step1 payloads for both tensor cores (pair01) ----\n")
    write_tb_matrix_block_pair01(f, "tc0 oct0 C01 pair01", s0_tc0["C01"], 0)
    write_tb_matrix_block_pair01(f, "tc0 oct1 C11 pair01", s0_tc0["C11"], 4)
    write_tb_matrix_block_pair01(f, "tc0 oct2 C21 pair01", s0_tc0["C21"], 8)
    write_tb_matrix_block_pair01(f, "tc0 oct3 C31 pair01", s0_tc0["C31"], 12)

    write_tb_matrix_block_pair01(f, "tc1 oct0 C03 pair01", s0_tc1["C01"], 0)
    write_tb_matrix_block_pair01(f, "tc1 oct1 C13 pair01", s0_tc1["C11"], 4)
    write_tb_matrix_block_pair01(f, "tc1 oct2 C23 pair01", s0_tc1["C21"], 8)
    write_tb_matrix_block_pair01(f, "tc1 oct3 C33 pair01", s0_tc1["C31"], 12)


def write_tb_later_set_dual_tc_phase_ordered(f, set_idx: int, blk_tc0: dict, blk_tc1: dict):
    f.write(f"#================ SET {set_idx} ================\n")

    f.write("#---- A payloads for both tensor cores (pair00) ----\n")
    write_tb_matrix_block_pair00(f, f"tc0 oct0 A0{set_idx} pair00", blk_tc0["A00"], 0)
    write_tb_matrix_block_pair00(f, f"tc0 oct1 A1{set_idx} pair00", blk_tc0["A10"], 4)
    write_tb_matrix_block_pair00(f, f"tc0 oct2 A2{set_idx} pair00", blk_tc0["A20"], 8)
    write_tb_matrix_block_pair00(f, f"tc0 oct3 A3{set_idx} pair00", blk_tc0["A30"], 12)

    write_tb_matrix_block_pair00(f, f"tc1 oct0 A0{set_idx} pair00", blk_tc1["A00"], 0)
    write_tb_matrix_block_pair00(f, f"tc1 oct1 A1{set_idx} pair00", blk_tc1["A10"], 4)
    write_tb_matrix_block_pair00(f, f"tc1 oct2 A2{set_idx} pair00", blk_tc1["A20"], 8)
    write_tb_matrix_block_pair00(f, f"tc1 oct3 A3{set_idx} pair00", blk_tc1["A30"], 12)

    f.write("#---- A payloads for both tensor cores (pair01) ----\n")
    write_tb_matrix_block_pair01(f, f"tc0 oct0 A0{set_idx} pair01", blk_tc0["A00"], 0)
    write_tb_matrix_block_pair01(f, f"tc0 oct1 A1{set_idx} pair01", blk_tc0["A10"], 4)
    write_tb_matrix_block_pair01(f, f"tc0 oct2 A2{set_idx} pair01", blk_tc0["A20"], 8)
    write_tb_matrix_block_pair01(f, f"tc0 oct3 A3{set_idx} pair01", blk_tc0["A30"], 12)

    write_tb_matrix_block_pair01(f, f"tc1 oct0 A0{set_idx} pair01", blk_tc1["A00"], 0)
    write_tb_matrix_block_pair01(f, f"tc1 oct1 A1{set_idx} pair01", blk_tc1["A10"], 4)
    write_tb_matrix_block_pair01(f, f"tc1 oct2 A2{set_idx} pair01", blk_tc1["A20"], 8)
    write_tb_matrix_block_pair01(f, f"tc1 oct3 A3{set_idx} pair01", blk_tc1["A30"], 12)

    f.write("#---- B payloads for both tensor cores (pair00) ----\n")
    write_tb_matrix_block_pair00(f, f"tc0 oct0 B{set_idx}0_T_for_HMMA pair00", blk_tc0["B_left_T"], 0)
    write_tb_matrix_block_pair00(f, f"tc0 oct1 B{set_idx}1_T_for_HMMA pair00", blk_tc0["B_right_T"], 4)
    write_tb_matrix_block_pair00(f, f"tc0 oct2 B{set_idx}0_T_for_HMMA pair00", blk_tc0["B_left_T"], 8)
    write_tb_matrix_block_pair00(f, f"tc0 oct3 B{set_idx}1_T_for_HMMA pair00", blk_tc0["B_right_T"], 12)

    write_tb_matrix_block_pair00(f, f"tc1 oct0 B{set_idx}2_T_for_HMMA pair00", blk_tc1["B_left_T"], 0)
    write_tb_matrix_block_pair00(f, f"tc1 oct1 B{set_idx}3_T_for_HMMA pair00", blk_tc1["B_right_T"], 4)
    write_tb_matrix_block_pair00(f, f"tc1 oct2 B{set_idx}2_T_for_HMMA pair00", blk_tc1["B_left_T"], 8)
    write_tb_matrix_block_pair00(f, f"tc1 oct3 B{set_idx}3_T_for_HMMA pair00", blk_tc1["B_right_T"], 12)

    f.write("#---- B payloads for both tensor cores (pair01) ----\n")
    write_tb_matrix_block_pair01(f, f"tc0 oct0 B{set_idx}0_T_for_HMMA pair01", blk_tc0["B_left_T"], 0)
    write_tb_matrix_block_pair01(f, f"tc0 oct1 B{set_idx}1_T_for_HMMA pair01", blk_tc0["B_right_T"], 4)
    write_tb_matrix_block_pair01(f, f"tc0 oct2 B{set_idx}0_T_for_HMMA pair01", blk_tc0["B_left_T"], 8)
    write_tb_matrix_block_pair01(f, f"tc0 oct3 B{set_idx}1_T_for_HMMA pair01", blk_tc0["B_right_T"], 12)

    write_tb_matrix_block_pair01(f, f"tc1 oct0 B{set_idx}2_T_for_HMMA pair01", blk_tc1["B_left_T"], 0)
    write_tb_matrix_block_pair01(f, f"tc1 oct1 B{set_idx}3_T_for_HMMA pair01", blk_tc1["B_right_T"], 4)
    write_tb_matrix_block_pair01(f, f"tc1 oct2 B{set_idx}2_T_for_HMMA pair01", blk_tc1["B_left_T"], 8)
    write_tb_matrix_block_pair01(f, f"tc1 oct3 B{set_idx}3_T_for_HMMA pair01", blk_tc1["B_right_T"], 12)


# ============================================================
# Experiment builder for one tensor core
# tc_col_base = 0  -> left half (cols 0..7)
# tc_col_base = 2  -> right half (cols 8..15)
# ============================================================
def build_one_tc_safe_experiment(A: np.ndarray, B: np.ndarray, C: np.ndarray, tc_col_base: int):
    staged = {}

    prev_D00 = prev_D10 = prev_D01 = prev_D11 = None
    prev_D20 = prev_D30 = prev_D21 = prev_D31 = None

    for s in range(4):
        A00 = get_block(A, 0, s)
        A10 = get_block(A, 1, s)
        A20 = get_block(A, 2, s)
        A30 = get_block(A, 3, s)

        B_left_full = get_block(B, s, tc_col_base + 0)
        B_right_full = get_block(B, s, tc_col_base + 1)

        B_left_T = B_left_full.T.astype(np.float64)
        B_right_T = B_right_full.T.astype(np.float64)

        if s == 0:
            C00 = get_block(C, 0, tc_col_base + 0)
            C10 = get_block(C, 1, tc_col_base + 0)
            C01 = get_block(C, 0, tc_col_base + 1)
            C11 = get_block(C, 1, tc_col_base + 1)

            C20 = get_block(C, 2, tc_col_base + 0)
            C30 = get_block(C, 3, tc_col_base + 0)
            C21 = get_block(C, 2, tc_col_base + 1)
            C31 = get_block(C, 3, tc_col_base + 1)
        else:
            C00 = prev_D00.copy()
            C10 = prev_D10.copy()
            C01 = prev_D01.copy()
            C11 = prev_D11.copy()

            C20 = prev_D20.copy()
            C30 = prev_D30.copy()
            C21 = prev_D21.copy()
            C31 = prev_D31.copy()

        D00 = posit32_matmul_add(A00, B_left_full, C00)
        D10 = posit32_matmul_add(A10, B_left_full, C10)
        D01 = posit32_matmul_add(A00, B_right_full, C01)
        D11 = posit32_matmul_add(A10, B_right_full, C11)

        D20 = posit32_matmul_add(A20, B_left_full, C20)
        D30 = posit32_matmul_add(A30, B_left_full, C30)
        D21 = posit32_matmul_add(A20, B_right_full, C21)
        D31 = posit32_matmul_add(A30, B_right_full, C31)

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

    final_16x8 = np.block([
        [staged[3]["D00"], staged[3]["D01"]],
        [staged[3]["D10"], staged[3]["D11"]],
        [staged[3]["D20"], staged[3]["D21"]],
        [staged[3]["D30"], staged[3]["D31"]],
    ]).astype(np.float64)

    return {
        "staged": staged,
        "final_16x8": final_16x8,
    }


def build_dual_tc_safe_experiment(rng: np.random.Generator, max_attempts: int = 20000):
    for _ in range(max_attempts):
        A = random_posit32_matrix(rng)
        B = random_posit32_matrix(rng)
        C = random_posit32_matrix(rng)

        D_full_one_shot = posit32_matmul_add(A, B, C)

        if not is_safe_posit32_matrix(D_full_one_shot):
            continue

        tc0 = build_one_tc_safe_experiment(A, B, C, tc_col_base=0)
        tc1 = build_one_tc_safe_experiment(A, B, C, tc_col_base=2)

        ok = True
        for tc in (tc0, tc1):
            for s in range(4):
                blk = tc["staged"][s]
                for M in (
                    blk["A00"], blk["A10"], blk["A20"], blk["A30"],
                    blk["B_left_full"], blk["B_right_full"],
                    blk["B_left_T"], blk["B_right_T"],
                    blk["C00"], blk["C10"], blk["C01"], blk["C11"],
                    blk["C20"], blk["C30"], blk["C21"], blk["C31"],
                    blk["D00"], blk["D10"], blk["D01"], blk["D11"],
                    blk["D20"], blk["D30"], blk["D21"], blk["D31"],
                ):
                    if not is_safe_posit32_matrix(M):
                        ok = False
                        break
                if not ok:
                    break
            if not ok:
                break

        if not ok:
            continue

        D_full_from_2tc = np.block([[tc0["final_16x8"], tc1["final_16x8"]]]).reshape(16, 16).astype(np.float64)

        if not is_safe_posit32_matrix(D_full_from_2tc):
            continue

        return {
            "A": A,
            "B": B,
            "C": C,
            "D_full_one_shot": D_full_one_shot,
            "tc0": tc0,
            "tc1": tc1,
            "D_full_from_2tc": D_full_from_2tc,
        }

    raise RuntimeError("Could not generate a safe dual-TC posit32 16x16 experiment.")


# ============================================================
# Main writers
# ============================================================
def write_human_file(f, exp):
    f.write("#Full 16x16 GEMM-ACC decomposed across 2 tensor cores, each with 2 octects (posit32)\n")
    f.write(f"#Configured as posit<{POSIT_NBITS},{POSIT_ES}>.\n")
    f.write("#Golden math computes A @ B + C in float64 and rounds once to posit32 per 4x4 output block.\n")
    f.write("#Only the B payload written to the TB file is transposed for hardware feeding.\n\n")

    write_matrix_with_encoded(f, "FULL_A_16x16", exp["A"])
    write_matrix_with_encoded(f, "FULL_B_16x16", exp["B"])
    write_matrix_with_encoded(f, "FULL_C_16x16", exp["C"])
    write_matrix_with_encoded(f, "FULL_D_16x16_one_shot_reference", exp["D_full_one_shot"])

    for s in range(4):
        f.write("\n")
        blk0 = exp["tc0"]["staged"][s]
        write_set_block(
            f, s, "TC0",
            blk0["A00"], blk0["A10"], blk0["A20"], blk0["A30"],
            blk0["B_left_full"], blk0["B_right_full"],
            blk0["B_left_T"], blk0["B_right_T"],
            blk0["C00"], blk0["C10"], blk0["C01"], blk0["C11"],
            blk0["C20"], blk0["C30"], blk0["C21"], blk0["C31"],
            blk0["D00"], blk0["D10"], blk0["D01"], blk0["D11"],
            blk0["D20"], blk0["D30"], blk0["D21"], blk0["D31"],
        )

        f.write("\n")
        blk1 = exp["tc1"]["staged"][s]
        write_set_block(
            f, s, "TC1",
            blk1["A00"], blk1["A10"], blk1["A20"], blk1["A30"],
            blk1["B_left_full"], blk1["B_right_full"],
            blk1["B_left_T"], blk1["B_right_T"],
            blk1["C00"], blk1["C10"], blk1["C01"], blk1["C11"],
            blk1["C20"], blk1["C30"], blk1["C21"], blk1["C31"],
            blk1["D00"], blk1["D10"], blk1["D01"], blk1["D11"],
            blk1["D20"], blk1["D30"], blk1["D21"], blk1["D31"],
        )

    f.write("\n#FINAL_CHAINED_16x8_FROM_TC0_POSIT32\n")
    for name in ("D00", "D01", "D10", "D11", "D20", "D21", "D30", "D31"):
        f.write(f"#TC0_{name}_final encoded\n")
        f.write(matrix_to_lines_hex(exp["tc0"]["staged"][3][name]) + "\n")

    f.write("\n#FINAL_CHAINED_16x8_FROM_TC1_POSIT32\n")
    for name in ("D00", "D01", "D10", "D11", "D20", "D21", "D30", "D31"):
        f.write(f"#TC1_{name}_final encoded\n")
        f.write(matrix_to_lines_hex(exp["tc1"]["staged"][3][name]) + "\n")

    f.write("\n#FINAL_CHAINED_16x16_FROM_DUAL_TC_POSIT32\n")
    f.write("#D_full_from_2tc decoded\n")
    f.write(matrix_to_lines_decimal(exp["D_full_from_2tc"]) + "\n")
    f.write("#D_full_from_2tc encoded\n")
    f.write(matrix_to_lines_hex(exp["D_full_from_2tc"]) + "\n")

    f.write("\n#FINAL_IDEAL_16x16_ONE_SHOT_REFERENCE\n")
    f.write("#D_full_one_shot decoded\n")
    f.write(matrix_to_lines_decimal(exp["D_full_one_shot"]) + "\n")
    f.write("#D_full_one_shot encoded\n")
    f.write(matrix_to_lines_hex(exp["D_full_one_shot"]) + "\n")


def write_tb_file(f, exp):
    f.write("#register file ports content for posit32 dual tensor-core wrapper\n")
    f.write(f"#Configured as posit<{POSIT_NBITS},{POSIT_ES}>.\n")
    f.write("#Phase-organized ordering inside each set:\n")
    f.write("#  1) all A payloads for both tensor cores (pair00)\n")
    f.write("#  2) all A payloads for both tensor cores (pair01)\n")
    f.write("#  3) all B payloads for both tensor cores (pair00)\n")
    f.write("#  4) all B payloads for both tensor cores (pair01)\n")
    f.write("#  5) all C step0 payloads for both tensor cores (pair00, set0 only)\n")
    f.write("#  6) all C step0 payloads for both tensor cores (pair01, set0 only)\n")
    f.write("#  7) all C step1 payloads for both tensor cores (pair00, set0 only)\n")
    f.write("#  8) all C step1 payloads for both tensor cores (pair01, set0 only)\n")
    f.write("#Later sets contain only A and B because C comes from chained results inside the TB.\n")
    f.write("#For posit32, each 4-wide row is loaded in two phases: pair00=(col0,col1), pair01=(col2,col3).\n\n")

    s0_tc0 = exp["tc0"]["staged"][0]
    s0_tc1 = exp["tc1"]["staged"][0]
    write_tb_set0_dual_tc_phase_ordered(f, s0_tc0, s0_tc1)

    for s in range(1, 4):
        f.write("\n")
        write_tb_later_set_dual_tc_phase_ordered(f, s, exp["tc0"]["staged"][s], exp["tc1"]["staged"][s])


# ============================================================
# Main
# ============================================================
def main():
    print("Script started...")
    print(f"Configured posit type: posit<{POSIT_NBITS},{POSIT_ES}>")
    print(f"Writing human-readable file to: {OUTPUT_FILE_HUMAN}")
    print(f"Writing TB input file to: {OUTPUT_FILE_TB}")

    rng = np.random.default_rng(SEED)
    exp = build_dual_tc_safe_experiment(rng)

    with open(OUTPUT_FILE_HUMAN, "w", encoding="utf-8") as f_human:
        write_human_file(f_human, exp)

    with open(OUTPUT_FILE_TB, "w", encoding="utf-8") as f_tb:
        write_tb_file(f_tb, exp)

    print(f"Generated human-readable experiment file: '{OUTPUT_FILE_HUMAN}'")
    print(f"Generated TB input file: '{OUTPUT_FILE_TB}'")


if __name__ == "__main__":
    main()
