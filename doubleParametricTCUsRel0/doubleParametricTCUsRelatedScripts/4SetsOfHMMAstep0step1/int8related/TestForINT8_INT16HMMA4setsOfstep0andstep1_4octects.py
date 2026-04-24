
import os
import numpy as np

SEED = 42
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

OUTPUT_FILE_HUMAN = os.path.join(SCRIPT_DIR, "hmma_8instr_dualTC_4octects_int8int16_single_experiment.txt")
OUTPUT_FILE_TB = os.path.join(SCRIPT_DIR, "hmma_8instr_dualTC_4octects_int8int16_single_experiment_tb_input.txt")

AB_VALUE_MIN = -16
AB_VALUE_MAX = 15
C_VALUE_MIN = -256
C_VALUE_MAX = 255

FULL_SIZE = 16
BLOCK = 4

INT8_MIN, INT8_MAX = -128, 127
INT16_MIN, INT16_MAX = -32768, 32767

def clamp_int16(x: int) -> int:
    return max(INT16_MIN, min(INT16_MAX, int(x)))

def int8_to_hex(x: int) -> str:
    return f"{(int(x) & 0xFF):02X}"

def int16_to_hex(x: int) -> str:
    return f"{(int(x) & 0xFFFF):04X}"

def matrix_to_lines_decimal(mat: np.ndarray) -> str:
    return "\n".join(" ".join(str(int(v)) for v in row) for row in mat)

def matrix_to_lines_hex_int8(mat: np.ndarray) -> str:
    return "\n".join(" ".join(int8_to_hex(int(v)) for v in row) for row in mat)

def matrix_to_lines_hex_int16(mat: np.ndarray) -> str:
    return "\n".join(" ".join(int16_to_hex(int(v)) for v in row) for row in mat)

def random_int8_matrix(rng, low=AB_VALUE_MIN, high=AB_VALUE_MAX, shape=(FULL_SIZE, FULL_SIZE)):
    return rng.integers(low, high + 1, size=shape, dtype=np.int16)

def random_int16_matrix(rng, low=C_VALUE_MIN, high=C_VALUE_MAX, shape=(FULL_SIZE, FULL_SIZE)):
    return rng.integers(low, high + 1, size=shape, dtype=np.int32)

def is_safe_int8_matrix(mat):
    return np.all(mat >= INT8_MIN) and np.all(mat <= INT8_MAX)

def is_safe_int16_matrix(mat):
    return np.all(mat >= INT16_MIN) and np.all(mat <= INT16_MAX)

def int8_int16_matmul_add(A, B, C):
    result_i32 = A.astype(np.int32) @ B.astype(np.int32) + C.astype(np.int32)
    out = np.empty(result_i32.shape, dtype=np.int32)
    for r in range(result_i32.shape[0]):
        for c in range(result_i32.shape[1]):
            out[r, c] = clamp_int16(result_i32[r, c])
    return out

def get_block(M, br, bc):
    r0 = br * BLOCK
    c0 = bc * BLOCK
    return M[r0:r0 + BLOCK, c0:c0 + BLOCK].copy()

def write_matrix_with_encoded_int8(f, name, mat):
    f.write(f"#{name}\n")
    f.write(matrix_to_lines_decimal(mat) + "\n")
    f.write(f"#{name} encoded\n")
    f.write(matrix_to_lines_hex_int8(mat) + "\n")

def write_matrix_with_encoded_int16(f, name, mat):
    f.write(f"#{name}\n")
    f.write(matrix_to_lines_decimal(mat) + "\n")
    f.write(f"#{name} encoded\n")
    f.write(matrix_to_lines_hex_int16(mat) + "\n")

