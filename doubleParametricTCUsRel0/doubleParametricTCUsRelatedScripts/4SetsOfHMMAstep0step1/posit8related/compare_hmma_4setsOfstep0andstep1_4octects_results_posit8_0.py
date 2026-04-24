import re
import math
from pathlib import Path


# ============================================================
# Posit8,0 helpers
# ============================================================
POSIT_NBITS = 8
POSIT_ES = 0
POSIT_NAR = 1 << (POSIT_NBITS - 1)
POSIT_MASK = (1 << POSIT_NBITS) - 1


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


def hex8_to_posit8_0(hex_str: str) -> float:
    bits = int(hex_str, 16)
    return posit_bits_to_float(bits)


# ============================================================
# Generic helpers
# ============================================================
def write_line(out, text=""):
    print(text)
    out.write(text + "\n")


def read_matrix(lines, start_idx, rows):
    matrix = []
    i = start_idx
    for _ in range(rows):
        i += 1
        if i >= len(lines):
            raise ValueError("Unexpected end of file while reading matrix.")
        row = lines[i].strip().split()
        matrix.append([x.upper() for x in row])
    return matrix, i + 1


# ============================================================
# Parse simulator output
# ============================================================
def parse_sim_output(path: str):
    lines = Path(path).read_text(encoding="utf-8").splitlines()

    results = {
        "sets": {},
        "final_16x16": None,
    }

    i = 0
    current_set = None

    valid_names = (
        "#STEP0_D00", "#STEP0_D10", "#STEP1_D01", "#STEP1_D11",
        "#STEP0_D20", "#STEP0_D30", "#STEP1_D21", "#STEP1_D31",
        "#STEP0_D02", "#STEP0_D12", "#STEP1_D03", "#STEP1_D13",
        "#STEP0_D22", "#STEP0_D32", "#STEP1_D23", "#STEP1_D33",
    )

    while i < len(lines):
        line = lines[i].strip()

        m = re.match(r"#SET\s+(\d+)\s+results", line, re.IGNORECASE)
        if m:
            current_set = int(m.group(1))
            results["sets"][current_set] = {}
            i += 1
            continue

        if line.upper() in valid_names:
            if current_set is None:
                raise ValueError(f"Found {line} before any #SET header in simulator output.")
            mat_name = line[1:].upper()
            matrix, i = read_matrix(lines, i, 4)
            results["sets"][current_set][mat_name] = matrix
            continue

        if line.upper() == "#FINAL_16X16_RESULT":
            matrix, i = read_matrix(lines, i, 16)
            results["final_16x16"] = matrix
            continue

        i += 1

    if not results["sets"] and results["final_16x16"] is None:
        raise ValueError(
            f"No simulator sections recognized in file:\n{path}\n"
            "Expected markers like '#SET 0 results' or '#FINAL_16x16_RESULT'."
        )

    return results


# ============================================================
# Parse golden/reference file
# ============================================================
def parse_golden_file(path: str):
    lines = Path(path).read_text(encoding="utf-8").splitlines()

    results = {
        "sets": {},
        "final_16x16_staged": None,
        "final_16x16_ideal": None,
    }

    i = 0

    while i < len(lines):
        line = lines[i].strip()

        m = re.match(
            r"#golden\s+TC([01])\s+"
            r"(STEP0_D00|STEP0_D10|STEP1_D01|STEP1_D11|STEP0_D20|STEP0_D30|STEP1_D21|STEP1_D31)"
            r"_set(\d+)\s+encoded",
            line,
            re.IGNORECASE,
        )
        if m:
            tc_id = int(m.group(1))
            local_name = m.group(2).upper()
            set_id = int(m.group(3))

            if tc_id == 0:
                global_name = local_name
            else:
                remap = {
                    "STEP0_D00": "STEP0_D02",
                    "STEP0_D10": "STEP0_D12",
                    "STEP1_D01": "STEP1_D03",
                    "STEP1_D11": "STEP1_D13",
                    "STEP0_D20": "STEP0_D22",
                    "STEP0_D30": "STEP0_D32",
                    "STEP1_D21": "STEP1_D23",
                    "STEP1_D31": "STEP1_D33",
                }
                global_name = remap[local_name]

            if set_id not in results["sets"]:
                results["sets"][set_id] = {}

            matrix, i = read_matrix(lines, i, 4)
            results["sets"][set_id][global_name] = matrix
            continue

        if line.upper() == "#D_FULL_FROM_2TC ENCODED":
            matrix, i = read_matrix(lines, i, 16)
            results["final_16x16_staged"] = matrix
            continue

        if line.upper() == "#D_FULL_ONE_SHOT ENCODED":
            matrix, i = read_matrix(lines, i, 16)
            results["final_16x16_ideal"] = matrix
            continue

        i += 1

    if not results["sets"] and results["final_16x16_staged"] is None and results["final_16x16_ideal"] is None:
        raise ValueError(
            f"No golden sections recognized in file:\n{path}\n"
            "Expected markers like '#golden TC0 STEP0_D00_set0 encoded', "
            "'#golden TC1 STEP0_D00_set0 encoded', "
            "'#D_full_from_2tc encoded', or '#D_full_one_shot encoded'."
        )

    return results


