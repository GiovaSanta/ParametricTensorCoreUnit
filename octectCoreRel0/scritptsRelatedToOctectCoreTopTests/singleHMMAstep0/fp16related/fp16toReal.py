#!/usr/bin/env python3
"""
Decode FP16 hex matrices from a text file and write real values to an output file.

Input example:
#A00 4 by 4 submatrix
0001 0002 0003 0004
0011 0012 0013 0014

#B00 4 by 4 submatrix
0101 0102 0103 0104
...

Usage:
    python decode_fp16_matrices.py input.txt output.txt
"""

from __future__ import annotations

import re
import sys
import struct
from pathlib import Path


HEX16_RE = re.compile(r"^[0-9A-Fa-f]{4}$")


def fp16_hex_to_float(hex_word: str) -> float:
    """Convert a 4-hex-digit FP16 word into a Python float."""
    value = int(hex_word, 16)
    raw = struct.pack(">H", value)
    return struct.unpack(">e", raw)[0]


def format_float(value: float) -> str:
    """Format decoded float for readable text output."""
    # '.8g' gives readable compact output while still showing small/subnormal values
    return f"{value:.8g}"


def decode_line(line: str) -> str:
    """
    Decode one line of FP16 hex values.
    Non-hex tokens are preserved as-is.
    """
    stripped = line.strip()

    # Preserve blank lines exactly
    if stripped == "":
        return ""

    # Preserve comments/headers exactly
    if stripped.startswith("#"):
        return line.rstrip("\n")

    tokens = stripped.split()
    decoded_tokens = []

    for tok in tokens:
        if HEX16_RE.fullmatch(tok):
            decoded = fp16_hex_to_float(tok)
            decoded_tokens.append(format_float(decoded))
        else:
            decoded_tokens.append(tok)

    return " ".join(decoded_tokens)


def decode_file(input_path: Path, output_path: Path) -> None:
    with input_path.open("r", encoding="utf-8") as f:
        lines = f.readlines()

    decoded_lines = [decode_line(line) for line in lines]

    with output_path.open("w", encoding="utf-8") as f:
        for line in decoded_lines:
            f.write(line + "\n")


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: python decode_fp16_matrices.py input.txt output.txt")
        return 1

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])

    if not input_path.exists():
        print(f"Error: input file not found: {input_path}")
        return 1

    try:
        decode_file(input_path, output_path)
    except Exception as exc:
        print(f"Error while decoding file: {exc}")
        return 1

    print(f"Decoded FP16 values written to: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())