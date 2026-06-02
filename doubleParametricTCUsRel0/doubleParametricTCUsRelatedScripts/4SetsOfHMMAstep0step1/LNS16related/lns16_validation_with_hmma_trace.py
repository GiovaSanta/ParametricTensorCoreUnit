import argparse
import math
import re
from dataclasses import dataclass, field
from pathlib import Path

# ============================================================
# LNS16 4_9 validation helper for HMMA dual-TC output
# ============================================================
# Encoding used by the current LNS16 DPU:
#   0x0000     = zero
#   bits 15:14 = "01" normal finite
#   bit  13    = sign
#   bits 12:0  = signed log2 field
#   wF         = 9
#
# real_value = (-1)^sign * 2^(signed_log / 512)
# ============================================================

WF = 9
SCALE = 1 << WF
LNS_MIN_LOG = -4096
LNS_MAX_LOG = 4095
LNS_MIN_MAG = 2.0 ** (LNS_MIN_LOG / SCALE)

VALID_NAMES = (
    "STEP0_D00", "STEP0_D10", "STEP1_D01", "STEP1_D11",
    "STEP0_D20", "STEP0_D30", "STEP1_D21", "STEP1_D31",
    "STEP0_D02", "STEP0_D12", "STEP1_D03", "STEP1_D13",
    "STEP0_D22", "STEP0_D32", "STEP1_D23", "STEP1_D33",
)

TC1_REMAP = {
    "STEP0_D00": "STEP0_D02",
    "STEP0_D10": "STEP0_D12",
    "STEP1_D01": "STEP1_D03",
    "STEP1_D11": "STEP1_D13",
    "STEP0_D20": "STEP0_D22",
    "STEP0_D30": "STEP0_D32",
    "STEP1_D21": "STEP1_D23",
    "STEP1_D31": "STEP1_D33",
}


@dataclass
class LNSDecoded:
    hex_str: str
    bits: int
    status: int
    sign_bit: int
    log_int: int
    value: float
    is_zero: bool
    is_normal: bool


@dataclass
class MismatchRecord:
    row: int
    col: int
    sim_hex: str
    gold_hex: str
    sim_value: float
    gold_value: float
    abs_diff: float
    rel_diff: float
    log_diff: int
    reason: str
    scope: str = ""
    set_id: int | None = None
    mat_name: str | None = None


@dataclass
class MatrixCompareStats:
    diff_count: int = 0
    sign_mismatch_count: int = 0
    zero_mismatch_count: int = 0
    non_normal_count: int = 0
    max_abs_diff: float = 0.0
    max_rel_diff: float = 0.0
    max_log_lsb_diff: int = 0
    mismatches: list[MismatchRecord] = field(default_factory=list)


def signed13_from_bits(bits: int) -> int:
    v = bits & 0x1FFF
    if v & 0x1000:
        v -= 0x2000
    return v


def signed13_to_bits(x: int) -> int:
    if x < 0:
        x = (1 << 13) + x
    return x & 0x1FFF


def lns16_bits_to_hex(bits: int) -> str:
    return f"{int(bits) & 0xFFFF:04X}"


def real_to_lns16_bits(value: float) -> int:
    """Encode a Python real value into this LNS16 4_9 format."""
    value = float(value)

    if not math.isfinite(value):
        raise ValueError(f"Cannot encode non-finite value: {value}")

    if abs(value) < LNS_MIN_MAG:
        return 0x0000

    sign = 1 if value < 0.0 else 0
    log_fixed = int(round(math.log2(abs(value)) * SCALE))

    if not (LNS_MIN_LOG <= log_fixed <= LNS_MAX_LOG):
        raise ValueError(
            f"Cannot encode value outside LNS16 4_9 range: "
            f"value={value}, log_fixed={log_fixed}"
        )

    return 0x4000 | (sign << 13) | signed13_to_bits(log_fixed)


def real_to_lns16_hex(value: float) -> str:
    return lns16_bits_to_hex(real_to_lns16_bits(value))


def lns_mul_hex(a_hex: str, b_hex: str) -> str:
    """Exact LNS multiply for normal finite values: sign XOR, log add."""
    a = hex16_to_lns(a_hex)
    b = hex16_to_lns(b_hex)

    if a.is_zero or b.is_zero:
        return "0000"
    if not a.is_normal or not b.is_normal:
        return "NNNN"

    sign = a.sign_bit ^ b.sign_bit
    log_sum = a.log_int + b.log_int

    if not (LNS_MIN_LOG <= log_sum <= LNS_MAX_LOG):
        return "OVFL"

    return lns16_bits_to_hex(0x4000 | (sign << 13) | signed13_to_bits(log_sum))


