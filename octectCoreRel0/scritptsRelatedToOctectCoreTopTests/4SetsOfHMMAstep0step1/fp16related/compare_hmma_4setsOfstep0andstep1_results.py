import re
import struct
from pathlib import Path


# ============================================================
# FP16 helpers
# ============================================================

def hex16_to_float(hex_str: str) -> float:
    bits = int(hex_str, 16)
    return struct.unpack(">e", bits.to_bytes(2, byteorder="big"))[0]


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
# Parse testbench output
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

        if line.upper() in ("#STEP0_D00", "#STEP0_D10", "#STEP1_D01", "#STEP1_D11"):
            if current_set is None:
                raise ValueError(f"Found {line} before any #SET header in simulator output.")
            mat_name = line[1:].upper()
            matrix, i = read_matrix(lines, i, 4)
            results["sets"][current_set][mat_name] = matrix
            continue

        if line.upper() == "#FINAL_8X8_QUADRANT":
            matrix, i = read_matrix(lines, i, 8)
            results["final_8x8"] = matrix
            continue

        i += 1

    if not results["sets"] and results["final_8x8"] is None:
        raise ValueError(
            f"No simulator sections recognized in file:\n{path}\n"
            "Expected markers like '#SET 0 results' or '#FINAL_8x8_QUADRANT'."
        )

    return results


# ============================================================
# Parse golden/reference file
# ============================================================

def parse_golden_file(path: str):
    lines = Path(path).read_text(encoding="utf-8").splitlines()

    results = {
        "sets": {},
        "final_blocks": {},
        "final_8x8_staged": None,
        "final_8x8_ideal": None,
    }

    i = 0

    while i < len(lines):
        line = lines[i].strip()

        # Per-set golden matrices
        m = re.match(
            r"#golden\s+(STEP0_D00|STEP0_D10|STEP1_D01|STEP1_D11)_set(\d+)\s+encoded",
            line,
            re.IGNORECASE,
        )
        if m:
            mat_name = m.group(1).upper()
            set_id = int(m.group(2))
            if set_id not in results["sets"]:
                results["sets"][set_id] = {}
            matrix, i = read_matrix(lines, i, 4)
            results["sets"][set_id][mat_name] = matrix
            continue

        # Final staged 4x4 blocks
        m = re.match(r"#(D00_final|D01_final|D10_final|D11_final)\s+encoded", line, re.IGNORECASE)
        if m:
            block_name = m.group(1).upper()
            matrix, i = read_matrix(lines, i, 4)
            results["final_blocks"][block_name] = matrix
            continue

        # Final ideal 8x8 one-shot reference
        if line.upper() == "#D_EXPECTED_TOP_LEFT_8X8 ENCODED":
            matrix, i = read_matrix(lines, i, 8)
            results["final_8x8_ideal"] = matrix
            continue

        i += 1

    # Assemble staged final 8x8 from D00/D01/D10/D11
    needed = ("D00_FINAL", "D01_FINAL", "D10_FINAL", "D11_FINAL")
    if all(k in results["final_blocks"] for k in needed):
        d00 = results["final_blocks"]["D00_FINAL"]
        d01 = results["final_blocks"]["D01_FINAL"]
        d10 = results["final_blocks"]["D10_FINAL"]
        d11 = results["final_blocks"]["D11_FINAL"]

        final_8x8 = []
        for r in range(4):
            final_8x8.append(d00[r] + d01[r])
        for r in range(4):
            final_8x8.append(d10[r] + d11[r])

        results["final_8x8_staged"] = final_8x8

    if not results["sets"] and results["final_8x8_staged"] is None and results["final_8x8_ideal"] is None:
        raise ValueError(
            f"No golden sections recognized in file:\n{path}\n"
            "Expected markers like '#golden STEP0_D00_set0 encoded', "
            "'#D00_final encoded', or '#D_expected_top_left_8x8 encoded'."
        )

    return results


# ============================================================
# Comparison
# ============================================================

def compare_matrix(sim_mat, gold_mat, out, tolerance=0.0):
    rows = len(sim_mat)
    cols = len(sim_mat[0]) if rows else 0

    diff_count = 0
    max_abs_diff = 0.0

    write_line(out, "row col | obtained(hex) obtained(val) | golden(hex) golden(val) | abs diff")

    for r in range(rows):
        for c in range(cols):
            sim_hex = sim_mat[r][c].upper()
            gold_hex = gold_mat[r][c].upper()

            sim_val = hex16_to_float(sim_hex)
            gold_val = hex16_to_float(gold_hex)
            diff = abs(sim_val - gold_val)

            if diff > max_abs_diff:
                max_abs_diff = diff

            if diff > tolerance:
                diff_count += 1
                write_line(
                    out,
                    f"{r:>3} {c:>3} | "
                    f"{sim_hex:>8} {sim_val:>12.6f} | "
                    f"{gold_hex:>8} {gold_val:>12.6f} | "
                    f"{diff:>10.6f}"
                )

    if diff_count == 0:
        write_line(out, "All entries match within tolerance.")

    return diff_count, max_abs_diff


