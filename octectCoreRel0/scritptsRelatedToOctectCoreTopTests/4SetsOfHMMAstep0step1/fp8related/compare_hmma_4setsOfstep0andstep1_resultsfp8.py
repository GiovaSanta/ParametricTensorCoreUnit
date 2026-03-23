import re
import math
from pathlib import Path


# ============================================================
# FP8 E4M3 decode
# ============================================================
FP8_EXP_BITS = 4
FP8_MAN_BITS = 3
FP8_EXP_BIAS = 7


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


def hex8_to_float(hex_str: str) -> float:
    return fp8e4m3_decode_byte(int(hex_str, 16))


# ============================================================
# Small helpers
# ============================================================
def write_line(out, text=""):
    print(text)
    out.write(text + "\n")


def read_matrix(lines, start_idx, rows, cols):
    mat = []
    i = start_idx
    for _ in range(rows):
        row = lines[i].strip().split()
        if len(row) != cols:
            raise ValueError(
                f"Expected {cols} columns at line {i+1}, found {len(row)}: {lines[i]!r}"
            )
        mat.append([x.upper() for x in row])
        i += 1
    return mat, i


# ============================================================
# Parse simulator output file
# ============================================================
def parse_sim_output(path: str):
    lines = Path(path).read_text(encoding="utf-8").splitlines()

    results = {
        "sets": {},
        "final_8x8": None,
    }

    i = 0
    current_set = None

    while i < len(lines):
        line = lines[i].strip()

        m = re.match(r"#SET\s+(\d+)\s+results", line, re.IGNORECASE)
        if m:
            current_set = int(m.group(1))
            results["sets"][current_set] = {}
            i += 1
            continue

        if line == "#STEP0_D00" and current_set is not None:
            mat, i = read_matrix(lines, i + 1, 4, 4)
            results["sets"][current_set]["STEP0_D00"] = mat
            continue

        if line == "#STEP0_D10" and current_set is not None:
            mat, i = read_matrix(lines, i + 1, 4, 4)
            results["sets"][current_set]["STEP0_D10"] = mat
            continue

        if line == "#STEP1_D01" and current_set is not None:
            mat, i = read_matrix(lines, i + 1, 4, 4)
            results["sets"][current_set]["STEP1_D01"] = mat
            continue

        if line == "#STEP1_D11" and current_set is not None:
            mat, i = read_matrix(lines, i + 1, 4, 4)
            results["sets"][current_set]["STEP1_D11"] = mat
            continue

        if line == "#FINAL_8x8_QUADRANT":
            mat, i = read_matrix(lines, i + 1, 8, 8)
            results["final_8x8"] = mat
            continue

        i += 1

    return results


# ============================================================
# Parse golden/reference file
# ============================================================
def parse_golden_file(path: str):
    lines = Path(path).read_text(encoding="utf-8").splitlines()

    results = {
        "sets": {},
        "final_chained_blocks": {},
        "final_ideal_8x8": None,
    }

    i = 0
    current_set = None

    while i < len(lines):
        line = lines[i].strip()

        m = re.match(r"#=+\s*SET\s+(\d+)\s*=+", line, re.IGNORECASE)
        if m:
            current_set = int(m.group(1))
            results["sets"][current_set] = {}
            i += 1
            continue

        # per-set goldens
        if re.match(r"#golden STEP0_D00_set\d+ encoded", line, re.IGNORECASE):
            mat, i = read_matrix(lines, i + 1, 4, 4)
            results["sets"][current_set]["STEP0_D00"] = mat
            continue

        if re.match(r"#golden STEP0_D10_set\d+ encoded", line, re.IGNORECASE):
            mat, i = read_matrix(lines, i + 1, 4, 4)
            results["sets"][current_set]["STEP0_D10"] = mat
            continue

        if re.match(r"#golden STEP1_D01_set\d+ encoded", line, re.IGNORECASE):
            mat, i = read_matrix(lines, i + 1, 4, 4)
            results["sets"][current_set]["STEP1_D01"] = mat
            continue

        if re.match(r"#golden STEP1_D11_set\d+ encoded", line, re.IGNORECASE):
            mat, i = read_matrix(lines, i + 1, 4, 4)
            results["sets"][current_set]["STEP1_D11"] = mat
            continue

        # final chained blocks
        if line == "#D00_final encoded":
            mat, i = read_matrix(lines, i + 1, 4, 4)
            results["final_chained_blocks"]["D00"] = mat
            continue

        if line == "#D01_final encoded":
            mat, i = read_matrix(lines, i + 1, 4, 4)
            results["final_chained_blocks"]["D01"] = mat
            continue

        if line == "#D10_final encoded":
            mat, i = read_matrix(lines, i + 1, 4, 4)
            results["final_chained_blocks"]["D10"] = mat
            continue

        if line == "#D11_final encoded":
            mat, i = read_matrix(lines, i + 1, 4, 4)
            results["final_chained_blocks"]["D11"] = mat
            continue

        # final ideal 8x8
        if line == "#D_expected_top_left_8x8 encoded":
            mat, i = read_matrix(lines, i + 1, 8, 8)
            results["final_ideal_8x8"] = mat
            continue

        i += 1

    return results


