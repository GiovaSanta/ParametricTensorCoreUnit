#!/usr/bin/env python3
"""
Generate FlexGrip global_mem.mif for the mixed INT8/INT16 Tensor Core flow.

Format:
    A/B : signed int8
    C/D : signed int16

Input file must contain:
    #FULL_A_16x16 encoded    -> 8-bit hex tokens
    #FULL_B_16x16 encoded    -> 8-bit hex tokens
    #FULL_C_16x16 encoded    -> 16-bit hex tokens

Output byte-oriented memory layout:
    A: row-major, one byte per element
       base 0x000, size 0x100

    B: column-major, one byte per element
       base 0x100, size 0x100
       This stores B^T in memory for the Tensor Core feeding convention.

    C: row-major, two bytes per element, little-endian
       base 0x200, size 0x200

For 16x16:
    D starts at 0x400.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import List


HEX8_RE = re.compile(r"^[0-9A-Fa-f]{1,2}$")
HEX16_RE = re.compile(r"^[0-9A-Fa-f]{1,4}$")


def normalize_hex8(token: str) -> str:
    token = token.strip()
    if not HEX8_RE.fullmatch(token):
        raise ValueError(f"Invalid 8-bit hex token: {token!r}")
    return token.upper().zfill(2)


def normalize_hex16(token: str) -> str:
    token = token.strip()
    if not HEX16_RE.fullmatch(token):
        raise ValueError(f"Invalid 16-bit hex token: {token!r}")
    return token.upper().zfill(4)


def word16_to_little_endian_bytes(word_hex: str) -> list[str]:
    word = normalize_hex16(word_hex)
    return [word[2:4], word[0:2]]


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
    normalizer,
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
            tokens.append(normalizer(token))

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


def words16_to_byte_lines(words: list[str]) -> list[str]:
    out: list[str] = []
    for word in words:
        out.extend(word16_to_little_endian_bytes(word))
    return out


def write_global_mem(path: Path, byte_lines: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(byte_lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate mixed INT8/INT16 byte-oriented FlexGrip global_mem.mif."
    )
    parser.add_argument("--input", required=True, type=Path, help="Input experiment text file.")
    parser.add_argument("--output", required=True, type=Path, help="Output global_mem.mif path.")
    parser.add_argument("--rows", type=int, default=16, help="Matrix rows. Default: 16.")
    parser.add_argument("--cols", type=int, default=16, help="Matrix columns. Default: 16.")
    args = parser.parse_args()

    A = read_matrix_after_section(args.input, "#FULL_A_16x16 encoded", args.rows, args.cols, normalize_hex8)
    B = read_matrix_after_section(args.input, "#FULL_B_16x16 encoded", args.rows, args.cols, normalize_hex8)
    C = read_matrix_after_section(args.input, "#FULL_C_16x16 encoded", args.rows, args.cols, normalize_hex16)

    a_bytes = flatten_row_major(A)
    b_bytes = flatten_column_major(B)
    c_bytes = words16_to_byte_lines(flatten_row_major(C))

    byte_lines = []
    byte_lines.extend(a_bytes)
    byte_lines.extend(b_bytes)
    byte_lines.extend(c_bytes)

    write_global_mem(args.output, byte_lines)

    print("Generated mixed INT8/INT16 FlexGrip global_mem.mif")
    print(f"Input experiment: {args.input}")
    print(f"Output file:      {args.output}")
    print(f"Matrix shape:     {args.rows}x{args.cols}")
    print(f"A bytes:          {len(a_bytes)} base 0x000")
    print(f"B bytes:          {len(b_bytes)} base 0x100")
    print(f"C bytes:          {len(c_bytes)} base 0x200")
    print(f"Total byte lines: {len(byte_lines)}")
    print("Expected D start: 0x400")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