def write_set_block(f, set_idx, prefix,
                    A00,A10,A20,A30,B_left,B_right,B_left_T,B_right_T,
                    C00,C10,C01,C11,C20,C30,C21,C31,
                    D00,D10,D01,D11,D20,D30,D21,D31):
    f.write(f"#================ {prefix} SET {set_idx} ================\n")

    for n,m in [
        (f"{prefix}_A0{set_idx}",A00),(f"{prefix}_A1{set_idx}",A10),
        (f"{prefix}_A2{set_idx}",A20),(f"{prefix}_A3{set_idx}",A30),
        (f"{prefix}_B{set_idx}L",B_left),(f"{prefix}_B{set_idx}R",B_right),
        (f"{prefix}_B{set_idx}L_T_for_HMMA",B_left_T),(f"{prefix}_B{set_idx}R_T_for_HMMA",B_right_T)
    ]:
        write_matrix_with_encoded_int8(f, n, m)

    for n,m in [
        (f"{prefix}_C00_set{set_idx}",C00),(f"{prefix}_C10_set{set_idx}",C10),
        (f"{prefix}_C01_set{set_idx}",C01),(f"{prefix}_C11_set{set_idx}",C11),
        (f"{prefix}_C20_set{set_idx}",C20),(f"{prefix}_C30_set{set_idx}",C30),
        (f"{prefix}_C21_set{set_idx}",C21),(f"{prefix}_C31_set{set_idx}",C31)
    ]:
        write_matrix_with_encoded_int16(f, n, m)

    for tag, M in [
        ("STEP0_D00",D00),("STEP0_D10",D10),("STEP1_D01",D01),("STEP1_D11",D11),
        ("STEP0_D20",D20),("STEP0_D30",D30),("STEP1_D21",D21),("STEP1_D31",D31)
    ]:
        f.write(f"#golden {prefix} {tag}_set{set_idx} decoded\n")
        f.write(matrix_to_lines_decimal(M) + "\n")
        f.write(f"#golden {prefix} {tag}_set{set_idx} encoded\n")
        f.write(matrix_to_lines_hex_int16(M) + "\n")

def encode_row_int8_hex(row):
    return [int8_to_hex(int(v)) for v in row]

def encode_row_int16_hex(row):
    return [int16_to_hex(int(v)) for v in row]

def pack_row_into_ports_int8(row):
    h = encode_row_int8_hex(row)
    return h[3] + h[2] + h[1] + h[0], "00000000"

def pack_row_into_ports_int16(row):
    h = encode_row_int16_hex(row)
    return h[1] + h[0], h[3] + h[2]

def write_tb_matrix_block_int8(f, label, mat, base_lane):
    f.write(f"#{label}\n")
    for i in range(4):
        portA, portB = pack_row_into_ports_int8(mat[i])
        f.write(f"#lane{base_lane+i}\n")
        f.write(f"{portA} {portB}\n")

def write_tb_matrix_block_int16(f, label, mat, base_lane):
    f.write(f"#{label}\n")
    for i in range(4):
        portA, portB = pack_row_into_ports_int16(mat[i])
        f.write(f"#lane{base_lane+i}\n")
        f.write(f"{portA} {portB}\n")

