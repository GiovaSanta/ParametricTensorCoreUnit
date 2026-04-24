import re
from pathlib import Path


# ============================================================
# FXP16 helpers
# D / C / final result format: signed_5_M10 on 16 bits
# ============================================================

FRAC_BITS = 10
WORD_BITS = 16


def twos_complement_to_signed(val: int, bits: int) -> int:
    if val & (1 << (bits - 1)):
        return val - (1 << bits)
    return val


def hex16_to_signed_int(hex_str: str) -> int:
    return twos_complement_to_signed(int(hex_str, 16), 16)


def hex16_to_real(hex_str: str) -> float:
    return hex16_to_signed_int(hex_str) / float(1 << FRAC_BITS)


def write_line(out, text=""):
    print(text)
    out.write(text + "\n")


def read_hex_matrix(lines, start_idx, rows):
    matrix = []
    i = start_idx
    for _ in range(rows):
        i += 1
        if i >= len(lines):
            raise ValueError("Unexpected end of file while reading matrix.")
        row = lines[i].strip().split()
        matrix.append([x.upper() for x in row])
    return matrix, i + 1


def skip_decoded_matrix(lines, start_idx, rows):
    i = start_idx
    for _ in range(rows):
        i += 1
        if i >= len(lines):
            raise ValueError("Unexpected end of file while skipping decoded matrix.")
    return i + 1


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
            matrix, i = read_hex_matrix(lines, i, 4)
            results["sets"][current_set][mat_name] = matrix
            continue

        if line.upper() == "#FINAL_16X16_RESULT":
            matrix, i = read_hex_matrix(lines, i, 16)
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
# Works with compact file containing:
#   #golden TC0 STEP0_D00_set0 decoded_real_signed_5_M10
#   ... 4 decoded rows ...
#   #golden TC0 STEP0_D00_set0 encoded
#   ... 4 encoded rows ...
#
# and similarly for TC1, plus final sections
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

        # ----------------------------------------------------
        # Golden block lines:
        # #golden TC0 STEP0_D00_set0 decoded_real_signed_5_M10
        # #golden TC1 STEP0_D00_set0 decoded_real_signed_5_M10
        # ----------------------------------------------------
        m = re.match(
            r"#golden\s+TC([01])\s+"
            r"(STEP0_D00|STEP0_D10|STEP1_D01|STEP1_D11|STEP0_D20|STEP0_D30|STEP1_D21|STEP1_D31)"
            r"_set(\d+)\s+decoded_real_signed_5_M10",
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

            # skip decoded 4x4 matrix
            i = skip_decoded_matrix(lines, i, 4)

            # next line must be encoded marker
            if i >= len(lines):
                raise ValueError(f"Unexpected EOF after decoded block for set {set_id} {global_name}")

            encoded_marker = lines[i].strip()
            expected_suffix = f"{local_name}_set{set_id} encoded"
            if expected_suffix.upper() not in encoded_marker.upper():
                raise ValueError(
                    f"Expected encoded marker after decoded block for set {set_id} {global_name}, got:\n{encoded_marker}"
                )

            matrix, i = read_hex_matrix(lines, i, 4)
            results["sets"][set_id][global_name] = matrix
            continue

        # ----------------------------------------------------
        # Final staged result
        # ----------------------------------------------------
        if line.upper() == "#FINAL_CHAINED_16X16_FROM_DUAL_TC_FXP16":
            # expect:
            # next line: #... decoded_real...
            # 16 decoded rows
            # next line: #... encoded
            # 16 encoded rows
            i += 1
            if i >= len(lines):
                raise ValueError("Unexpected EOF after FINAL_CHAINED header.")

            # skip decoded marker if present
            if "DECODED" in lines[i].upper():
                i = skip_decoded_matrix(lines, i, 16)
            else:
                raise ValueError(f"Expected decoded marker after FINAL_CHAINED header, got: {lines[i]}")

            if i >= len(lines):
                raise ValueError("Unexpected EOF before FINAL_CHAINED encoded marker.")

            if "ENCODED" not in lines[i].upper():
                raise ValueError(f"Expected encoded marker for FINAL_CHAINED, got: {lines[i]}")

            matrix, i = read_hex_matrix(lines, i, 16)
            results["final_16x16_staged"] = matrix
            continue

        # ----------------------------------------------------
        # Final ideal one-shot result
        # ----------------------------------------------------
        if line.upper() == "#FINAL_IDEAL_16X16_ONE_SHOT_REFERENCE":
            i += 1
            if i >= len(lines):
                raise ValueError("Unexpected EOF after FINAL_IDEAL header.")

            if "DECODED" in lines[i].upper():
                i = skip_decoded_matrix(lines, i, 16)
            else:
                raise ValueError(f"Expected decoded marker after FINAL_IDEAL header, got: {lines[i]}")

            if i >= len(lines):
                raise ValueError("Unexpected EOF before FINAL_IDEAL encoded marker.")

            if "ENCODED" not in lines[i].upper():
                raise ValueError(f"Expected encoded marker for FINAL_IDEAL, got: {lines[i]}")

            matrix, i = read_hex_matrix(lines, i, 16)
            results["final_16x16_ideal"] = matrix
            continue

        i += 1

    if not results["sets"] and results["final_16x16_staged"] is None and results["final_16x16_ideal"] is None:
        raise ValueError(
            f"No golden sections recognized in file:\n{path}\n"
            "Expected '#golden TC0 ... decoded_real_signed_5_M10', "
            "'#golden TC1 ... decoded_real_signed_5_M10', "
            "'#FINAL_CHAINED_16x16_FROM_DUAL_TC_FXP16', or "
            "'#FINAL_IDEAL_16x16_ONE_SHOT_REFERENCE'."
        )

    return results


# ============================================================
# Comparison helpers
# ============================================================

def compare_matrix(sim_mat, gold_mat, out):
    rows = len(sim_mat)
    cols = len(sim_mat[0]) if rows else 0

    diff_count = 0
    hex_mismatches = 0
    max_abs_diff = 0.0

    write_line(out, "row col | obtained(hex) obtained(val) | golden(hex) golden(val) | abs diff")

    for r in range(rows):
        for c in range(cols):
            sim_hex = sim_mat[r][c].upper()
            gold_hex = gold_mat[r][c].upper()

            sim_val = hex16_to_real(sim_hex)
            gold_val = hex16_to_real(gold_hex)
            diff = abs(sim_val - gold_val)

            if diff > max_abs_diff:
                max_abs_diff = diff

            if sim_hex != gold_hex:
                hex_mismatches += 1
                diff_count += 1
                write_line(
                    out,
                    f"{r:02d} {c:02d} | "
                    f"{sim_hex:>8} {sim_val:>12.8f} | "
                    f"{gold_hex:>8} {gold_val:>12.8f} | "
                    f"{diff:>12.8f}"
                )

    if diff_count == 0:
        write_line(out, "All entries match within tolerance and encoded-word equality.")

    return diff_count, hex_mismatches, max_abs_diff


def compare_sets(sim_data, golden_data, out):
    all_sets = sorted(set(sim_data["sets"].keys()) | set(golden_data["sets"].keys()))
    matrix_names = (
        "STEP0_D00", "STEP0_D10", "STEP1_D01", "STEP1_D11",
        "STEP0_D20", "STEP0_D30", "STEP1_D21", "STEP1_D31",
        "STEP0_D02", "STEP0_D12", "STEP1_D03", "STEP1_D13",
        "STEP0_D22", "STEP0_D32", "STEP1_D23", "STEP1_D33",
    )

    total_diff_count = 0
    total_hex_mismatches = 0
    total_missing_sets = 0
    total_missing_matrices = 0

    for set_id in all_sets:
        write_line(out, f"\n========== SET {set_id} ==========")

        if set_id not in sim_data["sets"]:
            write_line(out, "Missing set in simulator output.")
            total_missing_sets += 1
            continue

        if set_id not in golden_data["sets"]:
            write_line(out, "Missing set in golden file.")
            total_missing_sets += 1
            continue

        for mat_name in matrix_names:
            sim_mat = sim_data["sets"][set_id].get(mat_name)
            gold_mat = golden_data["sets"][set_id].get(mat_name)

            write_line(out, f"\n{mat_name}:")

            if sim_mat is None:
                write_line(out, "Missing in simulator output.")
                total_missing_matrices += 1
                continue

            if gold_mat is None:
                write_line(out, "Missing in golden file.")
                total_missing_matrices += 1
                continue

            local_diff, local_hex, max_abs = compare_matrix(sim_mat, gold_mat, out)
            total_diff_count += local_diff
            total_hex_mismatches += local_hex

            if local_diff != 0:
                write_line(out, f"--> {local_diff} differing entries in {mat_name}")
                write_line(out, f"--> {local_hex} hex mismatches in {mat_name}")
                write_line(out, f"--> max abs diff in {mat_name}: {max_abs:.8f}")

    return total_diff_count, total_hex_mismatches, total_missing_sets, total_missing_matrices


def compare_named_matrix(title, sim_mat, gold_mat, out):
    write_line(out, f"\n========== {title} ==========")
    write_line(out, "FINAL_16x16_RESULT:")

    if sim_mat is None and gold_mat is None:
        write_line(out, "Missing in both files.")
        return 0, 0, 1

    if sim_mat is None:
        write_line(out, "Missing in simulator output.")
        return 0, 0, 1

    if gold_mat is None:
        write_line(out, "Missing in golden file.")
        return 0, 0, 1

    diff_count, hex_mismatches, max_abs = compare_matrix(sim_mat, gold_mat, out)

    if diff_count != 0:
        write_line(out, f"--> {diff_count} differing entries")
        write_line(out, f"--> {hex_mismatches} hex mismatches")
        write_line(out, f"--> max abs diff: {max_abs:.8f}")
    else:
        write_line(out, "Match within encoded-word equality.")

    return diff_count, hex_mismatches, 0


# ============================================================
# Main
# ============================================================

if __name__ == "__main__":
    sim_output_file = (
        r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi"
        r"\doubleParametricTCUsRel0\doubleParametricTCUsRelatedScripts"
        r"\4SetsOfHMMAstep0step1\fixedPoint8related"
        r"\hmma_8instr_dualTC_4octects_tb_output_ctrl_fxp8.txt"
    )

    golden_file = (
        r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi"
        r"\doubleParametricTCUsRel0\doubleParametricTCUsRelatedScripts"
        r"\4SetsOfHMMAstep0step1\fixedPoint8related"
        r"\hmma_8instr_dualTC_4octects_fxp8fxp16_single_experiment_compact.txt"
    )

    report_file = (
        r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi"
        r"\doubleParametricTCUsRel0\doubleParametricTCUsRelatedScripts"
        r"\4SetsOfHMMAstep0step1\fixedPoint8related"
        r"\compare_hmma_8instr_dualTC_4octects_fxp8_results.txt"
    )

    sim_data = parse_sim_output(sim_output_file)
    golden_data = parse_golden_file(golden_file)

    print("Parsed simulator sets:", sorted(sim_data["sets"].keys()))
    print("Parsed golden sets   :", sorted(golden_data["sets"].keys()))
    print("Simulator final 16x16 present     :", sim_data["final_16x16"] is not None)
    print("Golden staged final 16x16 present :", golden_data["final_16x16_staged"] is not None)
    print("Golden ideal final 16x16 present  :", golden_data["final_16x16_ideal"] is not None)

    with open(report_file, "w", encoding="utf-8") as out:
        write_line(out, "HMMA 4-SET STEP0/STEP1 FXP8/FXP16 VALIDATION REPORT (DUAL TC, 4 OCTECTS)")
        write_line(out, f"Simulator output file: {sim_output_file}")
        write_line(out, f"Golden reference file: {golden_file}")
        write_line(out, f"Format: signed_5_M10 on 16 bits")
        write_line(out)

        set_diffs, set_hex_mismatches, missing_sets, missing_mats = compare_sets(
            sim_data, golden_data, out
        )

        staged_diffs, staged_hex, staged_missing = compare_named_matrix(
            "FINAL 16x16 RESULT vs FINAL_CHAINED_16x16_FROM_DUAL_TC_FXP16",
            sim_data["final_16x16"],
            golden_data["final_16x16_staged"],
            out,
        )

        ideal_diffs, ideal_hex, ideal_missing = compare_named_matrix(
            "FINAL 16x16 RESULT vs FINAL_IDEAL_16x16_ONE_SHOT_REFERENCE",
            sim_data["final_16x16"],
            golden_data["final_16x16_ideal"],
            out,
        )

        total_diffs = set_diffs + staged_diffs + ideal_diffs
        total_hex_mismatches = set_hex_mismatches + staged_hex + ideal_hex
        total_missing = missing_sets + missing_mats + staged_missing + ideal_missing

        write_line(out, "\n====================================")
        write_line(out, f"Total differing entries: {total_diffs}")
        write_line(out, f"Total hex mismatches: {total_hex_mismatches}")
        write_line(out, f"Total missing items: {total_missing}")

    print(f"\nReport written to: {report_file}")