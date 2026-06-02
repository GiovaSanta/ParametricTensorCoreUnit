import math
import random
from pathlib import Path

W_F = 9
SCALE = 1 << W_F

BASE = Path("TestingDPU_LNS16NEW")
VEC_DIR = BASE / "vectors"
VEC_DIR.mkdir(parents=True, exist_ok=True)

OUT_FILE = VEC_DIR / "LNS16_4_9_DPU_vectors.txt"

random.seed(12345)

def signed13_to_bits(x: int) -> int:
    if x < 0:
        x = (1 << 13) + x
    return x & 0x1FFF

def make_lns(sign: int, log_val: int) -> int:
    # Normal finite LNS16:
    # bits 15:14 = 01
    # bit 13     = sign
    # bits 12:0  = signed log field
    return 0x4000 | ((sign & 1) << 13) | signed13_to_bits(log_val)

def signed13_from_lns(x: int) -> int:
    v = x & 0x1FFF
    if v & 0x1000:
        v -= 0x2000
    return v

def sign_from_lns(x: int) -> int:
    return (x >> 13) & 1

def decode_lns(x: int) -> float:
    if x == 0x0000:
        return 0.0

    if (x >> 14) != 0b01:
        # For now the DPU tests focus on normal finite numbers plus zero.
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
        raise ValueError(f"Result out of signed-13-bit range: value={value}, log_fixed={log_fixed}")

    return make_lns(sign, log_fixed)

def dpu_expected(A, B, C0):
    acc = decode_lns(C0)
    for a, b in zip(A, B):
        acc += decode_lns(a) * decode_lns(b)
    return encode_lns_real(acc)

def lns_pos(log_fixed):
    return make_lns(0, log_fixed)

def lns_neg(log_fixed):
    return make_lns(1, log_fixed)

def safe_expected(A, B, C0):
    try:
        return dpu_expected(A, B, C0)
    except ValueError:
        return None

def add_vector(vectors, A, B, C0, tol):
    exp = safe_expected(A, B, C0)
    if exp is not None:
        vectors.append((A, B, C0, exp, tol))

def write_vectors(path: Path, vectors):
    with path.open("w") as f:
        for idx, (A, B, C0, exp, tol) in enumerate(vectors, start=1):
            f.write(
                f"{idx} "
                f"{A[0]:04X} {A[1]:04X} {A[2]:04X} {A[3]:04X} "
                f"{B[0]:04X} {B[1]:04X} {B[2]:04X} {B[3]:04X} "
                f"{C0:04X} {exp:04X} {tol}\n"
            )

# Convenient constants.
ZERO = 0x0000

P025 = lns_pos(-1024)  # +0.25
P05  = lns_pos(-512)   # +0.5
P1   = lns_pos(0)      # +1
P2   = lns_pos(512)    # +2
P4   = lns_pos(1024)   # +4

N025 = lns_neg(-1024)
N05  = lns_neg(-512)
N1   = lns_neg(0)
N2   = lns_neg(512)
N4   = lns_neg(1024)

VALUES_BASIC = [P025, P05, P1, P2, P4, N025, N05, N1, N2, N4]

vectors = []

# -------------------------------------------------------------------------
# 1. Original simple / structural vectors
# -------------------------------------------------------------------------

single_lane_cases = [
    ([P1, ZERO, ZERO, ZERO], [P1, P1, P1, P1], ZERO),
    ([P2, ZERO, ZERO, ZERO], [P1, P1, P1, P1], ZERO),
    ([P05, ZERO, ZERO, ZERO], [P2, P1, P1, P1], ZERO),
    ([N1, ZERO, ZERO, ZERO], [P2, P1, P1, P1], ZERO),
    ([P2, ZERO, ZERO, ZERO], [N1, P1, P1, P1], ZERO),
]

for A, B, C0 in single_lane_cases:
    add_vector(vectors, A, B, C0, tol=8)

positive_cases = [
    ([P1, P1, P1, P1], [P1, P1, P1, P1], ZERO),
    ([P1, P2, P05, P1], [P2, P1, P2, P05], ZERO),
    ([P05, P05, P05, P05], [P05, P05, P05, P05], ZERO),
    ([P2, P2, P1, P1], [P05, P05, P1, P1], P1),
    ([P4, P1, P05, P2], [P05, P2, P2, P05], P1),
]

for A, B, C0 in positive_cases:
    add_vector(vectors, A, B, C0, tol=16)

