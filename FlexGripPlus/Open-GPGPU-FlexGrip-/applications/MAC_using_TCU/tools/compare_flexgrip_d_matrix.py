#!/usr/bin/env python3
"""
Compare a FlexGrip Plus extracted hardware D matrix against a golden encoded D matrix,
including decoded-real error metrics.

Default golden section:
    #FULL_D_16x16_one_shot_reference encoded

Typical usage from:
    FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/

FP16:
    python tools/compare_flexgrip_d_matrix.py \
        --format fp16 \
        --golden-file fp16operands/hmma_8instr_dualTC_4octects_fp16_single_experiment.txt \
        --hw-file fp16operands/hw_D_matrix_extracted.txt \
        --output-report fp16operands/validation_report.txt \
        --output-csv fp16operands/validation_element_errors.csv

LNS16:
    python tools/compare_flexgrip_d_matrix.py \
        --format lns16 \
        --golden-file LNS16operands/hmma_8instr_dualTC_4octects_lns16_single_experiment.txt \
        --hw-file LNS16operands/hw_D_matrix_extracted.txt \
        --output-report LNS16operands/validation_report.txt \
        --output-csv LNS16operands/validation_element_errors.csv


POSIT16:
    python tools/compare_flexgrip_d_matrix.py \
        --format posit16 \
        --golden-file softPosit16_1operands/hmma_8instr_dualTC_4octects_posit16_single_experiment.txt \
        --hw-file softPosit16_1operands/hw_D_matrix_extracted.txt \
        --output-report softPosit16_1operands/validation_report.txt \
        --output-csv softPosit16_1operands/validation_element_errors.csv

This script performs two checks:

1. Encoded-domain exact comparison:
      golden_hex == hardware_hex

2. Decoded-real numerical comparison:
      decode(golden_hex) vs decode(hardware_hex)
      abs_error = abs(hw_real - golden_real)
      rel_error = abs_error / abs(golden_real), except:
          if golden_real == 0 and abs_error == 0 -> rel_error = 0
          if golden_real == 0 and abs_error != 0 -> rel_error = inf

Supported decoded formats:
    fp16
    lns16
    posit16
"""

from __future__ import annotations

import argparse
import csv
import math
import re
from dataclasses import dataclass
from pathlib import Path
from typing import List

import numpy as np


HEX_WORD_RE = re.compile(r"^[0-9A-Fa-f]{1,4}$")

# LNS16 4_9 format used by your generated VHDL modules:
#   bits 15:14 = 01 for normal finite values
#   bit 13     = sign
#   bits 12:0  = signed fixed-point log2(|value|)
#   wF = 9, scale = 2^9 = 512
LNS16_WF = 9
LNS16_SCALE = 1 << LNS16_WF

# Posit16 convention used by the current posit16 generator:
#   posit<16,1>
# If your RTL/generator changes to posit<16,2>, update POSIT16_ES.
POSIT16_NBITS = 16
POSIT16_ES = 1
POSIT16_NAR = 1 << (POSIT16_NBITS - 1)


@dataclass(frozen=True)
class ElementComparison:
    row: int
    col: int
    golden_hex: str
    hardware_hex: str
    golden_real: float
    hardware_real: float
    abs_error: float
    rel_error: float
    encoded_exact_match: bool


def normalize_hex_word(token: str) -> str:
    token = token.strip()

    if not HEX_WORD_RE.fullmatch(token):
        raise ValueError(f"Invalid 16-bit hex token: {token!r}")

    return token.upper().zfill(4)


def find_section_line(lines: List[str], section_label: str) -> int:
    wanted = section_label.strip().lower()

    for idx, line in enumerate(lines):
        if line.strip().lower() == wanted:
            return idx

    raise ValueError(f"Could not find golden section label: {section_label}")


def read_matrix_after_section(
    path: Path,
    section_label: str,
    rows: int,
    cols: int,
) -> List[List[str]]:
    """
    Read rows*cols 16-bit hex tokens immediately after a section label.

    Blank lines are ignored.
    If a new '#' section begins after tokens were collected, parsing stops.
    """
    lines = path.read_text(encoding="utf-8").splitlines()
    start_idx = find_section_line(lines, section_label) + 1

    needed = rows * cols
    tokens: List[str] = []

    for line_no, raw in enumerate(lines[start_idx:], start=start_idx + 1):
        stripped = raw.strip()

        if not stripped:
            continue

        if stripped.startswith("#"):
            if tokens:
                break
            continue

        for token in stripped.split():
            tokens.append(normalize_hex_word(token))

        if len(tokens) >= needed:
            break

    if len(tokens) != needed:
        raise ValueError(
            f"Section {section_label!r} in {path} contains {len(tokens)} words; "
            f"expected {needed} for a {rows}x{cols} matrix."
        )

    return [tokens[r * cols : (r + 1) * cols] for r in range(rows)]


