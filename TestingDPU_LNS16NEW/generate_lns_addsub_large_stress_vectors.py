import math
import random
from pathlib import Path

# ============================================================
# Large LNSAddSub 4_9 stress-vector generator
# ============================================================
# Vector format expected by LNS_AddSub_4_9_comb_tb.vhd:
#   ID A_HEX B_HEX EXPECTED_HEX TOL
#
# LNS16 4_9 encoding:
#   0000       = zero
#   bits 15:14 = 01 normal finite
#   bit  13    = sign
#   bits 12:0  = signed log2 field
#   scale      = 512
# ============================================================

WF = 9
SCALE = 1 << WF

BASE = Path("TestingDPU_LNS16NEW")
VEC_DIR = BASE / "vectors"
VEC_DIR.mkdir(parents=True, exist_ok=True)

OUT_FILE = VEC_DIR / "LNSAddSub_large_stress_vectors.txt"

random.seed(20260601)

MIN_LOG = -4096
MAX_LOG = 4095
MIN_MAG = 2.0 ** (MIN_LOG / SCALE)


def signed13_to_bits(x: int) -> int:
    if x < 0:
        x = (1 << 13) + x
    return x & 0x1FFF


def make_lns(sign: int, log_val: int) -> int:
    assert MIN_LOG <= log_val <= MAX_LOG
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
        raise ValueError(f"non-normal unsupported input: {x:04X}")

    sign = -1.0 if sign_from_lns(x) else 1.0
    log_val = signed13_from_lns(x) / SCALE
    return sign * (2.0 ** log_val)


def encode_lns_real(value: float) -> int:
    # Clamp underflow to zero. This is the behavior we want to validate
    # for near-cancellation cases.
    if abs(value) < MIN_MAG:
        return 0x0000

    sign = 1 if value < 0.0 else 0
    log_fixed = int(round(math.log2(abs(value)) * SCALE))

    if log_fixed < MIN_LOG:
        return 0x0000

    if log_fixed > MAX_LOG:
        # Saturate instead of crashing; this should rarely happen in these tests.
        log_fixed = MAX_LOG

    return make_lns(sign, log_fixed)


def expected_addsub(a: int, b: int) -> int:
    return encode_lns_real(decode_lns(a) + decode_lns(b))


def add_vec(vectors, a: int, b: int, tol: int):
    exp = expected_addsub(a, b)
    vectors.append((a, b, exp, tol))


def write_vectors(path: Path, vectors):
    with path.open("w") as f:
        for idx, (a, b, exp, tol) in enumerate(vectors, start=300001):
            f.write(f"{idx} {a:04X} {b:04X} {exp:04X} {tol}\n")


def random_log():
    # Keep most values in a practical range, but include some extremes.
    choices = (
        list(range(-2048, 2049, 64)) +
        [-4096, -3584, -3072, -2560, 2560, 3072, 3584, 4095]
    )
    return random.choice(choices)


def random_lns():
    # Some zeros, mostly normal finite values.
    if random.random() < 0.05:
        return 0x0000
    return make_lns(random.randint(0, 1), random_log())


vectors = []

# ------------------------------------------------------------
# 1. Same-sign near-equal additions.
# These should increase log by about +512.
# ------------------------------------------------------------
for sign in [0, 1]:
    for base_log in range(-2048, 2049, 128):
        for d in [-8, -4, -2, -1, 0, 1, 2, 4, 8]:
            log_a = base_log
            log_b = base_log + d
            if MIN_LOG <= log_b <= MAX_LOG:
                a = make_lns(sign, log_a)
                b = make_lns(sign, log_b)
                add_vec(vectors, a, b, tol=16)
                add_vec(vectors, b, a, tol=16)

# ------------------------------------------------------------
# 2. Opposite-sign exact and near cancellation.
# Exact equal should be zero.
# Very close difference below min magnitude should be zero.
# ------------------------------------------------------------
for base_log in range(-2048, 2049, 128):
    for d in [-4, -2, -1, 0, 1, 2, 4]:
        log_a = base_log
        log_b = base_log + d
        if MIN_LOG <= log_b <= MAX_LOG:
            a_pos = make_lns(0, log_a)
            b_neg = make_lns(1, log_b)
            add_vec(vectors, a_pos, b_neg, tol=32)
            add_vec(vectors, b_neg, a_pos, tol=32)

# ------------------------------------------------------------
# 3. Known debug cases from DPU/HMMA investigation.
# ------------------------------------------------------------
known = [
    (0x661A, 0x661B, 16),
    (0x661B, 0x661A, 16),
    (0x4151, 0x4152, 16),
    (0x6151, 0x6152, 16),
    (0x461A, 0x461B, 16),
    (0x79CC, 0x59CA, 32),
    (0x59CA, 0x79CC, 32),
    (0x4000, 0x6000, 0),
    (0x4200, 0x6200, 0),
    (0x5E00, 0x7E00, 0),
]
for a, b, tol in known:
    add_vec(vectors, a, b, tol)

# ------------------------------------------------------------
# 4. Broad random stress.
# Tolerance is intentionally looser because FloPoCo LNSAddSub
# is approximate, but sign/zero disasters will still be caught.
# ------------------------------------------------------------
for _ in range(5000):
    a = random_lns()
    b = random_lns()
    add_vec(vectors, a, b, tol=128)

write_vectors(OUT_FILE, vectors)

print(f"Wrote {len(vectors)} vectors to {OUT_FILE}")
print("Next: add this file to LNS_AddSub_4_9_comb_tb.vhd with run_vector_file(BASE_PATH & \"LNSAddSub_large_stress_vectors.txt\");")