signed_cases = [
    ([P2, N1, P05, P1], [P1, P1, P1, P05], P1),
    ([N2, P1, P05, P2], [P1, P1, P1, P05], P2),
    ([P2, P1, N05, P05], [N1, P2, P2, P1], P4),
    ([N1, N1, P2, P05], [N1, P1, P05, P1], P1),
    ([P1, N2, P1, P05], [P1, P05, N1, P1], P2),
]

for A, B, C0 in signed_cases:
    add_vector(vectors, A, B, C0, tol=24)

# -------------------------------------------------------------------------
# 2. Explicit cancellation cases in different parts of the DPU tree
# -------------------------------------------------------------------------

# S01 cancellation: P0 + P1 = 0
cancellation_cases = [
    # P0 = +1, P1 = -1
    ([P1, N1, P1, P1], [P1, P1, P1, P1], ZERO),

    # P2 + P3 = 0
    ([P1, P1, P1, N1], [P1, P1, P1, P1], ZERO),

    # S01 = +2, S23 = -2 -> S0123 = 0
    ([P1, P1, N1, N1], [P1, P1, P1, P1], ZERO),

    # product sum cancelled by C0
    ([P1, P1, P1, P1], [P1, P1, P1, P1], N4),

    # mixed exact cancellations plus C0
    ([P2, N2, P05, N05], [P1, P1, P2, P2], P1),

    # cancellation with non-unit magnitudes
    ([P2, N2, P4, N4], [P05, P05, P025, P025], P2),

    # cancellation in S01, then S23 + C0
    ([P2, N2, P1, P05], [P1, P1, P1, P2], N2),

    # cancellation in S23, then S01 + C0
    ([P1, P2, P2, N2], [P1, P1, P1, P1], N2),
]

for A, B, C0 in cancellation_cases:
    add_vector(vectors, A, B, C0, tol=24)

# -------------------------------------------------------------------------
# 3. Exhaustive-ish small grid for simple values
#    Keep it limited: use lane patterns rather than full 10^8 combinations.
# -------------------------------------------------------------------------

lane_patterns = [
    [P1, P1, P1, P1],
    [P1, P2, P1, P05],
    [P2, P05, P1, P1],
    [N1, P1, P1, P05],
    [P1, N1, P2, P05],
    [P05, P05, N1, P2],
    [N2, P1, P05, P2],
    [P2, N05, P1, P05],
    [P025, P2, N1, P1],
    [N025, P2, P1, N1],
]

c0_values = [ZERO, P025, P05, P1, P2, N025, N05, N1, N2]

for A in lane_patterns:
    for B in lane_patterns:
        for C0 in c0_values:
            add_vector(vectors, A, B, C0, tol=48)

# -------------------------------------------------------------------------
# 4. Random normal finite vectors
# -------------------------------------------------------------------------

def random_lns_value():
    # Use moderate log range to avoid overflow and crazy dynamic range.
    # log_fixed in [-1024, +1024] corresponds to magnitudes [0.25, 4].
    log_fixed = random.choice([
        -1024, -768, -512, -384, -256, -128,
        0,
        128, 256, 384, 512, 768, 1024
    ])
    sign = random.randint(0, 1)
    return make_lns(sign, log_fixed)

def random_c0_value():
    # Sometimes zero, otherwise moderate finite value.
    if random.random() < 0.20:
        return ZERO
    return random_lns_value()

N_RANDOM = 500

for _ in range(N_RANDOM):
    A = [random_lns_value() for _ in range(4)]
    B = [random_lns_value() for _ in range(4)]
    C0 = random_c0_value()

    # Avoid cases where the ideal mathematical result is extremely close to zero.
    # Those are valid, but they are numerically delicate for approximate LNS adders.
    real_acc = decode_lns(C0)
    for a, b in zip(A, B):
        real_acc += decode_lns(a) * decode_lns(b)

    if abs(real_acc) < 0.05:
        continue

    add_vector(vectors, A, B, C0, tol=96)

# -------------------------------------------------------------------------
# 5. Random sparse vectors: many zeros
# -------------------------------------------------------------------------

def random_sparse_lns_value():
    if random.random() < 0.45:
        return ZERO
    return random_lns_value()

N_SPARSE = 300

for _ in range(N_SPARSE):
    A = [random_sparse_lns_value() for _ in range(4)]
    B = [random_sparse_lns_value() for _ in range(4)]
    C0 = random_c0_value()

    real_acc = decode_lns(C0)
    for a, b in zip(A, B):
        real_acc += decode_lns(a) * decode_lns(b)

    if abs(real_acc) < 0.05:
        continue

    add_vector(vectors, A, B, C0, tol=96)

write_vectors(OUT_FILE, vectors)

print(f"Wrote {len(vectors)} DPU vectors to {OUT_FILE}")