def write_tb_set0_dual_tc_phase_ordered(f, s0_tc0, s0_tc1):
    f.write("#================ SET 0 ================\n")

    f.write("#---- A payloads for both tensor cores (int8) ----\n")
    for label, mat, base in [
        ("tc0 oct0 A00", s0_tc0["A00"], 0), ("tc0 oct1 A10", s0_tc0["A10"], 4),
        ("tc0 oct2 A20", s0_tc0["A20"], 8), ("tc0 oct3 A30", s0_tc0["A30"], 12),
        ("tc1 oct0 A00", s0_tc1["A00"], 0), ("tc1 oct1 A10", s0_tc1["A10"], 4),
        ("tc1 oct2 A20", s0_tc1["A20"], 8), ("tc1 oct3 A30", s0_tc1["A30"], 12)
    ]:
        write_tb_matrix_block_int8(f, label, mat, base)

    f.write("#---- B payloads for both tensor cores (int8) ----\n")
    for label, mat, base in [
        ("tc0 oct0 B00_T_for_HMMA", s0_tc0["B_left_T"], 0), ("tc0 oct1 B01_T_for_HMMA", s0_tc0["B_right_T"], 4),
        ("tc0 oct2 B00_T_for_HMMA", s0_tc0["B_left_T"], 8), ("tc0 oct3 B01_T_for_HMMA", s0_tc0["B_right_T"], 12),
        ("tc1 oct0 B02_T_for_HMMA", s0_tc1["B_left_T"], 0), ("tc1 oct1 B03_T_for_HMMA", s0_tc1["B_right_T"], 4),
        ("tc1 oct2 B02_T_for_HMMA", s0_tc1["B_left_T"], 8), ("tc1 oct3 B03_T_for_HMMA", s0_tc1["B_right_T"], 12)
    ]:
        write_tb_matrix_block_int8(f, label, mat, base)

    f.write("#---- C step0 payloads for both tensor cores (int16) ----\n")
    for label, mat, base in [
        ("tc0 oct0 C00", s0_tc0["C00"], 0), ("tc0 oct1 C10", s0_tc0["C10"], 4),
        ("tc0 oct2 C20", s0_tc0["C20"], 8), ("tc0 oct3 C30", s0_tc0["C30"], 12),
        ("tc1 oct0 C02", s0_tc1["C00"], 0), ("tc1 oct1 C12", s0_tc1["C10"], 4),
        ("tc1 oct2 C22", s0_tc1["C20"], 8), ("tc1 oct3 C32", s0_tc1["C30"], 12)
    ]:
        write_tb_matrix_block_int16(f, label, mat, base)

    f.write("#---- C step1 payloads for both tensor cores (int16) ----\n")
    for label, mat, base in [
        ("tc0 oct0 C01", s0_tc0["C01"], 0), ("tc0 oct1 C11", s0_tc0["C11"], 4),
        ("tc0 oct2 C21", s0_tc0["C21"], 8), ("tc0 oct3 C31", s0_tc0["C31"], 12),
        ("tc1 oct0 C03", s0_tc1["C01"], 0), ("tc1 oct1 C13", s0_tc1["C11"], 4),
        ("tc1 oct2 C23", s0_tc1["C21"], 8), ("tc1 oct3 C33", s0_tc1["C31"], 12)
    ]:
        write_tb_matrix_block_int16(f, label, mat, base)

def write_tb_later_set_dual_tc_phase_ordered(f, set_idx, blk_tc0, blk_tc1):
    f.write(f"#================ SET {set_idx} ================\n")

    f.write("#---- A payloads for both tensor cores (int8) ----\n")
    for label, mat, base in [
        (f"tc0 oct0 A0{set_idx}", blk_tc0["A00"], 0), (f"tc0 oct1 A1{set_idx}", blk_tc0["A10"], 4),
        (f"tc0 oct2 A2{set_idx}", blk_tc0["A20"], 8), (f"tc0 oct3 A3{set_idx}", blk_tc0["A30"], 12),
        (f"tc1 oct0 A0{set_idx}", blk_tc1["A00"], 0), (f"tc1 oct1 A1{set_idx}", blk_tc1["A10"], 4),
        (f"tc1 oct2 A2{set_idx}", blk_tc1["A20"], 8), (f"tc1 oct3 A3{set_idx}", blk_tc1["A30"], 12)
    ]:
        write_tb_matrix_block_int8(f, label, mat, base)

    f.write("#---- B payloads for both tensor cores (int8) ----\n")
    for label, mat, base in [
        (f"tc0 oct0 B{set_idx}0_T_for_HMMA", blk_tc0["B_left_T"], 0), (f"tc0 oct1 B{set_idx}1_T_for_HMMA", blk_tc0["B_right_T"], 4),
        (f"tc0 oct2 B{set_idx}0_T_for_HMMA", blk_tc0["B_left_T"], 8), (f"tc0 oct3 B{set_idx}1_T_for_HMMA", blk_tc0["B_right_T"], 12),
        (f"tc1 oct0 B{set_idx}2_T_for_HMMA", blk_tc1["B_left_T"], 0), (f"tc1 oct1 B{set_idx}3_T_for_HMMA", blk_tc1["B_right_T"], 4),
        (f"tc1 oct2 B{set_idx}2_T_for_HMMA", blk_tc1["B_left_T"], 8), (f"tc1 oct3 B{set_idx}3_T_for_HMMA", blk_tc1["B_right_T"], 12)
    ]:
        write_tb_matrix_block_int8(f, label, mat, base)