def lns_add_quantized_hex(*hex_values: str) -> str:
    """Add decoded real values and quantize the real-domain result back to LNS16."""
    total = 0.0
    for h in hex_values:
        if h in (None, "", "NNNN", "OVFL"):
            return "NNNN"
        d = hex16_to_lns(h)
        if not math.isfinite(d.value):
            return "NNNN"
        total += d.value
    return real_to_lns16_hex(total)


def fmt_lns(h: str) -> str:
    if h in (None, "", "NNNN", "OVFL"):
        return f"{str(h):>4} {'nan':>14} {'':>6} {'':>4}"
    d = hex16_to_lns(h)
    return f"{d.hex_str:>4} {d.value:>+14.9f} log={d.log_int:>5} s={d.sign_bit}"


def hex16_to_lns(hex_str: str) -> LNSDecoded:
    h = hex_str.strip().upper()
    bits = int(h, 16) & 0xFFFF

    if bits == 0:
        return LNSDecoded(h, bits, 0, 0, 0, 0.0, True, False)

    status = (bits >> 14) & 0x3
    sign_bit = (bits >> 13) & 0x1
    log_int = signed13_from_bits(bits)

    if status == 0b01:
        mag = 2.0 ** (log_int / SCALE)
        value = -mag if sign_bit else mag
        return LNSDecoded(h, bits, status, sign_bit, log_int, value, False, True)

    # Non-normal encodings are not expected in this LNS16 flow.
    return LNSDecoded(h, bits, status, sign_bit, log_int, float("nan"), False, False)


def write_line(out, text=""):
    print(text)
    out.write(text + "\n")


def normalize_marker(line: str) -> str:
    return re.sub(r"\s+", " ", line.strip().upper())


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
# Parsers
# ============================================================

def parse_sim_output(path: str):
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    results = {"sets": {}, "final_16x16": None}

    i = 0
    current_set = None

    while i < len(lines):
        line_norm = normalize_marker(lines[i])

        m = re.match(r"#SET\s+(\d+)\s+RESULTS", line_norm, re.IGNORECASE)
        if m:
            current_set = int(m.group(1))
            results["sets"][current_set] = {}
            i += 1
            continue

        if line_norm.startswith("#") and line_norm[1:] in VALID_NAMES:
            if current_set is None:
                raise ValueError(f"Found {line_norm} before any #SET header in simulator output.")
            mat_name = line_norm[1:]
            matrix, i = read_matrix(lines, i, 4)
            results["sets"][current_set][mat_name] = matrix
            continue

        if line_norm == "#FINAL_16X16_RESULT":
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


def parse_golden_file(path: str):
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    results = {
        "sets": {},
        "final_16x16_staged": None,
        "final_16x16_ideal": None,
        "full_A": None,
        "full_B": None,
        "full_C": None,
    }

    i = 0

    while i < len(lines):
        line_norm = normalize_marker(lines[i])

        # Example:
        # #golden TC0 STEP0_D00_set0 encoded
        # #golden TC1 STEP1_D31_set3 encoded
        m = re.match(
            r"#GOLDEN\s+TC([01])\s+"
            r"(STEP0_D00|STEP0_D10|STEP1_D01|STEP1_D11|STEP0_D20|STEP0_D30|STEP1_D21|STEP1_D31)"
            r"_SET(\d+)\s+ENCODED",
            line_norm,
            re.IGNORECASE,
        )
        if m:
            tc_id = int(m.group(1))
            local_name = m.group(2).upper()
            set_id = int(m.group(3))

            global_name = local_name if tc_id == 0 else TC1_REMAP[local_name]
            results["sets"].setdefault(set_id, {})

            matrix, i = read_matrix(lines, i, 4)
            results["sets"][set_id][global_name] = matrix
            continue

        # Full input matrices written by the experiment generator.
        if line_norm == "#FULL_A_16X16 ENCODED":
            matrix, i = read_matrix(lines, i, 16)
            results["full_A"] = matrix
            continue

        if line_norm == "#FULL_B_16X16 ENCODED":
            matrix, i = read_matrix(lines, i, 16)
            results["full_B"] = matrix
            continue

        if line_norm == "#FULL_C_16X16 ENCODED":
            matrix, i = read_matrix(lines, i, 16)
            results["full_C"] = matrix
            continue

        # Flexible final matrix markers.
        if (
            ("D_FULL_FROM_2TC" in line_norm or "FINAL_CHAINED" in line_norm or "FROM_DUAL_TC" in line_norm)
            and "ENCODED" in line_norm
        ):
            matrix, i = read_matrix(lines, i, 16)
            results["final_16x16_staged"] = matrix
            continue

        if (
            ("D_FULL_ONE_SHOT" in line_norm or "ONE_SHOT_REFERENCE" in line_norm or "FULL_D_16X16_ONE_SHOT_REFERENCE" in line_norm)
            and "ENCODED" in line_norm
        ):
            matrix, i = read_matrix(lines, i, 16)
            results["final_16x16_ideal"] = matrix
            continue

        i += 1

    if not results["sets"] and results["final_16x16_staged"] is None and results["final_16x16_ideal"] is None:
        raise ValueError(
            f"No golden sections recognized in file:\n{path}\n"
            "Expected markers like '#golden TC0 STEP0_D00_set0 encoded', "
            "'#D_full_from_2tc encoded', or '#D_full_one_shot encoded'."
        )

    return results