def compare_sets(sim_data, golden_data, out, tolerance=0.0):
    all_sets = sorted(set(sim_data["sets"].keys()) | set(golden_data["sets"].keys()))
    matrix_names = ("STEP0_D00", "STEP0_D10", "STEP1_D01", "STEP1_D11")

    total_diff_count = 0
    total_missing_sets = 0
    total_missing_matrices = 0

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
            local_diff, max_abs = compare_matrix(sim_mat, gold_mat, out, tolerance=tolerance)
            total_diff_count += local_diff

            if local_diff != 0:
                write_line(out, f"--> {local_diff} differing entries in {mat_name}")
                write_line(out, f"--> max abs diff in {mat_name}: {max_abs:.6f}")

    return total_diff_count, total_missing_sets, total_missing_matrices


def compare_named_matrix(title, sim_mat, gold_mat, out, tolerance=0.0):
    write_line(out, f"\n========== {title} ==========")

    if sim_mat is None and gold_mat is None:
        write_line(out, "Missing in both files.")
        return 0, 1

    if sim_mat is None:
        write_line(out, "Missing in simulator output.")
        return 0, 1

    if gold_mat is None:
        write_line(out, "Missing in golden file.")
        return 0, 1

    diff_count, max_abs = compare_matrix(sim_mat, gold_mat, out, tolerance=tolerance)

    if diff_count != 0:
        write_line(out, f"--> {diff_count} differing entries")
        write_line(out, f"--> max abs diff: {max_abs:.6f}")
    else:
        write_line(out, "Match within tolerance.")

    return diff_count, 0


# ============================================================
# Main
# ============================================================

if __name__ == "__main__":
    sim_output_file = r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\octectCoreRel0\scritptsRelatedToOctectCoreTopTests\4SetsOfHMMAstep0step1\fp16related\hmma_8instr_tb_output_ctrl_fp16.txt"
    golden_file = r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\octectCoreRel0\scritptsRelatedToOctectCoreTopTests\4SetsOfHMMAstep0step1\fp16related\hmma_8instr_fp16_single_experiment.txt"
    report_file = r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\octectCoreRel0\scritptsRelatedToOctectCoreTopTests\4SetsOfHMMAstep0step1\fp16related\hmma_8instr_fp16_validation_report.txt"

    tolerance = 0.0

    sim_data = parse_sim_output(sim_output_file)
    golden_data = parse_golden_file(golden_file)

    # Debug prints so you immediately see whether parsing worked
    print("Parsed simulator sets:", sorted(sim_data["sets"].keys()))
    print("Parsed golden sets   :", sorted(golden_data["sets"].keys()))
    print("Simulator final 8x8 present      :", sim_data["final_8x8"] is not None)
    print("Golden staged final 8x8 present  :", golden_data["final_8x8_staged"] is not None)
    print("Golden ideal final 8x8 present   :", golden_data["final_8x8_ideal"] is not None)

    with open(report_file, "w", encoding="utf-8") as out:
        write_line(out, "HMMA 4-SET STEP0/STEP1 FP16 VALIDATION REPORT")
        write_line(out, f"Simulator output file: {sim_output_file}")
        write_line(out, f"Golden reference file: {golden_file}")
        write_line(out, f"Tolerance: {tolerance}")
        write_line(out)

        set_diffs, missing_sets, missing_mats = compare_sets(
            sim_data, golden_data, out, tolerance=tolerance
        )

        staged_diffs, staged_missing = compare_named_matrix(
            "FINAL 8x8 QUADRANT vs FINAL_CHAINED_8x8_FROM_STAGED_FP16",
            sim_data["final_8x8"],
            golden_data["final_8x8_staged"],
            out,
            tolerance=tolerance,
        )

        ideal_diffs, ideal_missing = compare_named_matrix(
            "FINAL 8x8 QUADRANT vs FINAL_IDEAL_8x8_ONE_SHOT_REFERENCE",
            sim_data["final_8x8"],
            golden_data["final_8x8_ideal"],
            out,
            tolerance=tolerance,
        )

        total_diffs = set_diffs + staged_diffs + ideal_diffs
        total_missing = missing_sets + missing_mats + staged_missing + ideal_missing

        write_line(out, "\n====================================")
        write_line(out, f"Total differing entries: {total_diffs}")
        write_line(out, f"Total missing items: {total_missing}")

    print(f"\nReport written to: {report_file}")