# ============================================================
# Build 8x8 from final chained 4x4 blocks
# ============================================================
def build_8x8_from_final_blocks(blocks):
    d00 = blocks["D00"]
    d01 = blocks["D01"]
    d10 = blocks["D10"]
    d11 = blocks["D11"]

    top = [d00[r] + d01[r] for r in range(4)]
    bot = [d10[r] + d11[r] for r in range(4)]
    return top + bot


# ============================================================
# Comparison routines
# ============================================================
def compare_4x4_matrix(name, sim_mat, gold_mat, out, tolerance=0.0):
    write_line(out, f"\n{name}:")
    write_line(
        out,
        "row col | obtained(hex) obtained(val) | golden(hex) golden(val) | abs diff"
    )

    local_diff_count = 0
    local_max_diff = 0.0

    for r in range(4):
        for c in range(4):
            sim_hex = sim_mat[r][c]
            gold_hex = gold_mat[r][c]

            sim_val = hex8_to_float(sim_hex)
            gold_val = hex8_to_float(gold_hex)
            diff = abs(sim_val - gold_val)

            if diff > tolerance:
                local_diff_count += 1
                local_max_diff = max(local_max_diff, diff)
                write_line(
                    out,
                    f"{r:>3} {c:>3} | "
                    f"{sim_hex:>8} {sim_val:>12.6f} | "
                    f"{gold_hex:>8} {gold_val:>12.6f} | "
                    f"{diff:>10.6f}"
                )

    if local_diff_count == 0:
        write_line(out, "All entries match within tolerance.")
    else:
        write_line(out, f"--> {local_diff_count} differing entries in {name}")
        write_line(out, f"--> max abs diff in {name}: {local_max_diff:.6f}")

    return local_diff_count


def compare_8x8_matrix(title, sim_mat, gold_mat, out, tolerance=0.0):
    write_line(out, f"\n========== {title} ==========")
    write_line(
        out,
        "row col | obtained(hex) obtained(val) | golden(hex) golden(val) | abs diff"
    )

    diff_count = 0
    max_diff = 0.0

    for r in range(8):
        for c in range(8):
            sim_hex = sim_mat[r][c]
            gold_hex = gold_mat[r][c]

            sim_val = hex8_to_float(sim_hex)
            gold_val = hex8_to_float(gold_hex)
            diff = abs(sim_val - gold_val)

            if diff > tolerance:
                diff_count += 1
                max_diff = max(max_diff, diff)
                write_line(
                    out,
                    f"{r:>3} {c:>3} | "
                    f"{sim_hex:>8} {sim_val:>12.6f} | "
                    f"{gold_hex:>8} {gold_val:>12.6f} | "
                    f"{diff:>10.6f}"
                )

    if diff_count == 0:
        write_line(out, "All entries match within tolerance.")
    else:
        write_line(out, f"--> {diff_count} differing entries")
        write_line(out, f"--> max abs diff: {max_diff:.6f}")

    return diff_count


