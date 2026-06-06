#!/usr/bin/env python3
"""
Compare a FlexGrip Plus extracted hardware D matrix against a golden encoded D matrix,
including decoded-real error metrics.

Default golden section:
    #FULL_D_16x16_one_shot_reference encoded

Supported decoded formats:
    fp16      -> 16-bit IEEE half
    fp32      -> 32-bit IEEE single
    lns16     -> LNS16 4_9
    posit16   -> posit<16,1>
    posit32   -> posit<32,2>
    fp8       -> FP8 E4M3, 8-bit
    fxp8_16   -> mixed fixed-point: A/B 8-bit, C/D 16-bit signed_5_M10
    posit8    -> posit<8,0>, 8-bit

Typical usage from MAC_using_TCU:

FP16:
    python tools/compare_flexgrip_d_matrix.py \
        --format fp16 \
        --golden-file fp16operands/hmma_8instr_dualTC_4octects_fp16_single_experiment.txt \
        --hw-file fp16operands/hw_D_matrix_extracted.txt \
        --output-report fp16operands/validation_report.txt \
        --output-csv fp16operands/validation_element_errors.csv

FP8:
    python tools/compare_flexgrip_d_matrix.py \
        --format fp8 \
        --golden-file fp8e4m3eoperands/hmma_8instr_dualTC_4octects_fp8_single_experiment.txt \
        --hw-file fp8e4m3eoperands/hw_D_matrix_extracted.txt \
        --output-report fp8e4m3eoperands/validation_report.txt \
        --output-csv fp8e4m3eoperands/validation_element_errors.csv
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


# ---------- Format metadata ----------

FORMAT_ELEMENT_BITS = {
    "fp16": 16,
    "fp32": 32,
    "lns16": 16,
    "posit16": 16,
    "posit32": 32,
    "fp8": 8,
    "posit8": 8,
    "fxp8_16": 16,
    "fxp16_32": 32,
}

# LNS16 4_9 format:
#   bits 15:14 = 01 for normal finite values
#   bit 13     = sign
#   bits 12:0  = signed fixed-point log2(|value|)
#   wF = 9, scale = 2^9 = 512
LNS16_WF = 9
LNS16_SCALE = 1 << LNS16_WF

# Posit16 convention used by the current posit16 generator:
#   posit<16,1>
POSIT16_NBITS = 16
POSIT16_ES = 1

# Posit32 convention used by the current posit32 generator:
#   posit<32,2>
POSIT32_NBITS = 32
POSIT32_ES = 2

# Posit8 convention used by the current posit8 generator:
#   posit<8,0>
POSIT8_NBITS = 8
POSIT8_ES = 0

# FP8 E4M3 convention used by the current fp8 generator.
FP8_EXP_BITS = 4
FP8_MAN_BITS = 3
FP8_EXP_BIAS = 7

# FXP8/FXP16 mixed format output convention:
#   D is signed_5_M10 -> 16-bit two's complement, 10 fractional bits.
FXP16_FRAC_BITS = 10

# FXP16/FXP32 mixed format output convention:
#   D is signed_11_M20 -> 32-bit two's complement, 20 fractional bits.
FXP32_FRAC_BITS = 20


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


def hex_re_for_bits(element_bits: int) -> re.Pattern[str]:
    max_digits = element_bits // 4
    return re.compile(rf"^[0-9A-Fa-f]{{1,{max_digits}}}$")


def normalize_hex_word(token: str, element_bits: int) -> str:
    token = token.strip()
    max_digits = element_bits // 4

    if not hex_re_for_bits(element_bits).fullmatch(token):
        raise ValueError(f"Invalid {element_bits}-bit hex token: {token!r}")

    return token.upper().zfill(max_digits)


def element_bits_for_format(fmt: str) -> int:
    fmt_l = fmt.lower()

    if fmt_l not in FORMAT_ELEMENT_BITS:
        raise ValueError(
            f"Unsupported format {fmt!r}. "
            f"Supported: {', '.join(sorted(FORMAT_ELEMENT_BITS))}"
        )

    return FORMAT_ELEMENT_BITS[fmt_l]


# ---------- Matrix readers ----------

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
    element_bits: int,
) -> List[List[str]]:
    """
    Read rows*cols encoded hex tokens immediately after a section label.

    Blank lines are ignored.
    If a new '#' section begins after tokens were collected, parsing stops.
    """
    lines = path.read_text(encoding="utf-8").splitlines()
    start_idx = find_section_line(lines, section_label) + 1

    needed = rows * cols
    tokens: List[str] = []

    for raw in lines[start_idx:]:
        stripped = raw.strip()

        if not stripped:
            continue

        if stripped.startswith("#"):
            if tokens:
                break
            continue

        for token in stripped.split():
            tokens.append(normalize_hex_word(token, element_bits))

        if len(tokens) >= needed:
            break

    if len(tokens) != needed:
        raise ValueError(
            f"Section {section_label!r} in {path} contains {len(tokens)} words; "
            f"expected {needed} for a {rows}x{cols} matrix."
        )

    return [tokens[r * cols : (r + 1) * cols] for r in range(rows)]


def read_plain_matrix(
    path: Path,
    rows: int,
    cols: int,
    element_bits: int,
) -> List[List[str]]:
    tokens: List[str] = []

    with path.open("r", encoding="utf-8") as f:
        for raw in f:
            stripped = raw.strip()

            if not stripped or stripped.startswith("#"):
                continue

            for token in stripped.split():
                tokens.append(normalize_hex_word(token, element_bits))

    needed = rows * cols

    if len(tokens) != needed:
        raise ValueError(
            f"Hardware matrix file {path} contains {len(tokens)} words; "
            f"expected {needed} for a {rows}x{cols} matrix."
        )

    return [tokens[r * cols : (r + 1) * cols] for r in range(rows)]



def read_real_matrix_after_section(
    path: Path,
    section_label: str,
    rows: int,
    cols: int,
) -> List[List[float]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    start_idx = find_section_line(lines, section_label) + 1

    needed = rows * cols
    values: List[float] = []

    for raw in lines[start_idx:]:
        stripped = raw.strip()

        if not stripped:
            continue

        if stripped.startswith("#"):
            if values:
                break
            continue

        for token in stripped.split():
            values.append(float(token))

        if len(values) >= needed:
            break

    if len(values) != needed:
        raise ValueError(
            f"Real-valued section {section_label!r} in {path} contains {len(values)} values; "
            f"expected {needed} for a {rows}x{cols} matrix."
        )

    return [values[r * cols : (r + 1) * cols] for r in range(rows)]


# ---------- Decoders ----------

def decode_fp16(hex_word: str) -> float:
    bits = np.array([int(hex_word, 16)], dtype=np.uint16)
    value = bits.view(np.float16)[0]
    return float(value)


def decode_fp32(hex_word: str) -> float:
    bits = np.array([int(hex_word, 16)], dtype=np.uint32)
    value = bits.view(np.float32)[0]
    return float(value)


def bits_to_signed13(x: int) -> int:
    v = x & 0x1FFF

    if v & 0x1000:
        v -= 0x2000

    return v


def decode_lns16(hex_word: str) -> float:
    bits = int(hex_word, 16) & 0xFFFF

    if bits == 0x0000:
        return 0.0

    if (bits >> 14) != 0b01:
        raise ValueError(f"Unsupported non-normal LNS16 value: 0x{bits:04X}")

    sign = -1.0 if ((bits >> 13) & 1) else 1.0
    log_fixed = bits_to_signed13(bits)

    return sign * (2.0 ** (log_fixed / LNS16_SCALE))


def posit_bits_to_float(ui: int, nbits: int = POSIT16_NBITS, es: int = POSIT16_ES) -> float:
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
    bits = int(hex_word, 16) & 0xFFFF
    return posit_bits_to_float(bits, POSIT16_NBITS, POSIT16_ES)


def decode_posit32(hex_word: str) -> float:
    bits = int(hex_word, 16) & 0xFFFFFFFF
    return posit_bits_to_float(bits, POSIT32_NBITS, POSIT32_ES)


def decode_posit8(hex_word: str) -> float:
    bits = int(hex_word, 16) & 0xFF
    return posit_bits_to_float(bits, POSIT8_NBITS, POSIT8_ES)


def decode_fp8_e4m3(hex_word: str) -> float:
    code = int(hex_word, 16) & 0xFF

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



def decode_fxp8_16_output(hex_word: str) -> float:
    """
    Decode the mixed FXP8/FXP16 result D.

    A/B are 8-bit signed_2_M5, but D is 16-bit signed_5_M10.
    Therefore comparison decodes the 16-bit result as signed int16 / 2^10.
    """
    raw = int(hex_word, 16) & 0xFFFF
    if raw & 0x8000:
        raw -= 0x10000
    return float(raw) / float(1 << FXP16_FRAC_BITS)


def decode_fxp16_32_output(hex_word: str) -> float:
    raw = int(hex_word, 16) & 0xFFFFFFFF
    if raw & 0x80000000:
        raw -= 0x100000000
    return float(raw) / float(1 << FXP32_FRAC_BITS)


def decode_word(hex_word: str, fmt: str) -> float:
    fmt_l = fmt.lower()

    if fmt_l == "fp16":
        return decode_fp16(hex_word)

    if fmt_l == "fp32":
        return decode_fp32(hex_word)

    if fmt_l == "lns16":
        return decode_lns16(hex_word)

    if fmt_l == "posit16":
        return decode_posit16(hex_word)

    if fmt_l == "posit32":
        return decode_posit32(hex_word)

    if fmt_l == "fp8":
        return decode_fp8_e4m3(hex_word)

    if fmt_l == "posit8":
        return decode_posit8(hex_word)

    if fmt_l == "fxp8_16":
        return decode_fxp8_16_output(hex_word)

    if fmt_l == "fxp16_32":
        return decode_fxp16_32_output(hex_word)

    raise NotImplementedError(
        f"Decoded-real comparison is not implemented for format {fmt!r}."
    )


# ---------- Comparison / reporting ----------

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
    real_golden: List[List[float]] | None = None,
) -> List[ElementComparison]:
    comparisons: List[ElementComparison] = []

    for r in range(rows):
        for c in range(cols):
            golden_hex = golden[r][c]
            hardware_hex = hardware[r][c]

            if real_golden is None:
                golden_real = decode_word(golden_hex, fmt)
            else:
                golden_real = float(real_golden[r][c])

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

    finite_abs_errors = finite_values(abs_errors)
    finite_rel_errors = finite_values(rel_errors)

    mean_abs_error = sum(finite_abs_errors) / len(finite_abs_errors) if finite_abs_errors else 0.0
    max_abs_error = max(finite_abs_errors) if finite_abs_errors else 0.0
    rmse = math.sqrt(sum(e * e for e in finite_abs_errors) / len(finite_abs_errors)) if finite_abs_errors else 0.0

    mean_rel_error = sum(finite_rel_errors) / len(finite_rel_errors) if finite_rel_errors else 0.0
    max_rel_error = max(finite_rel_errors) if finite_rel_errors else 0.0

    infinite_rel_error_count = sum(1 for e in rel_errors if math.isinf(e))
    nan_error_count = sum(
        1 for item in comparisons
        if math.isnan(item.golden_real) or math.isnan(item.hardware_real)
        or math.isnan(item.abs_error) or math.isnan(item.rel_error)
    )

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
        "nan_error_count": nan_error_count,
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
    real_golden_label: str | None = None,
) -> str:
    summary = compute_summary(comparisons)

    nonzero_error_items = [
        item for item in comparisons
        if math.isfinite(item.abs_error) and item.abs_error != 0.0
    ]

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
    lines.append(f"Golden encoded section:    {section_label}")
    if real_golden_label is not None:
        lines.append(f"Golden real section:       {real_golden_label}")
    lines.append(f"Hardware file:             {hw_file}")
    lines.append(f"Matrix shape:              {rows}x{cols}")
    lines.append(f"Element bits:              {element_bits_for_format(fmt)}")
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
    lines.append(f"NaN-related error rows:    {summary['nan_error_count']}")
    lines.append("")
    lines.append("Interpretation")
    lines.append("-" * 70)

    lines.append(
        "Encoded result:            "
        + ("EXACT MATCH" if summary["encoded_mismatches"] == 0 else "NOT EXACT")
    )

    lines.append(
        "Decoded-real result:       "
        + ("ZERO ERROR" if summary["max_abs_error"] == 0.0 else "NONZERO ERROR")
    )

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
        choices=sorted(FORMAT_ELEMENT_BITS.keys()),
        help="Numeric format used to decode encoded result words.",
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
            "Golden encoded matrix section label. "
            "Default: '#FULL_D_16x16_one_shot_reference encoded'"
        ),
    )
    parser.add_argument(
        "--real-golden-label",
        default=None,
        help=(
            "Optional real-valued golden matrix section label. "
            "When provided, decoded-real errors are computed against this real section, "
            "while encoded exact matches are still checked against --golden-label."
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

    element_bits = element_bits_for_format(args.format)

    output_csv = args.output_csv
    if output_csv is None:
        output_csv = args.output_report.parent / "validation_element_errors.csv"

    golden_matrix = read_matrix_after_section(
        path=args.golden_file,
        section_label=args.golden_label,
        rows=args.rows,
        cols=args.cols,
        element_bits=element_bits,
    )

    hardware_matrix = read_plain_matrix(
        path=args.hw_file,
        rows=args.rows,
        cols=args.cols,
        element_bits=element_bits,
    )

    real_golden_matrix = None
    if args.real_golden_label is not None:
        real_golden_matrix = read_real_matrix_after_section(
            path=args.golden_file,
            section_label=args.real_golden_label,
            rows=args.rows,
            cols=args.cols,
        )

    comparisons = compare_matrices(
        golden=golden_matrix,
        hardware=hardware_matrix,
        rows=args.rows,
        cols=args.cols,
        fmt=args.format,
        real_golden=real_golden_matrix,
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
        real_golden_label=args.real_golden_label,
    )

    args.output_report.parent.mkdir(parents=True, exist_ok=True)
    args.output_report.write_text(report, encoding="utf-8")

    write_csv(output_csv, comparisons)

    print(report)
    print(f"Validation report written to: {args.output_report}")
    print(f"Per-element CSV written to:   {output_csv}")

    # Return 0 even if there are errors/mismatches.
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
