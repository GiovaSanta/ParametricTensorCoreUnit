import os
import sys
import math
import numpy as np

# ============================================================
# Configuration
# ============================================================
SEED = 42

# Workload modes:
#   "random_signed_stress"
#       Original style: A, B, C are fully random signed matrices.
#       This is a good stress test for cancellation.
#
#   "dnn_inference_like"
#       A is ReLU-like: nonnegative and sparse.
#       B is signed, but each output column has a dominant sign.
#       C is a small signed bias/addend, usually aligned with the column sign.
#       This is intended to be a more favorable DNN-inference-like workload
#       for the signed LNS adder.
#
# You can also override this from the command line:
#   python TestForLNS16HMMA4sets_4octects_dnn_workloads.py dnn_inference_like
#   python TestForLNS16HMMA4sets_4octects_dnn_workloads.py random_signed_stress
WORKLOAD_MODE = "dnn_inference_like"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

VALUE_MIN = -4.0
VALUE_MAX = 4.0

# Parameters for the DNN-inference-like case.
# Nonzero ReLU activations are positive. Sparsity means exact zeros.
RELU_SPARSITY = 0.50
ACTIVATION_MIN = 0.125
ACTIVATION_MAX = 2.0

# The weight matrix is still signed, but every output column has a dominant
# sign. This reduces the probability that a dot-product column alternates
# positive/negative products in a fully random way.
WEIGHT_MIN = 0.125
WEIGHT_MAX = 1.25
WEIGHT_DOMINANT_SIGN_PROB = 0.875

# C is kept small because it models a bias/addend rather than another
# fully random large matrix.
BIAS_ZERO_PROB = 0.25
BIAS_MIN = 0.0
BIAS_MAX = 0.125
BIAS_DOMINANT_SIGN_PROB = 0.875

# Cancellation metric threshold for the DNN-like mode.
# ratio = abs(sum products + C) / (sum(abs(products)) + abs(C))
# ratio close to 1 => little cancellation; ratio close to 0 => severe cancellation.
LOW_CANCEL_MEAN_MIN = 0.65
LOW_CANCEL_P10_MIN = 0.35


# IMPORTANT:
# Keep the exact same output filenames used by the older generator script.
# This avoids accidentally validating the simulator output against the wrong
# golden/reference file. The selected workload is still written inside the
# human-readable file under #WORKLOAD_METADATA.
OUTPUT_FILE_HUMAN = os.path.join(
    SCRIPT_DIR,
    "hmma_8instr_dualTC_4octects_lns16_single_experiment.txt"
)
OUTPUT_FILE_TB = os.path.join(
    SCRIPT_DIR,
    "hmma_8instr_dualTC_4octects_lns16_single_experiment_tb_input.txt"
)

FULL_SIZE = 16
BLOCK = 4

# LNS16 format currently used by the VHDL modules:
#   bits 15:14 = 01 for normal finite
#   bit 13     = sign
#   bits 12:0  = signed fixed-point log2(value magnitude)
#   wE = 4, wF = 9, scale = 2^9
W_F = 9
LNS_SCALE = 1 << W_F
LNS_MIN_LOG = -4096
LNS_MAX_LOG = 4095
LNS_MIN_MAG = 2.0 ** (LNS_MIN_LOG / LNS_SCALE)

# For the first tensor-core wrapper benchmark, avoid reference outputs
# very close to zero. This keeps the test focused on integration/arithmetic
# rather than the known multi-stage near-cancellation corner case.
AVOID_NEAR_ZERO_RESULTS = True
MIN_SAFE_RESULT_MAG = 0.125


# ============================================================
# LNS16 helpers
# ============================================================
def signed13_to_bits(x: int) -> int:
    if x < 0:
        x = (1 << 13) + x
    return x & 0x1FFF


def bits_to_signed13(x: int) -> int:
    v = x & 0x1FFF
    if v & 0x1000:
        v -= 0x2000
    return v