# ============================================================
# Comparison logic
# ============================================================

def relative_diff(sim_val: float, gold_val: float) -> float:
    denom = max(abs(gold_val), 1e-30)
    return abs(sim_val - gold_val) / denom


def is_near_zero(x: LNSDecoded, near_zero_abs_tol: float) -> bool:
    if x.is_zero:
        return True
    if not math.isfinite(x.value):
        return False
    return abs(x.value) <= near_zero_abs_tol


def entry_passes(sim: LNSDecoded, gold: LNSDecoded, log_lsb_tolerance: int, abs_tolerance: float, near_zero_abs_tolerance: float):
    # If both are zero/near-zero, accept.
    if is_near_zero(sim, near_zero_abs_tolerance) and is_near_zero(gold, near_zero_abs_tolerance):
        return True, "near-zero accepted"

    if not sim.is_zero and not sim.is_normal:
        return False, "sim non-normal"
    if not gold.is_zero and not gold.is_normal:
        return False, "gold non-normal"

    if is_near_zero(sim, near_zero_abs_tolerance) != is_near_zero(gold, near_zero_abs_tolerance):
        return False, "zero/near-zero mismatch"

    if sim.sign_bit != gold.sign_bit:
        return False, "sign mismatch"

    abs_diff = abs(sim.value - gold.value)
    if abs_diff <= abs_tolerance:
        return True, "abs tolerance"

    log_diff = abs(sim.log_int - gold.log_int)
    if log_diff <= log_lsb_tolerance:
        return True, "log tolerance"

    return False, "log/abs tolerance failed"


def add_stats(dst: MatrixCompareStats, src: MatrixCompareStats):
    dst.diff_count += src.diff_count
    dst.sign_mismatch_count += src.sign_mismatch_count
    dst.zero_mismatch_count += src.zero_mismatch_count
    dst.non_normal_count += src.non_normal_count
    dst.max_abs_diff = max(dst.max_abs_diff, src.max_abs_diff)
    dst.max_rel_diff = max(dst.max_rel_diff, src.max_rel_diff)
    dst.max_log_lsb_diff = max(dst.max_log_lsb_diff, src.max_log_lsb_diff)
    dst.mismatches.extend(src.mismatches)


