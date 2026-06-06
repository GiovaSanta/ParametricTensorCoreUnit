#!/usr/bin/env python3
"""
Generate FlexGrip global_mem.mif for 8-bit matrix operands.

Input file must contain these sections:
    #FULL_A_16x16 encoded
    #FULL_B_16x16 encoded
    #FULL_C_16x16 encoded

Output layout:
    A: row-major, one byte per element
    B: column-major, one byte per element
       This stores B^T in memory for the Tensor Core feeding convention.
    C: row-major, one byte per element

Each output line contains one 8-bit hex byte.

Typical usage from MAC_using_TCU:
    python tools/generate_flexgrip_8bit_global_mem.py \
        --input fp8e4m3eoperands/hmma_8instr_dualTC_4octects_fp8_single_experiment.txt \
        --output fp8e4m3eoperands/global_mem.mif
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import List


HEX8_RE = re.compile(r"^[0-9A-Fa-f]{1,2}$")


def normalize_hex8(token: str) -> str:
    token = token.strip()

    if not HEX8_RE.fullmatch(token):
        raise ValueError(f"Invalid 8-bit hex token: {token!r}")

    return token.upper().zfill(2)


def find_section_line(lines: list[str], section_label: str) -> int:
    wanted = section_label.strip().lower()

    for idx, line in enumerate(lines):
        if line.strip().lower() == wanted:
            return idx

    raise ValueError(f"Could not find section label: {section_label}")


def read_matrix_after_section(
    path: Path,
    section_label: str,
    rows: int,
    cols: int,
) -> List[List[str]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    start_idx = find_section_line(lines, section_label) + 1

    needed = rows * cols
    tokens: list[str] = []

    for raw in lines[start_idx:]:
        stripped = raw.strip()

        if not stripped:
            continue

        if stripped.startswith("#"):
            if tokens:
                break
            continue

        for token in stripped.split():
            tokens.append(normalize_hex8(token))

        if len(tokens) >= needed:
            break

    if len(tokens) != needed:
        raise ValueError(
            f"Section {section_label!r} contains {len(tokens)} elements; "
            f"expected {needed} for {rows}x{cols}."
        )

    return [tokens[r * cols : (r + 1) * cols] for r in range(rows)]


def flatten_row_major(matrix: List[List[str]]) -> list[str]:
    out: list[str] = []
    for row in matrix:
        out.extend(row)
    return out


def flatten_column_major(matrix: List[List[str]]) -> list[str]:
    rows = len(matrix)
    cols = len(matrix[0]) if rows else 0

    out: list[str] = []
    for c in range(cols):
        for r in range(rows):
            out.append(matrix[r][c])
    return out


def write_global_mem(path: Path, bytes_out: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(bytes_out) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate 8-bit FlexGrip global_mem.mif from encoded A/B/C matrices."
    )
    parser.add_argument("--input", required=True, type=Path, help="Input experiment text file.")
    parser.add_argument("--output", required=True, type=Path, help="Output global_mem.mif path.")
    parser.add_argument("--rows", type=int, default=16, help="Matrix rows. Default: 16.")
    parser.add_argument("--cols", type=int, default=16, help="Matrix columns. Default: 16.")

    args = parser.parse_args()

    A = read_matrix_after_section(args.input, "#FULL_A_16x16 encoded", args.rows, args.cols)
    B = read_matrix_after_section(args.input, "#FULL_B_16x16 encoded", args.rows, args.cols)
    C = read_matrix_after_section(args.input, "#FULL_C_16x16 encoded", args.rows, args.cols)

    bytes_out = []
    bytes_out.extend(flatten_row_major(A))
    bytes_out.extend(flatten_column_major(B))
    bytes_out.extend(flatten_row_major(C))

    write_global_mem(args.output, bytes_out)

    print("Generated 8-bit FlexGrip global_mem.mif")
    print(f"Input experiment: {args.input}")
    print(f"Output file:      {args.output}")
    print(f"Matrix shape:     {args.rows}x{args.cols}")
    print(f"A bytes:          {args.rows * args.cols}")
    print(f"B bytes:          {args.rows * args.cols}")
    print(f"C bytes:          {args.rows * args.cols}")
    print(f"Total bytes:      {len(bytes_out)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