def real_to_lns16_bits(value: float) -> int:
    """
    Encode a Python real value into the LNS16 4_9 format used by the VHDL.

    Zero is encoded as 0x0000.
    Normal finite values use:
        0x4000 | sign_bit | signed_log_field
    """
    value = float(value)

    if not math.isfinite(value):
        raise ValueError(f"Cannot encode non-finite value: {value}")

    if abs(value) < LNS_MIN_MAG:
        return 0x0000

    sign = 1 if value < 0.0 else 0
    mag = abs(value)

    log_fixed = int(round(math.log2(mag) * LNS_SCALE))

    if not (LNS_MIN_LOG <= log_fixed <= LNS_MAX_LOG):
        raise ValueError(
            f"Cannot encode value outside LNS16 4_9 range: "
            f"value={value}, log_fixed={log_fixed}"
        )

    return 0x4000 | (sign << 13) | signed13_to_bits(log_fixed)


def lns16_bits_to_real(bits: int) -> float:
    bits = int(bits) & 0xFFFF

    if bits == 0x0000:
        return 0.0

    # This generator only emits normal finite numbers plus zero.
    if (bits >> 14) != 0b01:
        raise ValueError(f"Unsupported non-normal LNS16 value: 0x{bits:04X}")

    sign = -1.0 if ((bits >> 13) & 1) else 1.0
    log_fixed = bits_to_signed13(bits)
    return sign * (2.0 ** (log_fixed / LNS_SCALE))


def quantize_lns16_value(value: float) -> float:
    return lns16_bits_to_real(real_to_lns16_bits(value))


def format_lns16_value(x: float) -> str:
    return f"{float(x):.6g}"


def format_lns16_hex(x: float) -> str:
    return f"{real_to_lns16_bits(float(x)):04X}"


def matrix_to_lines_decimal(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(format_lns16_value(v) for v in row)
        for row in mat
    )


def matrix_to_lines_hex(mat: np.ndarray) -> str:
    return "\n".join(
        " ".join(format_lns16_hex(v) for v in row)
        for row in mat
    )


def quantize_lns16_matrix(mat: np.ndarray) -> np.ndarray:
    out = np.zeros(mat.shape, dtype=np.float64)
    for idx in np.ndindex(mat.shape):
        out[idx] = quantize_lns16_value(float(mat[idx]))
    return out


def random_lns16_matrix(
    rng: np.random.Generator,
    low: float = VALUE_MIN,
    high: float = VALUE_MAX,
    shape=(FULL_SIZE, FULL_SIZE)
) -> np.ndarray:
    """
    Generate random real values and immediately quantize them to the LNS16
    format, so the decimal matrices match the encoded payloads.
    """
    raw = rng.uniform(low, high, size=shape).astype(np.float64)
    return quantize_lns16_matrix(raw)




def log_uniform_magnitudes(
    rng: np.random.Generator,
    low: float,
    high: float,
    shape
) -> np.ndarray:
    """
    Generate positive magnitudes uniformly in log2 space.
    This is closer to what an LNS format likes than uniform real spacing.
    """
    if low <= 0.0 or high <= 0.0:
        raise ValueError("log_uniform_magnitudes requires low/high > 0")
    log_low = math.log2(low)
    log_high = math.log2(high)
    return 2.0 ** rng.uniform(log_low, log_high, size=shape)


def random_relu_like_lns16_matrix(
    rng: np.random.Generator,
    shape=(FULL_SIZE, FULL_SIZE)
) -> np.ndarray:
    """
    DNN-inference-like activation matrix.

    It imitates an activation tensor after ReLU:
      - nonnegative only
      - many exact zeros
      - nonzero values are positive and log-spread
    """
    nonzero = rng.random(size=shape) >= RELU_SPARSITY
    mags = log_uniform_magnitudes(rng, ACTIVATION_MIN, ACTIVATION_MAX, shape)
    raw = np.where(nonzero, mags, 0.0).astype(np.float64)
    return quantize_lns16_matrix(raw)


def random_sign_coherent_weight_lns16_matrix(
    rng: np.random.Generator,
    shape=(FULL_SIZE, FULL_SIZE)
):
    """
    DNN-inference-like signed weight matrix.

    The matrix is still signed, but each output column has a dominant sign.
    Since A is nonnegative, this makes many products in a dot product share
    the same sign, reducing cancellation compared with fully random signs.
    """
    rows, cols = shape
    col_dominant_signs = rng.choice(np.array([-1.0, 1.0]), size=cols)

    same_as_column = rng.random(size=shape) < WEIGHT_DOMINANT_SIGN_PROB
    signs = np.where(same_as_column, col_dominant_signs.reshape(1, cols), -col_dominant_signs.reshape(1, cols))
    mags = log_uniform_magnitudes(rng, WEIGHT_MIN, WEIGHT_MAX, shape)
    raw = (signs * mags).astype(np.float64)
    return quantize_lns16_matrix(raw), col_dominant_signs