def compare_matrix(
    sim_mat,
    gold_mat,
    out,
    log_lsb_tolerance=128,
    abs_tolerance=0.50,
    near_zero_abs_tolerance=0.25,
    scope="",
    set_id=None,
    mat_name=None,
):
    rows = len(sim_mat)
    cols = len(sim_mat[0]) if rows else 0
    stats = MatrixCompareStats()

    write_line(out, "row col | obtained(hex) obtained(val) log sign | golden(hex) golden(val) log sign | abs diff rel diff log diff | reason")

    for r in range(rows):
        for c in range(cols):
            sim = hex16_to_lns(sim_mat[r][c])
            gold = hex16_to_lns(gold_mat[r][c])

            if (not sim.is_zero and not sim.is_normal) or (not gold.is_zero and not gold.is_normal):
                stats.non_normal_count += 1

            if math.isfinite(sim.value) and math.isfinite(gold.value):
                abs_diff = abs(sim.value - gold.value)
                rel_diff = relative_diff(sim.value, gold.value)
            else:
                abs_diff = float("inf")
                rel_diff = float("inf")

            stats.max_abs_diff = max(stats.max_abs_diff, abs_diff if math.isfinite(abs_diff) else 0.0)
            stats.max_rel_diff = max(stats.max_rel_diff, rel_diff if math.isfinite(rel_diff) else 0.0)
            log_diff = abs(sim.log_int - gold.log_int)
            stats.max_log_lsb_diff = max(stats.max_log_lsb_diff, log_diff)

            passed, reason = entry_passes(
                sim,
                gold,
                log_lsb_tolerance=log_lsb_tolerance,
                abs_tolerance=abs_tolerance,
                near_zero_abs_tolerance=near_zero_abs_tolerance,
            )

            if not passed:
                stats.diff_count += 1

                if sim.sign_bit != gold.sign_bit and not is_near_zero(sim, near_zero_abs_tolerance) and not is_near_zero(gold, near_zero_abs_tolerance):
                    stats.sign_mismatch_count += 1

                if is_near_zero(sim, near_zero_abs_tolerance) != is_near_zero(gold, near_zero_abs_tolerance):
                    stats.zero_mismatch_count += 1

                stats.mismatches.append(
                    MismatchRecord(
                        row=r,
                        col=c,
                        sim_hex=sim.hex_str,
                        gold_hex=gold.hex_str,
                        sim_value=sim.value,
                        gold_value=gold.value,
                        abs_diff=abs_diff,
                        rel_diff=rel_diff,
                        log_diff=log_diff,
                        reason=reason,
                        scope=scope,
                        set_id=set_id,
                        mat_name=mat_name,
                    )
                )

                write_line(
                    out,
                    f"{r:>3} {c:>3} | "
                    f"{sim.hex_str:>8} {sim.value:>14.6f} {sim.log_int:>5} {sim.sign_bit:>1} | "
                    f"{gold.hex_str:>8} {gold.value:>14.6f} {gold.log_int:>5} {gold.sign_bit:>1} | "
                    f"{abs_diff:>10.6f} {rel_diff:>10.6f} {log_diff:>8} | {reason}"
                )

    if stats.diff_count == 0:
        write_line(out, "All entries match within tolerance.")

    return stats


def compare_sets(sim_data, golden_data, out, log_lsb_tolerance=128, abs_tolerance=0.50, near_zero_abs_tolerance=0.25):
    all_sets = sorted(set(sim_data["sets"].keys()) | set(golden_data["sets"].keys()))
    total_stats = MatrixCompareStats()
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

        for mat_name in VALID_NAMES:
            sim_mat = sim_data["sets"][set_id].get(mat_name)
            gold_mat = golden_data["sets"][set_id].get(mat_name)

            if sim_mat is None or gold_mat is None:
                write_line(out, f"\n{mat_name}: missing in one of the files")
                total_missing_matrices += 1
                continue

            write_line(out, f"\n{mat_name}:")
            local_stats = compare_matrix(
                sim_mat,
                gold_mat,
                out,
                log_lsb_tolerance=log_lsb_tolerance,
                abs_tolerance=abs_tolerance,
                near_zero_abs_tolerance=near_zero_abs_tolerance,
                scope=f"SET {set_id} {mat_name}",
                set_id=set_id,
                mat_name=mat_name,
            )
            add_stats(total_stats, local_stats)

            if local_stats.diff_count != 0:
                write_line(out, f"--> {local_stats.diff_count} differing entries in {mat_name}")
                write_line(out, f"--> sign mismatches in {mat_name}: {local_stats.sign_mismatch_count}")
                write_line(out, f"--> zero/near-zero mismatches in {mat_name}: {local_stats.zero_mismatch_count}")
                write_line(out, f"--> max abs diff in {mat_name}: {local_stats.max_abs_diff:.6f}")
                write_line(out, f"--> max rel diff in {mat_name}: {local_stats.max_rel_diff:.6f}")
                write_line(out, f"--> max log LSB diff in {mat_name}: {local_stats.max_log_lsb_diff}")

    return total_stats, total_missing_sets, total_missing_matrices


