import re
import math
from pathlib import Path


# ============================================================
# FP8 E4M3 decode
# ============================================================
FP8_EXP_BITS = 4
FP8_MAN_BITS = 3
FP8_EXP_BIAS = 7


def hex8_to_float(hex_str: str) -> float:
    """
    Convert an 8-bit hex string representing FP8 E4M3
    into a Python float.
    Layout:
      sign[7], exp[6:3], frac[2:0]
    """
    code = int(hex_str, 16) & 0xFF

    sign = -1.0 if (code & 0x80) else 1.0
    exp_field = (code >> 3) & 0xF
    frac_field = code & 0x7

    # zero / subnormal
    if exp_field == 0:
        if frac_field == 0:
            return -0.0 if sign < 0 else 0.0
        mant = frac_field / (2 ** FP8_MAN_BITS)
        return sign * (2 ** (1 - FP8_EXP_BIAS)) * mant

    # inf / nan
    if exp_field == 0xF:
        if frac_field == 0:
            return math.copysign(math.inf, sign)
        return math.nan

    # normal
    mant = 1.0 + frac_field / (2 ** FP8_MAN_BITS)
    exp_unbiased = exp_field - FP8_EXP_BIAS
    return sign * mant * (2 ** exp_unbiased)


# ============================================================
# File parsing
# ============================================================
def parse_sim_output(path: str):
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    results = {}

    i = 0
    current_test = None

    while i < len(lines):
        line = lines[i].strip()

        m = re.match(r"#Test\s+(\d+)\s+HMMAstep0", line, re.IGNORECASE)
        if m:
            current_test = int(m.group(1))
            results[current_test] = {}
            i += 1
            continue

        if line == "#D00" and current_test is not None:
            matrix = []
            for _ in range(4):
                i += 1
                matrix.append([x.upper() for x in lines[i].strip().split()])
            results[current_test]["D00"] = matrix
            i += 1
            continue

        if line == "#D10" and current_test is not None:
            matrix = []
            for _ in range(4):
                i += 1
                matrix.append([x.upper() for x in lines[i].strip().split()])
            results[current_test]["D10"] = matrix
            i += 1
            continue

        i += 1

    return results


def parse_golden_file(path: str):
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    results = {}

    i = 0
    current_test = 0

    while i < len(lines):
        line = lines[i].strip()

        if re.match(r"#.*HMMAstep0 test related values", line, re.IGNORECASE):
            current_test += 1
            results[current_test] = {}
            i += 1
            continue

        if line.lower() == "#golden d00 encoded" and current_test > 0:
            matrix = []
            for _ in range(4):
                i += 1
                matrix.append([x.upper() for x in lines[i].strip().split()])
            results[current_test]["D00"] = matrix
            i += 1
            continue

        if line.lower() in ("#golden encoded d20", "#golden d20 encoded") and current_test > 0:
            matrix = []
            for _ in range(4):
                i += 1
                matrix.append([x.upper() for x in lines[i].strip().split()])
            results[current_test]["D10"] = matrix
            i += 1
            continue

        i += 1

    return results


# ============================================================
# Reporting helpers
# ============================================================
def write_line(out, text=""):
    print(text)
    out.write(text + "\n")


def compare_with_numeric_differences(sim_data, golden_data, out, tolerance=0.0):
    all_tests = sorted(set(sim_data.keys()) | set(golden_data.keys()))

    total_diff_count = 0
    total_missing_tests = 0
    total_missing_matrices = 0

    for test_id in all_tests:
        write_line(out, f"\n========== Test {test_id} ==========")

        if test_id not in sim_data:
            write_line(out, "Missing in simulator output")
            total_missing_tests += 1
            continue

        if test_id not in golden_data:
            write_line(out, "Missing in golden file")
            total_missing_tests += 1
            continue

        for mat_name in ("D00", "D10"):
            sim_mat = sim_data[test_id].get(mat_name)
            gold_mat = golden_data[test_id].get(mat_name)

            if sim_mat is None or gold_mat is None:
                write_line(out, f"{mat_name}: missing in one of the files")
                total_missing_matrices += 1
                continue

            write_line(out, f"\n{mat_name}:")
            write_line(
                out,
                "row col | obtained(hex) obtained(val) | golden(hex) golden(val) | abs diff"
            )

            local_diff_count = 0

            for r in range(4):
                for c in range(4):
                    sim_hex = sim_mat[r][c]
                    gold_hex = gold_mat[r][c]

                    sim_val = hex8_to_float(sim_hex)
                    gold_val = hex8_to_float(gold_hex)
                    diff = abs(sim_val - gold_val)

                    if diff > tolerance:
                        local_diff_count += 1
                        total_diff_count += 1
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
                write_line(out, f"--> {local_diff_count} differing entries in {mat_name}")

    write_line(out, "\n====================================")
    write_line(out, f"Total differing entries: {total_diff_count}")
    write_line(out, f"Total missing tests: {total_missing_tests}")
    write_line(out, f"Total missing matrices: {total_missing_matrices}")


# ============================================================
# Main
# ============================================================
if __name__ == "__main__":
    sim_output_file = r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\octectCoreRel0\scritptsRelatedToOctectCoreTopTests\fp8related\hmma_step0_tb_output_fp8.txt"
    golden_file = r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\octectCoreRel0\scritptsRelatedToOctectCoreTopTests\fp8related\hmma_step0_fp8_tests.txt"
    report_file = r"C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\octectCoreRel0\scritptsRelatedToOctectCoreTopTests\fp8related\hmma_step0_validation_report_fp8.txt"

    sim_data = parse_sim_output(sim_output_file)
    golden_data = parse_golden_file(golden_file)

    with open(report_file, "w", encoding="utf-8") as out:
        write_line(out, "HMMA STEP0 FP8 E4M3 VALIDATION REPORT")
        write_line(out, f"Simulator output file: {sim_output_file}")
        write_line(out, f"Golden reference file: {golden_file}")
        write_line(out, f"Tolerance: 0.0")
        write_line(out)

        compare_with_numeric_differences(sim_data, golden_data, out, tolerance=0.0)

    print(f"\nReport written to: {report_file}")