def random_small_bias_lns16_matrix(
    rng: np.random.Generator,
    col_dominant_signs: np.ndarray,
    shape=(FULL_SIZE, FULL_SIZE)
) -> np.ndarray:
    """
    Small C matrix for D = A*B + C.

    This is a bias/addend-like matrix. It is not the main source of energy in
    the dot product. Most entries follow the same sign as the corresponding
    output column, so C does not intentionally create strong cancellation.
    """
    rows, cols = shape
    zero_mask = rng.random(size=shape) < BIAS_ZERO_PROB
    same_as_column = rng.random(size=shape) < BIAS_DOMINANT_SIGN_PROB
    signs = np.where(same_as_column, col_dominant_signs.reshape(1, cols), -col_dominant_signs.reshape(1, cols))

    if BIAS_MIN == 0.0:
        mags = rng.uniform(0.0, BIAS_MAX, size=shape)
    else:
        mags = log_uniform_magnitudes(rng, BIAS_MIN, BIAS_MAX, shape)

    raw = np.where(zero_mask, 0.0, signs * mags).astype(np.float64)
    return quantize_lns16_matrix(raw)


def generate_workload_matrices(rng: np.random.Generator):
    """
    Generate A, B, C according to WORKLOAD_MODE.
    """
    if WORKLOAD_MODE == "random_signed_stress":
        A = random_lns16_matrix(rng)
        B = random_lns16_matrix(rng)
        C = random_lns16_matrix(rng)
        meta = {
            "workload_mode": WORKLOAD_MODE,
            "description": "fully random signed A, B, C; cancellation-heavy stress test"
        }
        return A, B, C, meta

    if WORKLOAD_MODE == "dnn_inference_like":
        A = random_relu_like_lns16_matrix(rng)
        B, col_dominant_signs = random_sign_coherent_weight_lns16_matrix(rng)
        C = random_small_bias_lns16_matrix(rng, col_dominant_signs)
        meta = {
            "workload_mode": WORKLOAD_MODE,
            "description": "ReLU-like sparse nonnegative A, signed sign-coherent B, small bias-like C",
            "relu_sparsity_target": RELU_SPARSITY,
            "actual_A_zero_fraction": float(np.mean(A == 0.0)),
            "weight_dominant_sign_probability": WEIGHT_DOMINANT_SIGN_PROB,
            "bias_dominant_sign_probability": BIAS_DOMINANT_SIGN_PROB,
            "column_dominant_signs": col_dominant_signs.astype(int).tolist(),
        }
        return A, B, C, meta

    raise ValueError(
        f"Unsupported WORKLOAD_MODE='{WORKLOAD_MODE}'. "
        "Use 'dnn_inference_like' or 'random_signed_stress'."
    )


def cancellation_ratio_matrix(A: np.ndarray, B: np.ndarray, C: np.ndarray) -> np.ndarray:
    """
    Per-output cancellation ratio for D = A @ B + C.

    For each output element:
      numerator   = abs(sum_k A[i,k] * B[k,j] + C[i,j])
      denominator = sum_k abs(A[i,k] * B[k,j]) + abs(C[i,j])

    ratio close to 1 means low cancellation.
    ratio close to 0 means strong cancellation or near-zero result.
    """
    A64 = A.astype(np.float64)
    B64 = B.astype(np.float64)
    C64 = C.astype(np.float64)
    products = A64[:, :, None] * B64[None, :, :]
    numerator = np.abs(np.sum(products, axis=1) + C64)
    denominator = np.sum(np.abs(products), axis=1) + np.abs(C64)
    return np.divide(numerator, denominator, out=np.ones_like(numerator), where=(denominator != 0.0))


def summarize_ratios(ratios: np.ndarray) -> dict:
    r = np.asarray(ratios, dtype=np.float64).ravel()
    if r.size == 0:
        return {"min": 1.0, "p10": 1.0, "mean": 1.0, "median": 1.0, "max": 1.0}
    return {
        "min": float(np.min(r)),
        "p10": float(np.percentile(r, 10)),
        "mean": float(np.mean(r)),
        "median": float(np.median(r)),
        "max": float(np.max(r)),
    }