def compare_named_matrix(title, sim_mat, gold_mat, out, log_lsb_tolerance=128, abs_tolerance=0.50, near_zero_abs_tolerance=0.25):
    write_line(out, f"\n========== {title} ==========")

    if sim_mat is None and gold_mat is None:
        write_line(out, "Missing in both files.")
        return MatrixCompareStats(), 1
    if sim_mat is None:
        write_line(out, "Missing in simulator output.")
        return MatrixCompareStats(), 1
    if gold_mat is None:
        write_line(out, "Missing in golden file.")
        return MatrixCompareStats(), 1

    stats = compare_matrix(
        sim_mat,
        gold_mat,
        out,
        log_lsb_tolerance=log_lsb_tolerance,
        abs_tolerance=abs_tolerance,
        near_zero_abs_tolerance=near_zero_abs_tolerance,
        scope=title,
    )

    if stats.diff_count != 0:
        write_line(out, f"--> {stats.diff_count} differing entries")
        write_line(out, f"--> sign mismatches: {stats.sign_mismatch_count}")
        write_line(out, f"--> zero/near-zero mismatches: {stats.zero_mismatch_count}")
        write_line(out, f"--> max abs diff: {stats.max_abs_diff:.6f}")
        write_line(out, f"--> max rel diff: {stats.max_rel_diff:.6f}")
        write_line(out, f"--> max log LSB diff: {stats.max_log_lsb_diff}")
    else:
        write_line(out, "Match within tolerance.")

    return stats, 0



# ============================================================
# HMMA element tracing
# ============================================================

MATRIX_BLOCK_MAP = {
    "STEP0_D00": (0, 0), "STEP1_D01": (0, 1),
    "STEP0_D10": (1, 0), "STEP1_D11": (1, 1),
    "STEP0_D20": (2, 0), "STEP1_D21": (2, 1),
    "STEP0_D30": (3, 0), "STEP1_D31": (3, 1),
    "STEP0_D02": (0, 2), "STEP1_D03": (0, 3),
    "STEP0_D12": (1, 2), "STEP1_D13": (1, 3),
    "STEP0_D22": (2, 2), "STEP1_D23": (2, 3),
    "STEP0_D32": (3, 2), "STEP1_D33": (3, 3),
}

BLOCK_TO_MATRIX = {v: k for k, v in MATRIX_BLOCK_MAP.items()}


def map_full_coord_to_hmma(row0: int, col0: int):
    """Map zero-based full 16x16 coordinate to TC/block/local indices."""
    if not (0 <= row0 < 16 and 0 <= col0 < 16):
        raise ValueError(f"Full matrix coordinate out of range: row0={row0}, col0={col0}")

    block_row = row0 // 4
    block_col = col0 // 4
    local_r = row0 % 4
    local_c = col0 % 4

    mat_name = BLOCK_TO_MATRIX[(block_row, block_col)]
    tc_id = 0 if block_col < 2 else 1
    local_tc_col = block_col if tc_id == 0 else block_col - 2

    return {
        "tc_id": tc_id,
        "block_row": block_row,
        "block_col": block_col,
        "local_tc_col": local_tc_col,
        "local_r": local_r,
        "local_c": local_c,
        "mat_name": mat_name,
    }


def full_coord_from_set_matrix(mat_name: str, local_r: int, local_c: int):
    block = MATRIX_BLOCK_MAP.get(mat_name)
    if block is None:
        return None
    block_row, block_col = block
    return block_row * 4 + local_r, block_col * 4 + local_c


def safe_matrix_entry(mat, r: int, c: int):
    try:
        return mat[r][c]
    except Exception:
        return None


def quantized_sum_hex(hex_values):
    return lns_add_quantized_hex(*hex_values)