def read_plain_matrix(path: Path, rows: int, cols: int) -> List[List[str]]:
    """
    Read a plain encoded matrix file.

    Expected format:
        16 hex words per row
        16 rows by default

    Blank lines and comment lines starting with '#' are ignored.
    """
    tokens: List[str] = []

    with path.open("r", encoding="utf-8") as f:
        for line_no, raw in enumerate(f, start=1):
            stripped = raw.strip()

            if not stripped or stripped.startswith("#"):
                continue

            for token in stripped.split():
                tokens.append(normalize_hex_word(token))

    needed = rows * cols

    if len(tokens) != needed:
        raise ValueError(
            f"Hardware matrix file {path} contains {len(tokens)} words; "
            f"expected {needed} for a {rows}x{cols} matrix."
        )

    return [tokens[r * cols : (r + 1) * cols] for r in range(rows)]


def decode_fp16(hex_word: str) -> float:
    """
    Decode a 16-bit IEEE FP16 hex word into a Python float.
    """
    bits = np.array([int(hex_word, 16)], dtype=np.uint16)
    value = bits.view(np.float16)[0]
    return float(value)


def bits_to_signed13(x: int) -> int:
    """
    Convert the 13-bit signed field used by LNS16 into a Python signed int.
    """
    v = x & 0x1FFF

    if v & 0x1000:
        v -= 0x2000

    return v


def decode_lns16(hex_word: str) -> float:
    """
    Decode the LNS16 4_9 format used by the VHDL modules.

    Encoding:
        0x0000       -> zero
        bits 15:14   -> 01 for normal finite values
        bit 13       -> sign
        bits 12:0    -> signed fixed-point log2 magnitude, scaled by 2^9

    Real value:
        sign * 2^(log_fixed / 512)
    """
    bits = int(hex_word, 16) & 0xFFFF

    if bits == 0x0000:
        return 0.0

    if (bits >> 14) != 0b01:
        raise ValueError(f"Unsupported non-normal LNS16 value: 0x{bits:04X}")

    sign = -1.0 if ((bits >> 13) & 1) else 1.0
    log_fixed = bits_to_signed13(bits)

    return sign * (2.0 ** (log_fixed / LNS16_SCALE))



def posit_bits_to_float(ui: int, nbits: int = POSIT16_NBITS, es: int = POSIT16_ES) -> float:
    """
    Decode a posit integer into a Python float.

    Current automated posit16 flow uses posit<16,1>, matching the generator.
    """
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

    # Skip regime termination bit if present.
    if idx < len(bits):
        idx += 1

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


def decode_posit16(hex_word: str) -> float:
    """
    Decode posit<16,1> into a Python float.
    """
    bits = int(hex_word, 16) & 0xFFFF
    return posit_bits_to_float(bits, POSIT16_NBITS, POSIT16_ES)


def decode_word(hex_word: str, fmt: str) -> float:
    fmt_l = fmt.lower()

    if fmt_l == "fp16":
        return decode_fp16(hex_word)

    if fmt_l == "lns16":
        return decode_lns16(hex_word)

    if fmt_l == "posit16":
        return decode_posit16(hex_word)

    raise NotImplementedError(
        f"Decoded-real comparison is not implemented for format {fmt!r}. "
        "Currently supported: fp16, lns16, posit16."
    )


def relative_error(abs_error: float, golden_real: float) -> float:
    denom = abs(golden_real)

    if denom == 0.0:
        if abs_error == 0.0:
            return 0.0
        return math.inf

    return abs_error / denom


def compare_matrices(
    golden: List[List[str]],
    hardware: List[List[str]],
    rows: int,
    cols: int,
    fmt: str,
) -> List[ElementComparison]:
    comparisons: List[ElementComparison] = []

    for r in range(rows):
        for c in range(cols):
            golden_hex = golden[r][c]
            hardware_hex = hardware[r][c]

            golden_real = decode_word(golden_hex, fmt)
            hardware_real = decode_word(hardware_hex, fmt)

            abs_err = abs(hardware_real - golden_real)
            rel_err = relative_error(abs_err, golden_real)

            comparisons.append(
                ElementComparison(
                    row=r,
                    col=c,
                    golden_hex=golden_hex,
                    hardware_hex=hardware_hex,
                    golden_real=golden_real,
                    hardware_real=hardware_real,
                    abs_error=abs_err,
                    rel_error=rel_err,
                    encoded_exact_match=(golden_hex == hardware_hex),
                )
            )

    return comparisons