def collect_staged_cancellation_ratios(tc: dict) -> np.ndarray:
    all_ratios = []
    for s in range(4):
        blk = tc["staged"][s]
        all_ratios.append(cancellation_ratio_matrix(blk["A00"], blk["B_left_full"],  blk["C00"]))
        all_ratios.append(cancellation_ratio_matrix(blk["A10"], blk["B_left_full"],  blk["C10"]))
        all_ratios.append(cancellation_ratio_matrix(blk["A00"], blk["B_right_full"], blk["C01"]))
        all_ratios.append(cancellation_ratio_matrix(blk["A10"], blk["B_right_full"], blk["C11"]))
        all_ratios.append(cancellation_ratio_matrix(blk["A20"], blk["B_left_full"],  blk["C20"]))
        all_ratios.append(cancellation_ratio_matrix(blk["A30"], blk["B_left_full"],  blk["C30"]))
        all_ratios.append(cancellation_ratio_matrix(blk["A20"], blk["B_right_full"], blk["C21"]))
        all_ratios.append(cancellation_ratio_matrix(blk["A30"], blk["B_right_full"], blk["C31"]))
    return np.concatenate([x.ravel() for x in all_ratios])


def cancellation_summary_for_experiment(exp: dict) -> dict:
    full_ratios = cancellation_ratio_matrix(exp["A"], exp["B"], exp["C"])
    staged_ratios = np.concatenate([
        collect_staged_cancellation_ratios(exp["tc0"]),
        collect_staged_cancellation_ratios(exp["tc1"]),
    ])
    return {
        "full": summarize_ratios(full_ratios),
        "staged": summarize_ratios(staged_ratios),
    }

def is_safe_lns16_matrix(mat: np.ndarray, check_near_zero: bool = False) -> bool:
    if not np.all(np.isfinite(mat)):
        return False

    try:
        # Verify all values are encodable.
        for v in mat.flat:
            _ = real_to_lns16_bits(float(v))
    except ValueError:
        return False

    if check_near_zero and AVOID_NEAR_ZERO_RESULTS:
        abs_m = np.abs(mat.astype(np.float64))
        bad = (abs_m != 0.0) & (abs_m < MIN_SAFE_RESULT_MAG)
        if np.any(bad):
            return False

    return True


def lns16_matmul_add(A: np.ndarray, B: np.ndarray, C: np.ndarray) -> np.ndarray:
    """
    LNS16 golden/reference model for the wrapper experiment:
      compute real A @ B + C, then quantize each output to LNS16.
    """
    result_real = A.astype(np.float64) @ B.astype(np.float64) + C.astype(np.float64)
    return quantize_lns16_matrix(result_real)


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
# ============================================================
def encode_row_lns16_hex(row: np.ndarray):
    return [format_lns16_hex(float(v)) for v in row]


def pack_row_into_ports(row: np.ndarray):
    """
    row = [v0, v1, v2, v3]
    portA = enc(v1) + enc(v0)
    portB = enc(v3) + enc(v2)
    """
    h = encode_row_lns16_hex(row)
    portA = h[1] + h[0]
    portB = h[3] + h[2]
    return portA, portB


def write_tb_matrix_block(f, label: str, mat: np.ndarray, base_lane: int):
    f.write(f"#{label}\n")
    for i in range(4):
        lane_id = base_lane + i
        portA, portB = pack_row_into_ports(mat[i])
        f.write(f"#lane{lane_id}\n")
        f.write(f"{portA} {portB}\n")