def trace_full_hmma_element(
    row0: int,
    col0: int,
    golden_data,
    sim_data=None,
    out=None,
    up_to_set: int = 3,
    source_note: str = "",
):
    """
    Dump the exact A-row/B-column/C-chain terms used for one full 16x16 output element.
    row0/col0 are zero-based full-matrix coordinates.
    """
    if out is None:
        raise ValueError("trace_full_hmma_element requires an output file handle")

    A = golden_data.get("full_A")
    B = golden_data.get("full_B")
    C = golden_data.get("full_C")

    if A is None or B is None or C is None:
        write_line(out, "\n========== HMMA TRACE SKIPPED ==========")
        write_line(out, "The golden file did not include FULL_A/FULL_B/FULL_C encoded matrices.")
        write_line(out, "Regenerate the human-readable experiment file with FULL_A_16x16, FULL_B_16x16, FULL_C_16x16 encoded sections.")
        return

    info = map_full_coord_to_hmma(row0, col0)
    mat_name = info["mat_name"]
    local_r = info["local_r"]
    local_c = info["local_c"]

    up_to_set = max(0, min(3, int(up_to_set)))

    write_line(out, "\n============================================================")
    write_line(out, "HMMA ELEMENT TRACE")
    if source_note:
        write_line(out, f"Source mismatch: {source_note}")
    write_line(out, f"Full coordinate: row {row0 + 1}, col {col0 + 1}  (zero-based {row0}, {col0})")
    write_line(out, f"Maps to: TC{info['tc_id']} {mat_name}, local row {local_r + 1}, local col {local_c + 1}")
    write_line(out, "Each SET contributes four products A[row,k] * B[k,col], then chains previous D as C for the next SET.")
    write_line(out, "============================================================")

    final_sim = safe_matrix_entry(sim_data.get("final_16x16"), row0, col0) if sim_data else None
    final_staged = safe_matrix_entry(golden_data.get("final_16x16_staged"), row0, col0)
    final_ideal = safe_matrix_entry(golden_data.get("final_16x16_ideal"), row0, col0)

    if final_sim is not None or final_staged is not None or final_ideal is not None:
        write_line(out, "Final full-matrix values:")
        if final_sim is not None:
            write_line(out, f"  simulator FINAL_16x16_RESULT : {fmt_lns(final_sim)}")
        if final_staged is not None:
            write_line(out, f"  golden chained/from-2TC     : {fmt_lns(final_staged)}")
        if final_ideal is not None:
            write_line(out, f"  golden one-shot A@B+C      : {fmt_lns(final_ideal)}")

    for s in range(up_to_set + 1):
        write_line(out, f"\n---- SET {s} contribution for full(row {row0 + 1}, col {col0 + 1}) ----")

        if s == 0:
            cin_hex = C[row0][col0]
            cin_label = f"original C[{row0 + 1},{col0 + 1}]"
        else:
            prev_mat = golden_data["sets"].get(s - 1, {}).get(mat_name)
            cin_hex = safe_matrix_entry(prev_mat, local_r, local_c)
            cin_label = f"previous golden {mat_name}_set{s - 1}[{local_r + 1},{local_c + 1}]"

        if cin_hex is None:
            write_line(out, f"  C input missing for SET {s}; cannot complete this trace stage.")
            continue

        write_line(out, f"C input ({cin_label}): {fmt_lns(cin_hex)}")

        products = []
        product_inputs = []
        for k_local in range(4):
            k_global = s * 4 + k_local
            a_hex = A[row0][k_global]
            b_hex = B[k_global][col0]
            p_hex = lns_mul_hex(a_hex, b_hex)
            products.append(p_hex)
            product_inputs.append((k_global, a_hex, b_hex, p_hex))

            write_line(
                out,
                f"p{k_local}: A[{row0 + 1},{k_global + 1}] {fmt_lns(a_hex)}  *  "
                f"B[{k_global + 1},{col0 + 1}] {fmt_lns(b_hex)}  =>  {fmt_lns(p_hex)}"
            )

        # These are diagnostic tree reconstructions. The real generator golden uses real-domain A@B+C
        # followed by one LNS quantization for each staged output, while the hardware may have an adder tree.
        p01_hex = quantized_sum_hex([products[0], products[1]])
        p23_hex = quantized_sum_hex([products[2], products[3]])
        tree_prod_hex = quantized_sum_hex([p01_hex, p23_hex])
        tree_out_hex = quantized_sum_hex([tree_prod_hex, cin_hex])
        one_shot_stage_hex = quantized_sum_hex([cin_hex] + products)

        write_line(out, "")
        write_line(out, f"pair p0+p1                 : {fmt_lns(p01_hex)}")
        write_line(out, f"pair p2+p3                 : {fmt_lns(p23_hex)}")
        write_line(out, f"tree product sum           : {fmt_lns(tree_prod_hex)}")
        write_line(out, f"tree estimate + C          : {fmt_lns(tree_out_hex)}")
        write_line(out, f"one-shot stage quantized   : {fmt_lns(one_shot_stage_hex)}")

        gold_stage = safe_matrix_entry(golden_data["sets"].get(s, {}).get(mat_name), local_r, local_c)
        sim_stage = safe_matrix_entry(sim_data["sets"].get(s, {}).get(mat_name), local_r, local_c) if sim_data else None

        if gold_stage is not None:
            write_line(out, f"golden staged {mat_name}_set{s} : {fmt_lns(gold_stage)}")
        if sim_stage is not None:
            write_line(out, f"sim staged {mat_name}_set{s}    : {fmt_lns(sim_stage)}")

        if gold_stage is not None and sim_stage is not None:
            gd = hex16_to_lns(gold_stage)
            sd = hex16_to_lns(sim_stage)
            if math.isfinite(gd.value) and math.isfinite(sd.value):
                write_line(out, f"stage abs diff              : {abs(sd.value - gd.value):.9f}")