# ============================================================
# Comparison helpers
# ============================================================
def compare_matrix(sim_mat, gold_mat, out, tolerance=0.0):
    rows = len(sim_mat)
    cols = len(sim_mat[0]) if rows else 0

    diff_count = 0
    max_abs_diff = 0.0
    hex_mismatch_count = 0

    write_line(out, "row col | obtained(hex) obtained(val) | golden(hex) golden(val) | abs diff")

    for r in range(rows):
        for c in range(cols):
            sim_hex = sim_mat[r][c].upper()
            gold_hex = gold_mat[r][c].upper()

            sim_val = hex8_to_posit8_0(sim_hex)
            gold_val = hex8_to_posit8_0(gold_hex)

            if math.isnan(sim_val) and math.isnan(gold_val):
                diff = 0.0
            else:
                diff = abs(sim_val - gold_val)

            if diff > max_abs_diff:
                max_abs_diff = diff

            is_diff = (sim_hex != gold_hex) or (diff > tolerance)
            if sim_hex != gold_hex:
                hex_mismatch_count += 1

            if is_diff:
                diff_count += 1
                write_line(
                    out,
                    f"{r:>3} {c:>3} | "
                    f"{sim_hex:>8} {sim_val:>14.8g} | "
                    f"{gold_hex:>8} {gold_val:>14.8g} | "
                    f"{diff:>14.8g}"
                )

    if diff_count == 0:
        write_line(out, "All entries match within tolerance and encoded-word equality.")

    return diff_count, max_abs_diff, hex_mismatch_count


def compare_sets(sim_data, golden_data, out, tolerance=0.0):
    all_sets = sorted(set(sim_data["sets"].keys()) | set(golden_data["sets"].keys()))
    matrix_names = (
        "STEP0_D00", "STEP0_D10", "STEP1_D01", "STEP1_D11",
        "STEP0_D20", "STEP0_D30", "STEP1_D21", "STEP1_D31",
        "STEP0_D02", "STEP0_D12", "STEP1_D03", "STEP1_D13",
        "STEP0_D22", "STEP0_D32", "STEP1_D23", "STEP1_D33",
    )

    total_diff_count = 0
    total_missing_sets = 0
    total_missing_matrices = 0
    total_hex_mismatches = 0

    for set_id in all_sets:
        write_line(out, f"\n========== SET {set_id} ==========")

        if set_id not in sim_data["sets"]:
            write_line(out, "Missing set in simulator output")
            total_missing_sets += 1
            continue

        if set_id not in golden_data["sets"]:
            write_line(out, "Missing set in golden file")
            total_missing_sets += 1
            continue

        for mat_name in matrix_names:
            sim_mat = sim_data["sets"][set_id].get(mat_name)
            gold_mat = golden_data["sets"][set_id].get(mat_name)

            if sim_mat is None or gold_mat is None:
                write_line(out, f"\n{mat_name}: missing in one of the files")
                total_missing_matrices += 1
                continue

            write_line(out, f"\n{mat_name}:")
            local_diff, max_abs, local_hex_mismatches = compare_matrix(sim_mat, gold_mat, out, tolerance=tolerance)
            total_diff_count += local_diff
            total_hex_mismatches += local_hex_mismatches

            if local_diff != 0:
                write_line(out, f"--> {local_diff} differing entries in {mat_name}")
                write_line(out, f"--> hex mismatches in {mat_name}: {local_hex_mismatches}")
                write_line(out, f"--> max abs diff in {mat_name}: {max_abs:.8g}")

    return total_diff_count, total_missing_sets, total_missing_matrices, total_hex_mismatches