def write_tb_set0_dual_tc_phase_ordered(f, s0_tc0: dict, s0_tc1: dict):
    f.write("#================ SET 0 ================\n")

    f.write("#---- A payloads for both tensor cores ----\n")
    write_tb_matrix_block(f, "tc0 oct0 A00", s0_tc0["A00"], 0)
    write_tb_matrix_block(f, "tc0 oct1 A10", s0_tc0["A10"], 4)
    write_tb_matrix_block(f, "tc0 oct2 A20", s0_tc0["A20"], 8)
    write_tb_matrix_block(f, "tc0 oct3 A30", s0_tc0["A30"], 12)

    write_tb_matrix_block(f, "tc1 oct0 A00", s0_tc1["A00"], 0)
    write_tb_matrix_block(f, "tc1 oct1 A10", s0_tc1["A10"], 4)
    write_tb_matrix_block(f, "tc1 oct2 A20", s0_tc1["A20"], 8)
    write_tb_matrix_block(f, "tc1 oct3 A30", s0_tc1["A30"], 12)

    f.write("#---- B payloads for both tensor cores ----\n")
    write_tb_matrix_block(f, "tc0 oct0 B00_T_for_HMMA", s0_tc0["B_left_T"], 0)
    write_tb_matrix_block(f, "tc0 oct1 B01_T_for_HMMA", s0_tc0["B_right_T"], 4)
    write_tb_matrix_block(f, "tc0 oct2 B00_T_for_HMMA", s0_tc0["B_left_T"], 8)
    write_tb_matrix_block(f, "tc0 oct3 B01_T_for_HMMA", s0_tc0["B_right_T"], 12)

    write_tb_matrix_block(f, "tc1 oct0 B02_T_for_HMMA", s0_tc1["B_left_T"], 0)
    write_tb_matrix_block(f, "tc1 oct1 B03_T_for_HMMA", s0_tc1["B_right_T"], 4)
    write_tb_matrix_block(f, "tc1 oct2 B02_T_for_HMMA", s0_tc1["B_left_T"], 8)
    write_tb_matrix_block(f, "tc1 oct3 B03_T_for_HMMA", s0_tc1["B_right_T"], 12)

    f.write("#---- C step0 payloads for both tensor cores ----\n")
    write_tb_matrix_block(f, "tc0 oct0 C00", s0_tc0["C00"], 0)
    write_tb_matrix_block(f, "tc0 oct1 C10", s0_tc0["C10"], 4)
    write_tb_matrix_block(f, "tc0 oct2 C20", s0_tc0["C20"], 8)
    write_tb_matrix_block(f, "tc0 oct3 C30", s0_tc0["C30"], 12)

    write_tb_matrix_block(f, "tc1 oct0 C02", s0_tc1["C00"], 0)
    write_tb_matrix_block(f, "tc1 oct1 C12", s0_tc1["C10"], 4)
    write_tb_matrix_block(f, "tc1 oct2 C22", s0_tc1["C20"], 8)
    write_tb_matrix_block(f, "tc1 oct3 C32", s0_tc1["C30"], 12)

    f.write("#---- C step1 payloads for both tensor cores ----\n")
    write_tb_matrix_block(f, "tc0 oct0 C01", s0_tc0["C01"], 0)
    write_tb_matrix_block(f, "tc0 oct1 C11", s0_tc0["C11"], 4)
    write_tb_matrix_block(f, "tc0 oct2 C21", s0_tc0["C21"], 8)
    write_tb_matrix_block(f, "tc0 oct3 C31", s0_tc0["C31"], 12)

    write_tb_matrix_block(f, "tc1 oct0 C03", s0_tc1["C01"], 0)
    write_tb_matrix_block(f, "tc1 oct1 C13", s0_tc1["C11"], 4)
    write_tb_matrix_block(f, "tc1 oct2 C23", s0_tc1["C21"], 8)
    write_tb_matrix_block(f, "tc1 oct3 C33", s0_tc1["C31"], 12)