def finite_values(values: List[float]) -> List[float]:
    return [v for v in values if math.isfinite(v)]


def compute_summary(comparisons: List[ElementComparison]) -> dict:
    total = len(comparisons)

    exact_matches = sum(1 for item in comparisons if item.encoded_exact_match)
    mismatches = total - exact_matches
    exact_percent = (exact_matches / total) * 100.0 if total else 0.0

    abs_errors = [item.abs_error for item in comparisons]
    rel_errors = [item.rel_error for item in comparisons]

    finite_rel_errors = finite_values(rel_errors)

    mean_abs_error = sum(abs_errors) / total if total else 0.0
    max_abs_error = max(abs_errors) if abs_errors else 0.0
    rmse = math.sqrt(sum(e * e for e in abs_errors) / total) if total else 0.0

    if finite_rel_errors:
        mean_rel_error = sum(finite_rel_errors) / len(finite_rel_errors)
        max_rel_error = max(finite_rel_errors)
    else:
        mean_rel_error = math.inf if any(math.isinf(e) for e in rel_errors) else 0.0
        max_rel_error = math.inf if any(math.isinf(e) for e in rel_errors) else 0.0

    infinite_rel_error_count = sum(1 for e in rel_errors if math.isinf(e))

    return {
        "total_elements": total,
        "exact_matches": exact_matches,
        "encoded_mismatches": mismatches,
        "exact_match_percent": exact_percent,
        "mean_abs_error": mean_abs_error,
        "max_abs_error": max_abs_error,
        "rmse": rmse,
        "mean_rel_error": mean_rel_error,
        "max_rel_error": max_rel_error,
        "infinite_rel_error_count": infinite_rel_error_count,
    }


def fmt_float(value: float) -> str:
    if math.isinf(value):
        return "inf"
    if math.isnan(value):
        return "nan"
    return f"{value:.12g}"


def write_csv(path: Path, comparisons: List[ElementComparison]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)

        writer.writerow(
            [
                "row",
                "col",
                "golden_hex",
                "hardware_hex",
                "encoded_exact_match",
                "golden_real",
                "hardware_real",
                "abs_error",
                "rel_error",
            ]
        )

        for item in comparisons:
            writer.writerow(
                [
                    item.row,
                    item.col,
                    item.golden_hex,
                    item.hardware_hex,
                    int(item.encoded_exact_match),
                    fmt_float(item.golden_real),
                    fmt_float(item.hardware_real),
                    fmt_float(item.abs_error),
                    fmt_float(item.rel_error),
                ]
            )


