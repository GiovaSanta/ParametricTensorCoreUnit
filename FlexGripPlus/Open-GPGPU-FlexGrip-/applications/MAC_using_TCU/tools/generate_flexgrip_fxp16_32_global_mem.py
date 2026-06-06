#!/usr/bin/env python3
"""
Generate FlexGrip global_mem.mif for the mixed FXP16/FXP32 Tensor Core flow.

Format:
    A/B : signed_6_M10  -> 16-bit elements
    C/D : signed_11_M20 -> 32-bit elements

Input file must contain:
    #FULL_A_16x16 encoded    -> 16-bit hex tokens
    #FULL_B_16x16 encoded    -> 16-bit hex tokens
    #FULL_C_16x16 encoded    -> 32-bit hex tokens

Output byte-oriented memory layout:
    A: row-major, two bytes per element, little-endian
       base 0x000, size 0x200

    B: column-major, two bytes per element, little-endian
       base 0x200, size 0x200
       This stores B^T in memory for the Tensor Core feeding convention.

    C: row-major, four bytes per element, little-endian
       base 0x400, size 0x400

For 16x16:
    D starts at 0x800.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import List


HEX16_RE = re.compile(r"^[0-9A-Fa-f]{1,4}$")
HEX32_RE = re.compile(r"^[0-9A-Fa-f]{1,8}$")


def normalize_hex16(token: str) -> str:
    token = token.strip()
    if not HEX16_RE.fullmatch(token):
        raise ValueError(f"Invalid 16-bit hex token: {token!r}")
    return token.upper().zfill(4)


def normalize_hex32(token: str) -> str:
    token = token.strip()
    if not HEX32_RE.fullmatch(token):
        raise ValueError(f"Invalid 32-bit hex token: {token!r}")
    return token.upper().zfill(8)


def word16_to_little_endian_bytes(word_hex: str) -> list[str]:
    word = normalize_hex16(word_hex)
    return [word[2:4], word[0:2]]


def word32_to_little_endian_bytes(word_hex: str) -> list[str]:
    word = normalize_hex32(word_hex)
    return [word[6:8], word[4:6], word[2:4], word[0:2]]


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


def words32_to_byte_lines(words: list[str]) -> list[str]:
    out: list[str] = []
    for word in words:
        out.extend(word32_to_little_endian_bytes(word))
    return out


def write_global_mem(path: Path, byte_lines: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(byte_lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate mixed FXP16/FXP32 byte-oriented FlexGrip global_mem.mif."
    )
    parser.add_argument("--input", required=True, type=Path, help="Input experiment text file.")
    parser.add_argument("--output", required=True, type=Path, help="Output global_mem.mif path.")
    parser.add_argument("--rows", type=int, default=16, help="Matrix rows. Default: 16.")
    parser.add_argument("--cols", type=int, default=16, help="Matrix columns. Default: 16.")
    args = parser.parse_args()

    A = read_matrix_after_section(args.input, "#FULL_A_16x16 encoded", args.rows, args.cols, normalize_hex16)
    B = read_matrix_after_section(args.input, "#FULL_B_16x16 encoded", args.rows, args.cols, normalize_hex16)
    C = read_matrix_after_section(args.input, "#FULL_C_16x16 encoded", args.rows, args.cols, normalize_hex32)

    a_bytes = words16_to_byte_lines(flatten_row_major(A))
    b_bytes = words16_to_byte_lines(flatten_column_major(B))
    c_bytes = words32_to_byte_lines(flatten_row_major(C))

    byte_lines = []
    byte_lines.extend(a_bytes)
    byte_lines.extend(b_bytes)
    byte_lines.extend(c_bytes)

    write_global_mem(args.output, byte_lines)

    print("Generated mixed FXP16/FXP32 FlexGrip global_mem.mif")
    print(f"Input experiment: {args.input}")
    print(f"Output file:      {args.output}")
    print(f"Matrix shape:     {args.rows}x{args.cols}")
    print(f"A bytes:          {len(a_bytes)} base 0x000")
    print(f"B bytes:          {len(b_bytes)} base 0x200")
    print(f"C bytes:          {len(c_bytes)} base 0x400")
    print(f"Total byte lines: {len(byte_lines)}")
    print("Expected D start: 0x800")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