def write_tb_later_set_dual_tc_phase_ordered(f, set_idx: int, blk_tc0: dict, blk_tc1: dict):
    f.write(f"#================ SET {set_idx} ================\n")

    f.write("#---- A payloads for both tensor cores ----\n")
    write_tb_matrix_block(f, f"tc0 oct0 A0{set_idx}", blk_tc0["A00"], 0)
    write_tb_matrix_block(f, f"tc0 oct1 A1{set_idx}", blk_tc0["A10"], 4)
    write_tb_matrix_block(f, f"tc0 oct2 A2{set_idx}", blk_tc0["A20"], 8)
    write_tb_matrix_block(f, f"tc0 oct3 A3{set_idx}", blk_tc0["A30"], 12)

    write_tb_matrix_block(f, f"tc1 oct0 A0{set_idx}", blk_tc1["A00"], 0)
    write_tb_matrix_block(f, f"tc1 oct1 A1{set_idx}", blk_tc1["A10"], 4)
    write_tb_matrix_block(f, f"tc1 oct2 A2{set_idx}", blk_tc1["A20"], 8)
    write_tb_matrix_block(f, f"tc1 oct3 A3{set_idx}", blk_tc1["A30"], 12)

    f.write("#---- B payloads for both tensor cores ----\n")
    write_tb_matrix_block(f, f"tc0 oct0 B{set_idx}0_T_for_HMMA", blk_tc0["B_left_T"], 0)
    write_tb_matrix_block(f, f"tc0 oct1 B{set_idx}1_T_for_HMMA", blk_tc0["B_right_T"], 4)
    write_tb_matrix_block(f, f"tc0 oct2 B{set_idx}0_T_for_HMMA", blk_tc0["B_left_T"], 8)
    write_tb_matrix_block(f, f"tc0 oct3 B{set_idx}1_T_for_HMMA", blk_tc0["B_right_T"], 12)

    write_tb_matrix_block(f, f"tc1 oct0 B{set_idx}2_T_for_HMMA", blk_tc1["B_left_T"], 0)
    write_tb_matrix_block(f, f"tc1 oct1 B{set_idx}3_T_for_HMMA", blk_tc1["B_right_T"], 4)
    write_tb_matrix_block(f, f"tc1 oct2 B{set_idx}2_T_for_HMMA", blk_tc1["B_left_T"], 8)
    write_tb_matrix_block(f, f"tc1 oct3 B{set_idx}3_T_for_HMMA", blk_tc1["B_right_T"], 12)


# ============================================================
# Experiment builder for one tensor core
# tc_col_base = 0  -> left half (cols 0..7)
# tc_col_base = 2  -> right half (cols 8..15)
# ============================================================
def build_one_tc_safe_experiment(
    A: np.ndarray,
    B: np.ndarray,
    C: np.ndarray,
    tc_col_base: int
):
    staged = {}

    prev_D00 = prev_D10 = prev_D01 = prev_D11 = None
    prev_D20 = prev_D30 = prev_D21 = prev_D31 = None

    for s in range(4):
        A00 = get_block(A, 0, s)
        A10 = get_block(A, 1, s)
        A20 = get_block(A, 2, s)
        A30 = get_block(A, 3, s)

        B_left_full  = get_block(B, s, tc_col_base + 0)
        B_right_full = get_block(B, s, tc_col_base + 1)

        B_left_T  = B_left_full.T.copy()
        B_right_T = B_right_full.T.copy()

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

        D00 = lns16_matmul_add(A00, B_left_full,  C00)
        D10 = lns16_matmul_add(A10, B_left_full,  C10)
        D01 = lns16_matmul_add(A00, B_right_full, C01)
        D11 = lns16_matmul_add(A10, B_right_full, C11)

        D20 = lns16_matmul_add(A20, B_left_full,  C20)
        D30 = lns16_matmul_add(A30, B_left_full,  C30)
        D21 = lns16_matmul_add(A20, B_right_full, C21)
        D31 = lns16_matmul_add(A30, B_right_full, C31)

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
        "final_16x8": final_16x8
    }


def build_dual_tc_safe_experiment(rng: np.random.Generator, max_attempts: int = 20000):
    for attempt in range(1, max_attempts + 1):
        A, B, C, meta = generate_workload_matrices(rng)

        D_full_one_shot = lns16_matmul_add(A, B, C)

        if not is_safe_lns16_matrix(D_full_one_shot, check_near_zero=True):
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
                    blk["D20"], blk["D30"], blk["D21"], blk["D31"]
                ):
                    # C and D are the important values for near-zero safety.
                    # A/B can be any normal LNS16 input produced by the generator.
                    if not is_safe_lns16_matrix(M, check_near_zero=False):
                        ok = False
                        break
                if not ok:
                    break
            if not ok:
                break

        if not ok:
            continue

        D_full_from_2tc = np.block([
            [tc0["final_16x8"], tc1["final_16x8"]]
        ]).reshape(16, 16).astype(np.float64)

        if not is_safe_lns16_matrix(D_full_from_2tc, check_near_zero=True):
            continue

        exp = {
            "A": A,
            "B": B,
            "C": C,
            "D_full_one_shot": D_full_one_shot,
            "tc0": tc0,
            "tc1": tc1,
            "D_full_from_2tc": D_full_from_2tc,
            "meta": meta,
        }

        exp["cancellation"] = cancellation_summary_for_experiment(exp)

        if WORKLOAD_MODE == "dnn_inference_like":
            staged = exp["cancellation"]["staged"]
            if staged["mean"] < LOW_CANCEL_MEAN_MIN or staged["p10"] < LOW_CANCEL_P10_MIN:
                continue

        print(f"Accepted {WORKLOAD_MODE} LNS16 experiment after {attempt} attempt(s).")
        print(f"Cancellation summary: {exp['cancellation']}")

        return exp

    raise RuntimeError("Could not generate a safe dual-TC LNS16 16x16 experiment.")