def emit_mismatch_traces(
    set_stats: MatrixCompareStats,
    staged_stats: MatrixCompareStats,
    ideal_stats: MatrixCompareStats,
    golden_data,
    sim_data,
    out,
    max_traces: int = 8,
):
    """Trace unique full-matrix coordinates implicated by mismatches."""
    candidates = []

    # Prefer staged SET mismatches first, because they tell where the error first appears.
    for m in set_stats.mismatches:
        if m.mat_name is None or m.set_id is None:
            continue
        full = full_coord_from_set_matrix(m.mat_name, m.row, m.col)
        if full is None:
            continue
        candidates.append((full[0], full[1], int(m.set_id), m))

    # Then final matrix mismatches. These trace all four SETs.
    for m in staged_stats.mismatches + ideal_stats.mismatches:
        candidates.append((m.row, m.col, 3, m))

    if not candidates:
        return

    write_line(out, "\n====================================")
    write_line(out, "AUTOMATIC HMMA INPUT TRACE FOR MISMATCHES")
    write_line(out, "This section expands each failing coordinate into the A/B/C values and products that produced it.")

    seen = set()
    emitted = 0
    for row0, col0, up_to_set, m in candidates:
        key = (row0, col0, up_to_set)
        if key in seen:
            continue
        seen.add(key)

        note = (
            f"{m.scope}; local row={m.row}, col={m.col}; "
            f"sim={m.sim_hex}, gold={m.gold_hex}, reason={m.reason}"
        )
        trace_full_hmma_element(
            row0=row0,
            col0=col0,
            golden_data=golden_data,
            sim_data=sim_data,
            out=out,
            up_to_set=up_to_set,
            source_note=note,
        )

        emitted += 1
        if emitted >= max_traces:
            remaining = len(seen) - emitted
            write_line(out, f"\nTrace limit reached: emitted {emitted} trace(s). Increase --max-traces to see more.")
            break


# ============================================================
# Main
# ============================================================

def default_base_dir() -> Path:
    # Use the folder where this script is located.
    # This avoids hard-coded Windows path problems and works even if the folder moves.
    return Path(__file__).resolve().parent

