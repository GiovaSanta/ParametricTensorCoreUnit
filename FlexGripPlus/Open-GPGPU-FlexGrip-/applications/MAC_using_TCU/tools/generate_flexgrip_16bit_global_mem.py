#!/usr/bin/env python3
"""
Generate a FlexGrip Plus 16-bit global_mem.mif payload from an annotated matrix file.

Default behavior:
  - reads #FULL_A_16x16 encoded
  - reads #FULL_B_16x16 encoded
  - reads #FULL_C_16x16 encoded

Output behavior:
  - A is emitted in row-major layout
  - B is emitted in column-major layout, i.e. transposed for hardware feeding
  - C is emitted in row-major layout
  - every 16-bit encoded word is emitted as little-endian bytes
  - output is one byte per line, uppercase hex, with no comments by default
  - default output filename is: global_mem.mif

Example:
  input word 0x7DB7 becomes:
    B7
    7D

Typical usage:
  python3 generate_flexgrip_16bit_global_mem.py --input matricesInvolvedandExpected.txt

Optional explicit output path:
  python3 generate_flexgrip_16bit_global_mem.py --input matricesInvolvedandExpected.txt --output global_mem.mif
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Iterable, List


HEX16_RE = re.compile(r"^[0-9a-fA-F]{1,4}$")


DEFAULT_LABELS = {
    "A": "#FULL_A_16x16 encoded",
    "B": "#FULL_B_16x16 encoded",
    "C": "#FULL_C_16x16 encoded",
}


def find_label_line(lines: List[str], label: str) -> int:
    wanted = label.strip().lower()
    for idx, line in enumerate(lines):
        if line.strip().lower() == wanted:
            return idx
    raise ValueError(f"Could not find section label: {label}")


def parse_encoded_matrix(
    lines: List[str],
    label: str,
    rows: int,
    cols: int,
) -> List[List[str]]:
    """
    Parse a rows x cols matrix of 16-bit hex words after a section label.

    The parser starts immediately after the label and stops when rows*cols
    words have been collected. Blank lines are ignored. If a new comment
    section appears after some tokens were collected, parsing stops there.
    """
    start = find_label_line(lines, label) + 1
    needed = rows * cols
    tokens: List[str] = []

    for line_no, raw in enumerate(lines[start:], start=start + 1):
        stripped = raw.strip()

        if not stripped:
            continue

        if stripped.startswith("#"):
            if tokens:
                break
            continue

        for token in stripped.split():
            if not HEX16_RE.fullmatch(token):
                raise ValueError(
                    f"Invalid 16-bit hex token {token!r} at line {line_no} "
                    f"while parsing {label}"
                )
            tokens.append(token.upper().zfill(4))

        if len(tokens) >= needed:
            break

    if len(tokens) != needed:
        raise ValueError(
            f"Section {label} has {len(tokens)} words, expected {needed} "
            f"for a {rows}x{cols} matrix."
        )

    return [tokens[r * cols : (r + 1) * cols] for r in range(rows)]


def iter_words(matrix: List[List[str]], layout: str) -> Iterable[str]:
    rows = len(matrix)
    cols = len(matrix[0]) if rows else 0

    if layout == "row-major":
        for r in range(rows):
            for c in range(cols):
                yield matrix[r][c]
        return

    if layout == "column-major":
        for c in range(cols):
            for r in range(rows):
                yield matrix[r][c]
        return

    raise ValueError(f"Unknown layout: {layout}")


def word_to_bytes(word_hex: str, endian: str) -> List[str]:
    value = int(word_hex, 16)
    lo = value & 0xFF
    hi = (value >> 8) & 0xFF

    if endian == "little":
        return [f"{lo:02X}", f"{hi:02X}"]

    if endian == "big":
        return [f"{hi:02X}", f"{lo:02X}"]

    raise ValueError(f"Unknown endian: {endian}")


def emit_matrix_bytes(
    matrix: List[List[str]],
    layout: str,
    endian: str,
) -> List[str]:
    output: List[str] = []
    for word in iter_words(matrix, layout):
        output.extend(word_to_bytes(word, endian))
    return output


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Generate global_mem.mif as a one-byte-per-line FlexGrip Plus "
            "payload from encoded 16-bit A/B/C matrices."
        )
    )

    parser.add_argument(
        "-i",
        "--input",
        required=True,
        type=Path,
        help="Input annotated text file containing encoded matrix sections.",
    )
    parser.add_argument(
        "-o",
        "--output",
        default=Path("global_mem.mif"),
        type=Path,
        help="Output file. Default: global_mem.mif",
    )
    parser.add_argument("--rows", type=int, default=16, help="Matrix row count. Default: 16.")
    parser.add_argument("--cols", type=int, default=16, help="Matrix column count. Default: 16.")

    parser.add_argument("--a-label", default=DEFAULT_LABELS["A"], help="Section label for A.")
    parser.add_argument("--b-label", default=DEFAULT_LABELS["B"], help="Section label for B.")
    parser.add_argument("--c-label", default=DEFAULT_LABELS["C"], help="Section label for C.")

    parser.add_argument(
        "--endian",
        choices=["little", "big"],
        default="little",
        help="Byte order used to emit each 16-bit word. Default: little.",
    )
    parser.add_argument(
        "--with-section-comments",
        action="store_true",
        help="Add section comments to the output. Default output is raw bytes only.",
    )

    args = parser.parse_args()

    lines = args.input.read_text(encoding="utf-8").splitlines()

    A = parse_encoded_matrix(lines, args.a_label, args.rows, args.cols)
    B = parse_encoded_matrix(lines, args.b_label, args.rows, args.cols)
    C = parse_encoded_matrix(lines, args.c_label, args.rows, args.cols)

    sections = [
        ("A", "row-major", A),
        ("B", "column-major", B),
        ("C", "row-major", C),
    ]

    output_lines: List[str] = []

    for name, layout, matrix in sections:
        if args.with_section_comments:
            output_lines.append(f"# {name}: {layout}, {args.endian}-endian bytes")
        output_lines.extend(emit_matrix_bytes(matrix, layout, args.endian))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(output_lines) + "\n", encoding="utf-8")

    words_per_matrix = args.rows * args.cols
    bytes_per_matrix = words_per_matrix * 2
    total_bytes = bytes_per_matrix * 3

    print("Generated FlexGrip Plus global_mem.mif payload.")
    print(f"Input:  {args.input}")
    print(f"Output: {args.output}")
    print("A layout: row-major")
    print("B layout: column-major")
    print("C layout: row-major")
    print(f"Endian: {args.endian}")
    print(f"Matrix shape: {args.rows}x{args.cols}")
    print(f"Words per matrix: {words_per_matrix}")
    print(f"Bytes per matrix: {bytes_per_matrix}")
    print(f"Total output bytes: {total_bytes}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