# ============================================================
# Main writers
# ============================================================
def write_human_file(f, exp):
    f.write("#Full 16x16 GEMM-ACC decomposed across 2 tensor cores, each with 2 octects (LNS16 4_9)\n")
    f.write("#Golden math uses real A @ B + C, then quantizes outputs to LNS16 4_9.\n")
    f.write("#Only the B payload written to the TB file is transposed for hardware feeding.\n")
    f.write("#This benchmark can generate either a fully random signed stress test or a DNN-inference-like lower-cancellation case.\n")
    f.write("#Cancellation ratio = abs(sum products + C) / (sum(abs(products)) + abs(C)).\n")
    f.write("#Ratio close to 1 means little cancellation; ratio close to 0 means severe cancellation.\n\n")

    f.write("#WORKLOAD_METADATA\n")
    for k, v in exp.get("meta", {}).items():
        f.write(f"#{k}: {v}\n")
    f.write("#CANCELLATION_SUMMARY_FULL_GEMM\n")
    for k, v in exp.get("cancellation", {}).get("full", {}).items():
        f.write(f"#{k}: {v:.6f}\n")
    f.write("#CANCELLATION_SUMMARY_STAGED_4x4_CHAINED_OPS\n")
    for k, v in exp.get("cancellation", {}).get("staged", {}).items():
        f.write(f"#{k}: {v:.6f}\n")
    f.write("\n")

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

    f.write("\n#FINAL_CHAINED_16x8_FROM_TC0_LNS16\n")
    for name in ("D00", "D01", "D10", "D11", "D20", "D21", "D30", "D31"):
        f.write(f"#TC0_{name}_final encoded\n")
        f.write(matrix_to_lines_hex(exp["tc0"]["staged"][3][name]) + "\n")

    f.write("\n#FINAL_CHAINED_16x8_FROM_TC1_LNS16\n")
    for name in ("D00", "D01", "D10", "D11", "D20", "D21", "D30", "D31"):
        f.write(f"#TC1_{name}_final encoded\n")
        f.write(matrix_to_lines_hex(exp["tc1"]["staged"][3][name]) + "\n")

    f.write("\n#FINAL_CHAINED_16x16_FROM_DUAL_TC_LNS16\n")
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
    f.write("#register file ports content for LNS16 4_9 dual tensor-core wrapper\n")
    f.write(f"#workload_mode: {exp.get('meta', {}).get('workload_mode', WORKLOAD_MODE)}\n")
    f.write("#Phase-organized ordering inside each set:\n")
    f.write("#  1) all A payloads for both tensor cores\n")
    f.write("#  2) all B payloads for both tensor cores\n")
    f.write("#  3) all C step0 payloads for both tensor cores (set0 only)\n")
    f.write("#  4) all C step1 payloads for both tensor cores (set0 only)\n")
    f.write("#Later sets contain only A and B because C comes from chained results inside the TB.\n\n")

    s0_tc0 = exp["tc0"]["staged"][0]
    s0_tc1 = exp["tc1"]["staged"][0]
    write_tb_set0_dual_tc_phase_ordered(f, s0_tc0, s0_tc1)

    for s in range(1, 4):
        f.write("\n")
        write_tb_later_set_dual_tc_phase_ordered(
            f,
            s,
            exp["tc0"]["staged"][s],
            exp["tc1"]["staged"][s],
        )


# ============================================================
# Main
# ============================================================
def main():
    global WORKLOAD_MODE

    if len(sys.argv) > 1:
        WORKLOAD_MODE = sys.argv[1].strip()

    print("Script started...")
    print(f"Workload mode: {WORKLOAD_MODE}")
    print("IMPORTANT: using the legacy fixed output filenames expected by your validation flow.")
    print("Existing files with these names will be overwritten.")
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