def main():
    base = default_base_dir()

    parser = argparse.ArgumentParser(description="Validate LNS16 HMMA 4-set dual-TC simulation output against golden/reference file.")
    parser.add_argument("--sim-output", default=str(base / "hmma_8instr_dualTC_4octects_tb_output_ctrl_lns16.txt"), help="Simulator output text file.")
    parser.add_argument("--golden", default=str(base / "hmma_8instr_dualTC_4octects_lns16_single_experiment.txt"), help="Golden/reference human-readable experiment file.")
    parser.add_argument("--report", default=str(base / "hmma_8instr_dualTC_4octects_lns16_validation_report.txt"), help="Output validation report file.")
    parser.add_argument("--log-tol", type=int, default=128, help="Allowed same-sign LNS log-field difference, in LNS LSBs.")
    parser.add_argument("--abs-tol", type=float, default=0.50, help="Allowed real-domain absolute difference.")
    parser.add_argument("--near-zero-tol", type=float, default=0.25, help="Values with abs(value) <= this are treated as near-zero.")
    parser.add_argument("--trace-mismatches", action="store_true", default=True, help="Automatically dump HMMA A/B/C/product traces for mismatches. Default: enabled.")
    parser.add_argument("--no-trace-mismatches", dest="trace_mismatches", action="store_false", help="Disable automatic mismatch traces.")
    parser.add_argument("--max-traces", type=int, default=8, help="Maximum number of automatic mismatch traces to emit.")
    parser.add_argument("--trace", action="append", default=[], metavar="ROW,COL", help="Manually trace a 1-based full 16x16 coordinate, e.g. --trace 4,8. Can be repeated.")

    args = parser.parse_args()

    sim_data = parse_sim_output(args.sim_output)
    golden_data = parse_golden_file(args.golden)

    print("Parsed simulator sets:", sorted(sim_data["sets"].keys()))
    print("Parsed golden sets   :", sorted(golden_data["sets"].keys()))
    print("Simulator final 16x16 present     :", sim_data["final_16x16"] is not None)
    print("Golden staged final 16x16 present :", golden_data["final_16x16_staged"] is not None)
    print("Golden ideal final 16x16 present  :", golden_data["final_16x16_ideal"] is not None)
    print("Golden FULL_A/B/C present         :", all(golden_data.get(k) is not None for k in ("full_A", "full_B", "full_C")))

    with open(args.report, "w", encoding="utf-8") as out:
        write_line(out, "HMMA 4-SET STEP0/STEP1 LNS16 VALIDATION REPORT (DUAL TC, 4 OCTECTS)")
        write_line(out, f"Simulator output file: {args.sim_output}")
        write_line(out, f"Golden reference file: {args.golden}")
        write_line(out, f"LNS log tolerance: {args.log_tol} LSB")
        write_line(out, f"Absolute tolerance: {args.abs_tol}")
        write_line(out, f"Near-zero tolerance: {args.near_zero_tol}")
        write_line(out, f"Automatic mismatch tracing: {args.trace_mismatches}")
        write_line(out, f"Max mismatch traces: {args.max_traces}")
        if args.trace:
            write_line(out, f"Manual traces requested: {', '.join(args.trace)}")
        write_line(out)

        set_stats, missing_sets, missing_mats = compare_sets(
            sim_data,
            golden_data,
            out,
            log_lsb_tolerance=args.log_tol,
            abs_tolerance=args.abs_tol,
            near_zero_abs_tolerance=args.near_zero_tol,
        )

        staged_stats, staged_missing = compare_named_matrix(
            "FINAL 16x16 RESULT vs FINAL_CHAINED_16x16_FROM_DUAL_TC_LNS16",
            sim_data["final_16x16"],
            golden_data["final_16x16_staged"],
            out,
            log_lsb_tolerance=args.log_tol,
            abs_tolerance=args.abs_tol,
            near_zero_abs_tolerance=args.near_zero_tol,
        )

        ideal_stats, ideal_missing = compare_named_matrix(
            "FINAL 16x16 RESULT vs FINAL_IDEAL_16x16_ONE_SHOT_REFERENCE",
            sim_data["final_16x16"],
            golden_data["final_16x16_ideal"],
            out,
            log_lsb_tolerance=args.log_tol,
            abs_tolerance=args.abs_tol,
            near_zero_abs_tolerance=args.near_zero_tol,
        )

        total_stats = MatrixCompareStats()
        add_stats(total_stats, set_stats)
        add_stats(total_stats, staged_stats)
        add_stats(total_stats, ideal_stats)
        total_missing = missing_sets + missing_mats + staged_missing + ideal_missing

        # Manual traces are useful when you already know a suspicious coordinate, e.g. --trace 4,8.
        for trace_spec in args.trace:
            try:
                row_s, col_s = trace_spec.split(",")
                row0 = int(row_s.strip()) - 1
                col0 = int(col_s.strip()) - 1
                trace_full_hmma_element(
                    row0=row0,
                    col0=col0,
                    golden_data=golden_data,
                    sim_data=sim_data,
                    out=out,
                    up_to_set=3,
                    source_note="manual --trace request",
                )
            except Exception as exc:
                write_line(out, f"Could not process --trace {trace_spec!r}: {exc}")

        if args.trace_mismatches:
            emit_mismatch_traces(
                set_stats=set_stats,
                staged_stats=staged_stats,
                ideal_stats=ideal_stats,
                golden_data=golden_data,
                sim_data=sim_data,
                out=out,
                max_traces=args.max_traces,
            )

        write_line(out, "\n====================================")
        write_line(out, f"Total differing entries: {total_stats.diff_count}")
        write_line(out, f"Total sign mismatches: {total_stats.sign_mismatch_count}")
        write_line(out, f"Total zero/near-zero mismatches: {total_stats.zero_mismatch_count}")
        write_line(out, f"Total non-normal decoded entries: {total_stats.non_normal_count}")
        write_line(out, f"Total missing items: {total_missing}")
        write_line(out, f"Global max abs diff: {total_stats.max_abs_diff:.6f}")
        write_line(out, f"Global max rel diff: {total_stats.max_rel_diff:.6f}")
        write_line(out, f"Global max log LSB diff: {total_stats.max_log_lsb_diff}")

    print(f"\nReport written to: {args.report}")


if __name__ == "__main__":
    main()
