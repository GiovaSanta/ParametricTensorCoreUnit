import math
import random
from pathlib import Path

W_F = 9
SCALE = 1 << W_F
LOG_MASK = 0x1FFF

OUT_DIR = Path(__file__).parent / "vectors"
OUT_DIR.mkdir(exist_ok=True)

def sign_extend_13(x: int) -> int:
    x &= LOG_MASK
    return x - 0x2000 if x & 0x1000 else x

def encode_lns(value: float) -> int:
    if value == 0.0:
        return 0x0000

    sign_bit = 1 if value < 0 else 0
    mag = abs(value)

    log_scaled = int(round(math.log2(mag) * SCALE))

    if log_scaled < -4096:
        log_scaled = -4096
    if log_scaled > 4095:
        log_scaled = 4095

    log_field = log_scaled & LOG_MASK

    # normal finite value: exception/status bits = 01
    return 0x4000 | (sign_bit << 13) | log_field

def decode_lns(code: int) -> float:
    status = (code >> 14) & 0x3
    sign_bit = (code >> 13) & 0x1
    log_field = code & LOG_MASK

    if status == 0:
        return 0.0

    log_scaled = sign_extend_13(log_field)
    mag = 2.0 ** (log_scaled / SCALE)

    return -mag if sign_bit else mag

def expected_add(a_code: int, b_code: int) -> int:
    return encode_lns(decode_lns(a_code) + decode_lns(b_code))

def h(x: int) -> str:
    return f"{x & 0xFFFF:04X}"

def write_vectors(filename: str, vectors):
    path = OUT_DIR / filename
    with path.open("w", newline="\n") as f:
        for tid, a, b, exp, tol in vectors:
            f.write(f"{tid} {h(a)} {h(b)} {h(exp)} {tol}\n")
    print(f"Wrote {len(vectors)} vectors to {path}")

vectors_same_sign = []
vectors_opposite_basic = []
vectors_random = []

tid = 1

# Powers of two from 2^-8 to 2^8
powers = [2.0 ** e for e in range(-8, 7)]

# Same-sign positive + positive
for a in powers:
    for b in powers:
        ac = encode_lns(a)
        bc = encode_lns(b)
        exp = expected_add(ac, bc)
        vectors_same_sign.append((tid, ac, bc, exp, 2))
        tid += 1

# Same-sign negative + negative
for a in powers:
    for b in powers:
        ac = encode_lns(-a)
        bc = encode_lns(-b)
        exp = expected_add(ac, bc)
        vectors_same_sign.append((tid, ac, bc, exp, 2))
        tid += 1

# Opposite-sign basic tests, avoiding exact cancellation
# These are controlled ratios: 1 - 1/2, 1 - 1/4, 1 - 1/8, 1 - 1/16
for base_exp in range(-4, 5):
    big = 2.0 ** base_exp
    for delta in [1, 2, 3, 4]:
        small = 2.0 ** (base_exp - delta)

        for a, b in [
            ( big, -small),
            (-big,  small),
            ( small, -big),
            (-small,  big),
        ]:
            ac = encode_lns(a)
            bc = encode_lns(b)
            exp = expected_add(ac, bc)
            vectors_opposite_basic.append((tid, ac, bc, exp, 2))
            tid += 1

# Random stress file, not necessarily expected to pass yet
random.seed(1234)
for _ in range(500):
    ea = random.randint(-8, 8)
    eb = random.randint(-8, 8)
    fa = random.uniform(0.75, 1.75)
    fb = random.uniform(0.75, 1.75)

    a = fa * (2.0 ** ea)
    b = fb * (2.0 ** eb)

    if random.random() < 0.5:
        a = -a
    if random.random() < 0.5:
        b = -b

    # avoid near-exact cancellation for now
    if abs(a + b) < 1e-12:
        continue

    ac = encode_lns(a)
    bc = encode_lns(b)
    exp = expected_add(ac, bc)
    vectors_random.append((tid, ac, bc, exp, 3))
    tid += 1

write_vectors("LNSAddSub_same_sign_vectors.txt", vectors_same_sign)
write_vectors("LNSAddSub_opposite_basic_vectors.txt", vectors_opposite_basic)
write_vectors("LNSAddSub_random_stress_vectors.txt", vectors_random)
