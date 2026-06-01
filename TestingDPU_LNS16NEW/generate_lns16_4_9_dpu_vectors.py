import math
from pathlib import Path

W_F = 9
SCALE = 1 << W_F

BASE = Path("TestingDPU_LNS16NEW")
VEC_DIR = BASE / "vectors"
VEC_DIR.mkdir(parents=True, exist_ok=True)

def signed13_to_bits(x: int) -> int:
    if x < 0:
        x = (1 << 13) + x
    return x & 0x1FFF

def make_lns(sign: int, log_val: int) -> int:
    # LNS16 normal finite encoding:
    #   bits 15:14 = 01
    #   bit 13     = sign
    #   bits 12:0  = signed log field
    return 0x4000 | ((sign & 1) << 13) | signed13_to_bits(log_val)

def signed13_from_lns(x: int) -> int:
    v = x & 0x1FFF
    if v & 0x1000:
        v -= 0x2000
    return v

def sign_from_lns(x: int) -> int:
    return (x >> 13) & 1

def decode_lns(x: int) -> float:
    # This generator focuses mainly on normal finite values.
    # Zero encoding is handled as exact zero.
    if x == 0x0000:
        return 0.0

    if (x >> 14) != 0b01:
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
        raise ValueError(f"Result out of signed-13-bit LNS range: value={value}, log_fixed={log_fixed}")

    return make_lns(sign, log_fixed)

def dpu_expected(A, B, C0):
    acc = decode_lns(C0)
    for a, b in zip(A, B):
        acc += decode_lns(a) * decode_lns(b)
    return encode_lns_real(acc)

def write_vectors(path: Path, vectors):
    with path.open("w") as f:
        for idx, (A, B, C0, exp, tol) in enumerate(vectors, start=1):
            f.write(
                f"{idx} "
                f"{A[0]:04X} {A[1]:04X} {A[2]:04X} {A[3]:04X} "
                f"{B[0]:04X} {B[1]:04X} {B[2]:04X} {B[3]:04X} "
                f"{C0:04X} {exp:04X} {tol}\n"
            )

def lns_pos(log_fixed):
    return make_lns(0, log_fixed)

def lns_neg(log_fixed):
    return make_lns(1, log_fixed)

# Normal finite values.
# log_fixed = 0    -> magnitude 1
# log_fixed = 512  -> magnitude 2
# log_fixed = -512 -> magnitude 0.5
P05 = lns_pos(-512)
P1  = lns_pos(0)
P2  = lns_pos(512)
P4  = lns_pos(1024)

N05 = lns_neg(-512)
N1  = lns_neg(0)
N2  = lns_neg(512)

ZERO = 0x0000

vectors = []

# Single-lane structural tests.
single_lane_cases = [
    ([P1, ZERO, ZERO, ZERO], [P1, P1, P1, P1], ZERO),
    ([P2, ZERO, ZERO, ZERO], [P1, P1, P1, P1], ZERO),
    ([P05, ZERO, ZERO, ZERO], [P2, P1, P1, P1], ZERO),
    ([N1, ZERO, ZERO, ZERO], [P2, P1, P1, P1], ZERO),
    ([P2, ZERO, ZERO, ZERO], [N1, P1, P1, P1], ZERO),
]

for A, B, C0 in single_lane_cases:
    exp = dpu_expected(A, B, C0)
    vectors.append((A, B, C0, exp, 8))

# Positive accumulation tests.
positive_cases = [
    ([P1, P1, P1, P1], [P1, P1, P1, P1], ZERO),
    ([P1, P2, P05, P1], [P2, P1, P2, P05], ZERO),
    ([P05, P05, P05, P05], [P05, P05, P05, P05], ZERO),
    ([P2, P2, P1, P1], [P05, P05, P1, P1], P1),
    ([P4, P1, P05, P2], [P05, P2, P2, P05], P1),
]

for A, B, C0 in positive_cases:
    exp = dpu_expected(A, B, C0)
    vectors.append((A, B, C0, exp, 12))

# Signed accumulation tests, avoiding exact or near-exact cancellation.
signed_cases = [
    ([P2, N1, P05, P1], [P1, P1, P1, P05], P1),
    ([N2, P1, P05, P2], [P1, P1, P1, P05], P2),
    ([P2, P1, N05, P05], [N1, P2, P2, P1], P4),
    ([N1, N1, P2, P05], [N1, P1, P05, P1], P1),
    ([P1, N2, P1, P05], [P1, P05, N1, P1], P2),
]

for A, B, C0 in signed_cases:
    exp = dpu_expected(A, B, C0)
    vectors.append((A, B, C0, exp, 16))

write_vectors(VEC_DIR / "LNS16_4_9_DPU_vectors.txt", vectors)

print(f"Wrote {len(vectors)} vectors to {VEC_DIR / 'LNS16_4_9_DPU_vectors.txt'}")
