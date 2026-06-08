#!/usr/bin/env python3
"""
Extract Klessydra TCU D matrix from final_touched_words.slm.

Supported backends:
    fp16
    posit16
    lns16
    fp8
    posit8
    fp32
    posit32
    fxp8_16
    fxp16_32
    int8_16

For 16-bit element formats:
    one 32-bit SLM word contains two 16-bit elements.
    Observed Klessydra packing is low 16-bit element first, then high 16-bit element.

Example:
    c4b8c54e -> C54E C4B8

So 128 words produce a 16x16 matrix.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import List, Tuple


SLM_LINE_RE = re.compile(r"^\s*@([0-9A-Fa-f]+)\s+([0-9A-Fa-fxXzZ]+)\s*$")


def parse_slm_words(path: Path) -> List[Tuple[int, str]]:
    words: List[Tuple[int, str]] = []

    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        match = SLM_LINE_RE.match(line)
        if not match:
            continue

        addr_s, word_s = match.groups()
        word_s = word_s.upper()

        # Ignore unknown/uninitialized words such as xxxxxxxx.
        if "X" in word_s or "Z" in word_s:
            continue

        if len(word_s) > 8:
            raise ValueError(f"Line {line_no}: word wider than 32 bits: {word_s}")

        addr = int(addr_s, 16)
        word = word_s.zfill(8)

        words.append((addr, word))

    if not words:
        raise ValueError(f"No valid 32-bit SLM words found in {path}")

    return words


def split_word_16bit_low_high(word: str) -> List[str]:
    word = word.upper().zfill(8)
    high = word[0:4]
    low = word[4:8]
    return [low, high]


def extract_16bit_matrix_from_first_words(
    words: List[Tuple[int, str]],
    rows: int,
    cols: int,
) -> List[List[str]]:
    needed_elements = rows * cols
    needed_words = (needed_elements + 1) // 2

    if len(words) < needed_words:
        raise ValueError(
            f"Not enough SLM words for {rows}x{cols} 16-bit matrix: "
            f"found {len(words)}, need {needed_words}"
        )

    elements: List[str] = []
    for _, word in words[:needed_words]:
        elements.extend(split_word_16bit_low_high(word))

    elements = elements[:needed_elements]

    return [elements[r * cols : (r + 1) * cols] for r in range(rows)]


def split_word_8bit_little_endian(word: str) -> List[str]:
    word = word.upper().zfill(8)
    # Memory order is low byte first.
    return [word[6:8], word[4:6], word[2:4], word[0:2]]


def extract_8bit_matrix_from_first_words(
    words: List[Tuple[int, str]],
    rows: int,
    cols: int,
) -> List[List[str]]:
    needed_elements = rows * cols
    needed_words = (needed_elements + 3) // 4

    if len(words) < needed_words:
        raise ValueError(
            f"Not enough SLM words for {rows}x{cols} 8-bit matrix: "
            f"found {len(words)}, need {needed_words}"
        )

    elements: List[str] = []
    for _, word in words[:needed_words]:
        elements.extend(split_word_8bit_little_endian(word))

    elements = elements[:needed_elements]

    return [elements[r * cols : (r + 1) * cols] for r in range(rows)]


def extract_32bit_matrix_from_first_words(
    words: List[Tuple[int, str]],
    rows: int,
    cols: int,
) -> List[List[str]]:
    needed_elements = rows * cols

    if len(words) < needed_elements:
        raise ValueError(
            f"Not enough SLM words for {rows}x{cols} 32-bit matrix: "
            f"found {len(words)}, need {needed_elements}"
        )

    elements = [word.upper().zfill(8) for _, word in words[:needed_elements]]

    return [elements[r * cols : (r + 1) * cols] for r in range(rows)]


def write_matrix(path: Path, matrix: List[List[str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(" ".join(row) for row in matrix) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract Klessydra D matrix from final_touched_words.slm.")
    parser.add_argument("--format", required=True, choices=["fp16", "posit16", "lns16", "fp8", "posit8", "fp32", "posit32", "fxp8_16", "fxp16_32", "int8_16"])
    parser.add_argument("--input", required=True, type=Path, help="Path to final_touched_words.slm")
    parser.add_argument("--output", required=True, type=Path, help="Output plain matrix file")
    parser.add_argument("--rows", type=int, default=16)
    parser.add_argument("--cols", type=int, default=16)
    args = parser.parse_args()

    words = parse_slm_words(args.input)

    if args.format in {"fp16", "posit16", "lns16", "fxp8_16", "int8_16"}:
        matrix = extract_16bit_matrix_from_first_words(words, args.rows, args.cols)
    elif args.format in {"fp8", "posit8"}:
        matrix = extract_8bit_matrix_from_first_words(words, args.rows, args.cols)
    elif args.format in {"fp32", "posit32", "fxp16_32"}:
        matrix = extract_32bit_matrix_from_first_words(words, args.rows, args.cols)
    else:
        raise NotImplementedError(args.format)

    write_matrix(args.output, matrix)

    print("Extracted Klessydra D matrix.")
    print(f"Format:        {args.format}")
    print(f"Input SLM:     {args.input}")
    print(f"Output matrix: {args.output}")
    print(f"Matrix shape:  {args.rows}x{args.cols}")
    print(f"SLM words read:{len(words)}")
    print("First output row:")
    print(" ".join(matrix[0]))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