def build_one_tc_safe_experiment(A, B, C, tc_col_base):
    staged = {}
    prev_D00 = prev_D10 = prev_D01 = prev_D11 = None
    prev_D20 = prev_D30 = prev_D21 = prev_D31 = None

    for s in range(4):
        A00 = get_block(A, 0, s); A10 = get_block(A, 1, s); A20 = get_block(A, 2, s); A30 = get_block(A, 3, s)
        B_left_full = get_block(B, s, tc_col_base + 0); B_right_full = get_block(B, s, tc_col_base + 1)
        B_left_T = B_left_full.T.astype(np.int16); B_right_T = B_right_full.T.astype(np.int16)

        if s == 0:
            C00 = get_block(C, 0, tc_col_base + 0); C10 = get_block(C, 1, tc_col_base + 0)
            C01 = get_block(C, 0, tc_col_base + 1); C11 = get_block(C, 1, tc_col_base + 1)
            C20 = get_block(C, 2, tc_col_base + 0); C30 = get_block(C, 3, tc_col_base + 0)
            C21 = get_block(C, 2, tc_col_base + 1); C31 = get_block(C, 3, tc_col_base + 1)
        else:
            C00 = prev_D00.copy(); C10 = prev_D10.copy(); C01 = prev_D01.copy(); C11 = prev_D11.copy()
            C20 = prev_D20.copy(); C30 = prev_D30.copy(); C21 = prev_D21.copy(); C31 = prev_D31.copy()

        D00 = int8_int16_matmul_add(A00, B_left_full, C00)
        D10 = int8_int16_matmul_add(A10, B_left_full, C10)
        D01 = int8_int16_matmul_add(A00, B_right_full, C01)
        D11 = int8_int16_matmul_add(A10, B_right_full, C11)
        D20 = int8_int16_matmul_add(A20, B_left_full, C20)
        D30 = int8_int16_matmul_add(A30, B_left_full, C30)
        D21 = int8_int16_matmul_add(A20, B_right_full, C21)
        D31 = int8_int16_matmul_add(A30, B_right_full, C31)

        staged[s] = {"A00":A00,"A10":A10,"A20":A20,"A30":A30,
                     "B_left_full":B_left_full,"B_right_full":B_right_full,"B_left_T":B_left_T,"B_right_T":B_right_T,
                     "C00":C00,"C10":C10,"C01":C01,"C11":C11,"C20":C20,"C30":C30,"C21":C21,"C31":C31,
                     "D00":D00,"D10":D10,"D01":D01,"D11":D11,"D20":D20,"D30":D30,"D21":D21,"D31":D31}

        prev_D00, prev_D10, prev_D01, prev_D11 = D00, D10, D01, D11
        prev_D20, prev_D30, prev_D21, prev_D31 = D20, D30, D21, D31

    final_16x8 = np.block([[staged[3]["D00"], staged[3]["D01"]],
                           [staged[3]["D10"], staged[3]["D11"]],
                           [staged[3]["D20"], staged[3]["D21"]],
                           [staged[3]["D30"], staged[3]["D31"]]]).astype(np.int32)
    return {"staged": staged, "final_16x8": final_16x8}