def build_report(
    golden_file: Path,
    hw_file: Path,
    section_label: str,
    fmt: str,
    rows: int,
    cols: int,
    comparisons: List[ElementComparison],
    max_rows_to_print: int,
) -> str:
    summary = compute_summary(comparisons)

    nonzero_error_items = [item for item in comparisons if item.abs_error != 0.0]

    # Sort by absolute error descending for the most informative diagnostic list.
    largest_errors = sorted(
        nonzero_error_items,
        key=lambda item: item.abs_error,
        reverse=True,
    )

    lines: List[str] = []

    lines.append("FlexGrip Plus D matrix decoded-real validation report")
    lines.append("=" * 70)
    lines.append("")
    lines.append(f"Format:                    {fmt}")
    lines.append(f"Golden file:               {golden_file}")
    lines.append(f"Golden section:            {section_label}")
    lines.append(f"Hardware file:             {hw_file}")
    lines.append(f"Matrix shape:              {rows}x{cols}")
    lines.append("")
    lines.append("Encoded-domain exact comparison")
    lines.append("-" * 70)
    lines.append(f"Total elements:            {summary['total_elements']}")
    lines.append(f"Exact encoded matches:     {summary['exact_matches']} / {summary['total_elements']}")
    lines.append(f"Exact encoded match %:     {summary['exact_match_percent']:.6f}%")
    lines.append(f"Encoded mismatches:        {summary['encoded_mismatches']}")
    lines.append("")
    lines.append("Decoded-real error metrics")
    lines.append("-" * 70)
    lines.append(f"Mean absolute error:       {fmt_float(summary['mean_abs_error'])}")
    lines.append(f"Max absolute error:        {fmt_float(summary['max_abs_error'])}")
    lines.append(f"RMSE:                      {fmt_float(summary['rmse'])}")
    lines.append(f"Mean relative error:       {fmt_float(summary['mean_rel_error'])}")
    lines.append(f"Max relative error:        {fmt_float(summary['max_rel_error'])}")
    lines.append(f"Infinite relative errors:  {summary['infinite_rel_error_count']}")
    lines.append("")
    lines.append("Interpretation")
    lines.append("-" * 70)

    if summary["encoded_mismatches"] == 0:
        lines.append("Encoded result:            EXACT MATCH")
    else:
        lines.append("Encoded result:            NOT EXACT")

    if summary["max_abs_error"] == 0.0:
        lines.append("Decoded-real result:       ZERO ERROR")
    else:
        lines.append("Decoded-real result:       NONZERO ERROR")

    lines.append("")

    if largest_errors:
        lines.append(f"Largest decoded-real errors, top {min(max_rows_to_print, len(largest_errors))}")
        lines.append("-" * 70)
        lines.append(
            "row,col,golden_hex,hardware_hex,golden_real,hardware_real,abs_error,rel_error"
        )

        for item in largest_errors[:max_rows_to_print]:
            lines.append(
                ",".join(
                    [
                        str(item.row),
                        str(item.col),
                        item.golden_hex,
                        item.hardware_hex,
                        fmt_float(item.golden_real),
                        fmt_float(item.hardware_real),
                        fmt_float(item.abs_error),
                        fmt_float(item.rel_error),
                    ]
                )
            )

        if len(largest_errors) > max_rows_to_print:
            lines.append(
                f"... truncated: showing {max_rows_to_print} of {len(largest_errors)} nonzero-error elements"
            )
    else:
        lines.append("No decoded-real errors found.")

    lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Compare an extracted FlexGrip hardware D matrix with a golden "
            "encoded D matrix and compute decoded-real error metrics."
        )
    )

    parser.add_argument(
        "--format",
        required=True,
        choices=["fp16", "lns16", "posit16"],
        help="Numeric format used to decode 16-bit words. Supported: fp16, lns16, posit16.",
    )
    parser.add_argument(
        "--golden-file",
        required=True,
        type=Path,
        help="Generated experiment text file containing the golden encoded D matrix.",
    )
    parser.add_argument(
        "--hw-file",
        required=True,
        type=Path,
        help="Extracted hardware D matrix file.",
    )
    parser.add_argument(
        "--output-report",
        required=True,
        type=Path,
        help="Output validation report path.",
    )
    parser.add_argument(
        "--output-csv",
        type=Path,
        default=None,
        help=(
            "Optional per-element CSV output. "
            "Default: same folder as output report, named validation_element_errors.csv"
        ),
    )
    parser.add_argument(
        "--golden-label",
        default="#FULL_D_16x16_one_shot_reference encoded",
        help=(
            "Golden matrix section label. "
            "Default: '#FULL_D_16x16_one_shot_reference encoded'"
        ),
    )
    parser.add_argument("--rows", type=int, default=16, help="Matrix rows. Default: 16.")
    parser.add_argument("--cols", type=int, default=16, help="Matrix columns. Default: 16.")
    parser.add_argument(
        "--max-rows-to-print",
        type=int,
        default=64,
        help="Maximum number of largest-error rows to include in the report. Default: 64.",
    )

    args = parser.parse_args()

    output_csv = args.output_csv
    if output_csv is None:
        output_csv = args.output_report.parent / "validation_element_errors.csv"

    golden_matrix = read_matrix_after_section(
        path=args.golden_file,
        section_label=args.golden_label,
        rows=args.rows,
        cols=args.cols,
    )

    hardware_matrix = read_plain_matrix(
        path=args.hw_file,
        rows=args.rows,
        cols=args.cols,
    )

    comparisons = compare_matrices(
        golden=golden_matrix,
        hardware=hardware_matrix,
        rows=args.rows,
        cols=args.cols,
        fmt=args.format,
    )

    report = build_report(
        golden_file=args.golden_file,
        hw_file=args.hw_file,
        section_label=args.golden_label,
        fmt=args.format,
        rows=args.rows,
        cols=args.cols,
        comparisons=comparisons,
        max_rows_to_print=args.max_rows_to_print,
    )

    args.output_report.parent.mkdir(parents=True, exist_ok=True)
    args.output_report.write_text(report, encoding="utf-8")

    write_csv(output_csv, comparisons)

    print(report)
    print(f"Validation report written to: {args.output_report}")
    print(f"Per-element CSV written to:   {output_csv}")

    # Return 0 even if there are errors/mismatches.
    # Numerical validation may intentionally produce nonzero error.
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
