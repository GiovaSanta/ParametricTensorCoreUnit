def signed13_to_bits(x):
    if x < 0:
        x = (1 << 13) + x
    return x & 0x1FFF

def make_lns(sign, log_val):
    """
    LNS16 format used here:
    bits 15:14 = 01 normal finite
    bit 13     = sign
    bits 12:0  = signed log field, wE+wF = 13
    """
    normal_prefix = 0x4000
    sign_bit = 0x2000 if sign else 0x0000
    return normal_prefix | sign_bit | signed13_to_bits(log_val)

def signed13_from_lns(x):
    v = x & 0x1FFF
    if v & 0x1000:
        v -= 0x2000
    return v

def sign_from_lns(x):
    return (x >> 13) & 1

def lns_mul_expected(a, b):
    sign_a = sign_from_lns(a)
    sign_b = sign_from_lns(b)

    log_a = signed13_from_lns(a)
    log_b = signed13_from_lns(b)

    sign_r = sign_a ^ sign_b
    log_r = log_a + log_b

    # Keep these structured tests inside valid signed-13-bit range.
    assert -4096 <= log_r <= 4095, (log_a, log_b, log_r)

    return make_lns(sign_r, log_r)

def write_vectors(filename, vectors):
    with open(filename, "w") as f:
        for i, (a, b, exp, tol) in enumerate(vectors, start=1):
            f.write(f"{i} {a:04X} {b:04X} {exp:04X} {tol}\n")

basic = []
logs = [-1024, -512, 0, 512, 1024]

for la in logs:
    for lb in logs:
        a = make_lns(0, la)
        b = make_lns(0, lb)
        exp = lns_mul_expected(a, b)
        basic.append((a, b, exp, 0))

signs = []
test_logs = [-1024, -512, 0, 512, 1024]

for la in test_logs:
    for lb in test_logs:
        for sa in [0, 1]:
            for sb in [0, 1]:
                a = make_lns(sa, la)
                b = make_lns(sb, lb)
                exp = lns_mul_expected(a, b)
                signs.append((a, b, exp, 0))

write_vectors("TestingDPU_LNS16NEW/vectors/LNSMul_basic_vectors.txt", basic)
write_vectors("TestingDPU_LNS16NEW/vectors/LNSMul_sign_vectors.txt", signs)

print(f"Wrote {len(basic)} basic vectors")
print(f"Wrote {len(signs)} sign vectors")