def build_dual_tc_safe_experiment(rng, max_attempts=20000):
    for _ in range(max_attempts):
        A = random_int8_matrix(rng); B = random_int8_matrix(rng); C = random_int16_matrix(rng)
        D_full_one_shot = int8_int16_matmul_add(A, B, C)
        if not is_safe_int16_matrix(D_full_one_shot):
            continue
        tc0 = build_one_tc_safe_experiment(A, B, C, 0)
        tc1 = build_one_tc_safe_experiment(A, B, C, 2)
        D_full_from_2tc = np.block([[tc0["final_16x8"], tc1["final_16x8"]]]).reshape(16,16).astype(np.int32)
        if is_safe_int16_matrix(D_full_from_2tc):
            return {"A":A,"B":B,"C":C,"D_full_one_shot":D_full_one_shot,"tc0":tc0,"tc1":tc1,"D_full_from_2tc":D_full_from_2tc}
    raise RuntimeError("Could not generate a safe dual-TC int8/int16 16x16 experiment.")

def write_human_file(f, exp):
    f.write("#Full 16x16 GEMM-ACC decomposed across 2 tensor cores, each with 2 octects (A/B=int8, C/D=int16)\n")
    f.write("#Golden math computes A @ B in int32, adds C(int16), then saturates once to int16 per 4x4 output block.\n")
    f.write("#Only the B payload written to the TB file is transposed for hardware feeding.\n\n")
    write_matrix_with_encoded_int8(f, "FULL_A_16x16", exp["A"])
    write_matrix_with_encoded_int8(f, "FULL_B_16x16", exp["B"])
    write_matrix_with_encoded_int16(f, "FULL_C_16x16", exp["C"])
    write_matrix_with_encoded_int16(f, "FULL_D_16x16_one_shot_reference", exp["D_full_one_shot"])
    for s in range(4):
        f.write("\n")
        blk0 = exp["tc0"]["staged"][s]
        write_set_block(f, s, "TC0", blk0["A00"],blk0["A10"],blk0["A20"],blk0["A30"],blk0["B_left_full"],blk0["B_right_full"],blk0["B_left_T"],blk0["B_right_T"],blk0["C00"],blk0["C10"],blk0["C01"],blk0["C11"],blk0["C20"],blk0["C30"],blk0["C21"],blk0["C31"],blk0["D00"],blk0["D10"],blk0["D01"],blk0["D11"],blk0["D20"],blk0["D30"],blk0["D21"],blk0["D31"])
        f.write("\n")
        blk1 = exp["tc1"]["staged"][s]
        write_set_block(f, s, "TC1", blk1["A00"],blk1["A10"],blk1["A20"],blk1["A30"],blk1["B_left_full"],blk1["B_right_full"],blk1["B_left_T"],blk1["B_right_T"],blk1["C00"],blk1["C10"],blk1["C01"],blk1["C11"],blk1["C20"],blk1["C30"],blk1["C21"],blk1["C31"],blk1["D00"],blk1["D10"],blk1["D01"],blk1["D11"],blk1["D20"],blk1["D30"],blk1["D21"],blk1["D31"])
    f.write("\n#FINAL_CHAINED_16x16_FROM_DUAL_TC_INT16\n")
    f.write("#D_full_from_2tc decoded\n")
    f.write(matrix_to_lines_decimal(exp["D_full_from_2tc"]) + "\n")
    f.write("#D_full_from_2tc encoded\n")
    f.write(matrix_to_lines_hex_int16(exp["D_full_from_2tc"]) + "\n")

def write_tb_file(f, exp):
    f.write("#register file ports content for mixed-precision INT8/INT16 dual tensor-core wrapper\n")
    f.write("#A and B are packed int8 rows into portA: [v3 v2 v1 v0], portB=00000000\n")
    f.write("#C is int16 and uses 16-bit packing: portA=[v1 v0], portB=[v3 v2]\n")
    f.write("#Later sets contain only A and B because C comes from chained results inside the TB.\n\n")
    write_tb_set0_dual_tc_phase_ordered(f, exp["tc0"]["staged"][0], exp["tc1"]["staged"][0])
    for s in range(1, 4):
        f.write("\n")
        write_tb_later_set_dual_tc_phase_ordered(f, s, exp["tc0"]["staged"][s], exp["tc1"]["staged"][s])

def main():
    print("Script started...")
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