def compare_all(sim_data, golden_data, out, tolerance=0.0):
    total_diff_count = 0
    total_missing_items = 0

    matrix_names = ("STEP0_D00", "STEP0_D10", "STEP1_D01", "STEP1_D11")
    all_sets = sorted(set(sim_data["sets"].keys()) | set(golden_data["sets"].keys()))

    for set_idx in all_sets:
        write_line(out, f"\n========== SET {set_idx} ==========")

        if set_idx not in sim_data["sets"]:
            write_line(out, "Missing set in simulator output.")
            total_missing_items += 1
            continue

        if set_idx not in golden_data["sets"]:
            write_line(out, "Missing set in golden file.")
            total_missing_items += 1
            continue

        for mat_name in matrix_names:
            sim_mat = sim_data["sets"][set_idx].get(mat_name)
            gold_mat = golden_data["sets"][set_idx].get(mat_name)

            if sim_mat is None or gold_mat is None:
                write_line(out, f"{mat_name}: missing in one of the files")
                total_missing_items += 1
                continue

            total_diff_count += compare_4x4_matrix(
                mat_name, sim_mat, gold_mat, out, tolerance=tolerance
            )

    # Final 8x8 vs chained staged final
    sim_final = sim_data.get("final_8x8")
    chained_blocks = golden_data.get("final_chained_blocks", {})
    ideal_8x8 = golden_data.get("final_ideal_8x8")

    if sim_final is None:
        write_line(out, "\nFinal 8x8 quadrant missing in simulator output.")
        total_missing_items += 1
    else:
        if all(k in chained_blocks for k in ("D00", "D01", "D10", "D11")):
            gold_final_chained = build_8x8_from_final_blocks(chained_blocks)
            total_diff_count += compare_8x8_matrix(
                "FINAL 8x8 QUADRANT vs FINAL_CHAINED_8x8_FROM_STAGED_FP8",
                sim_final,
                gold_final_chained,
                out,
                tolerance=tolerance,
            )
        else:
            write_line(out, "\nMissing one or more final chained 4x4 blocks in golden file.")
            total_missing_items += 1

        if ideal_8x8 is not None:
            total_diff_count += compare_8x8_matrix(
                "FINAL 8x8 QUADRANT vs FINAL_IDEAL_8x8_ONE_SHOT_REFERENCE",
                sim_final,
                ideal_8x8,
                out,
                tolerance=tolerance,
            )
        else:
            write_line(out, "\nMissing final ideal 8x8 reference in golden file.")
            total_missing_items += 1

    write_line(out, "\n====================================")
    write_line(out, f"Total differing entries: {total_diff_count}")
    write_line(out, f"Total missing items: {total_missing_items}")


# ============================================================
# Main
# ============================================================
if __name__ == "__main__":
    sim_output_file = r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\octectCoreRel0\scritptsRelatedToOctectCoreTopTests\4SetsOfHMMAstep0step1\fp8related\hmma_8instr_tb_output_ctrl_fp8.txt"
    golden_file = r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\octectCoreRel0\scritptsRelatedToOctectCoreTopTests\4SetsOfHMMAstep0step1\fp8related\hmma_8instr_fp8_single_experiment.txt"
    report_file = r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\octectCoreRel0\scritptsRelatedToOctectCoreTopTests\4SetsOfHMMAstep0step1\fp8related\hmma_8instr_fp8_validation_report.txt"

    sim_data = parse_sim_output(sim_output_file)
    golden_data = parse_golden_file(golden_file)

    with open(report_file, "w", encoding="utf-8") as out:
        write_line(out, "HMMA 4-SET STEP0/STEP1 FP8 E4M3 VALIDATION REPORT")
        write_line(out, f"Simulator output file: {sim_output_file}")
        write_line(out, f"Golden reference file: {golden_file}")
        write_line(out, f"Tolerance: 0.0")
        write_line(out)

        compare_all(sim_data, golden_data, out, tolerance=0.0)

    print(f"\nReport written to: {report_file}")