def compare_named_matrix(title, sim_mat, gold_mat, out, tolerance=0.0):
    write_line(out, f"\n========== {title} ==========")

    if sim_mat is None and gold_mat is None:
        write_line(out, "Missing in both files.")
        return 0, 1, 0

    if sim_mat is None:
        write_line(out, "Missing in simulator output.")
        return 0, 1, 0

    if gold_mat is None:
        write_line(out, "Missing in golden file.")
        return 0, 1, 0

    diff_count, max_abs, hex_mismatch_count = compare_matrix(sim_mat, gold_mat, out, tolerance=tolerance)

    if diff_count != 0:
        write_line(out, f"--> {diff_count} differing entries")
        write_line(out, f"--> hex mismatches: {hex_mismatch_count}")
        write_line(out, f"--> max abs diff: {max_abs:.8g}")
    else:
        write_line(out, "Match within tolerance and encoded-word equality.")

    return diff_count, 0, hex_mismatch_count


# ============================================================
# Main
# ============================================================
if __name__ == "__main__":
    sim_output_file = (
        r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi"
        r"\doubleParametricTCUsRel0\doubleParametricTCUsRelatedScripts"
        r"\4SetsOfHMMAstep0step1\posit8related"
        r"\hmma_8instr_dualTC_4octects_tb_output_ctrl_posit8.txt"
    )

    golden_file = (
        r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi"
        r"\doubleParametricTCUsRel0\doubleParametricTCUsRelatedScripts"
        r"\4SetsOfHMMAstep0step1\posit8related"
        r"\hmma_8instr_dualTC_4octects_posit8_single_experiment.txt"
    )

    report_file = (
        r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi"
        r"\doubleParametricTCUsRel0\doubleParametricTCUsRelatedScripts"
        r"\4SetsOfHMMAstep0step1\posit8related"
        r"\hmma_8instr_dualTC_4octects_posit8_validation_report.txt"
    )

    tolerance = 0.0

    sim_data = parse_sim_output(sim_output_file)
    golden_data = parse_golden_file(golden_file)

    print("Parsed simulator sets:", sorted(sim_data["sets"].keys()))
    print("Parsed golden sets   :", sorted(golden_data["sets"].keys()))
    print("Simulator final 16x16 present     :", sim_data["final_16x16"] is not None)
    print("Golden staged final 16x16 present :", golden_data["final_16x16_staged"] is not None)
    print("Golden ideal final 16x16 present  :", golden_data["final_16x16_ideal"] is not None)

    with open(report_file, "w", encoding="utf-8") as out:
        write_line(out, "HMMA 4-SET STEP0/STEP1 POSIT8,0 VALIDATION REPORT (DUAL TC, 4 OCTECTS)")
        write_line(out, f"Simulator output file: {sim_output_file}")
        write_line(out, f"Golden reference file: {golden_file}")
        write_line(out, f"Tolerance: {tolerance}")
        write_line(out, "Primary check: exact equality of 8-bit posit encoded words.")
        write_line(out)

        set_diffs, missing_sets, missing_mats, set_hex_mismatches = compare_sets(
            sim_data, golden_data, out, tolerance=tolerance
        )

        staged_diffs, staged_missing, staged_hex_mismatches = compare_named_matrix(
            "FINAL 16x16 RESULT vs FINAL_CHAINED_16x16_FROM_DUAL_TC_POSIT8",
            sim_data["final_16x16"],
            golden_data["final_16x16_staged"],
            out,
            tolerance=tolerance,
        )

        ideal_diffs, ideal_missing, ideal_hex_mismatches = compare_named_matrix(
            "FINAL 16x16 RESULT vs FINAL_IDEAL_16x16_ONE_SHOT_REFERENCE",
            sim_data["final_16x16"],
            golden_data["final_16x16_ideal"],
            out,
            tolerance=tolerance,
        )

        total_diffs = set_diffs + staged_diffs + ideal_diffs
        total_missing = missing_sets + missing_mats + staged_missing + ideal_missing
        total_hex_mismatches = set_hex_mismatches + staged_hex_mismatches + ideal_hex_mismatches

        write_line(out, "\n====================================")
        write_line(out, f"Total differing entries: {total_diffs}")
        write_line(out, f"Total hex mismatches: {total_hex_mismatches}")
        write_line(out, f"Total missing items: {total_missing}")

    print(f"\nReport written to: {report_file}")
