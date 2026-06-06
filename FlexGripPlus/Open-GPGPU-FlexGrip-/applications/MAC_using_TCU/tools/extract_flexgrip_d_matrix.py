#!/usr/bin/env python3
"""
Extract a 16x16 hardware D matrix from a FlexGrip Plus gpgpu_rdata.log file.

The FlexGrip output log stores memory words like:
    00600 C4B8C54E

For 16-bit output elements:
    C4B8C54E -> C54E C4B8

For 8-bit output elements:
    AABBCCDD -> DD CC BB AA

For 32-bit output elements:
    AABBCCDD -> AABBCCDD

Default:
    start address = 0x600
    matrix shape  = 16x16
    element bits  = 16

Typical usage:
    python tools/extract_flexgrip_d_matrix.py \
        --input fp16operands/gpgpu_rdata.log \
        --output fp16operands/hw_D_matrix_extracted.txt

FP8 usage:
    python tools/extract_flexgrip_d_matrix.py \
        --input fp8e4m3eoperands/gpgpu_rdata.log \
        --output fp8e4m3eoperands/hw_D_matrix_extracted.txt \
        --element-bits 8
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Dict, List


LOG_LINE_RE = re.compile(r"^\s*([0-9A-Fa-f]+)\s+([0-9A-Fa-f]{8})\s*$")


def parse_address(value: str) -> int:
    text = value.strip()

    if text.startswith("@"):
        text = text[1:]

    if text.lower().startswith("0x"):
        return int(text, 16)

    return int(text, 16)


def parse_gpgpu_rdata_log(path: Path) -> Dict[int, str]:
    memory: Dict[int, str] = {}

    with path.open("r", encoding="utf-8") as f:
        for line_no, line in enumerate(f, start=1):
            stripped = line.strip()

            if not stripped:
                continue

            match = LOG_LINE_RE.fullmatch(stripped)

            if not match:
                raise ValueError(
                    f"Invalid gpgpu_rdata.log line {line_no}: {line.rstrip()!r}"
                )

            addr_text, word_text = match.groups()
            address = parse_address(addr_text)
            memory[address] = word_text.upper()

    return memory


def split_32bit_word(word_hex: str, element_bits: int) -> List[str]:
    word = word_hex.upper().zfill(8)

    if element_bits == 16:
        high16 = word[0:4]
        low16 = word[4:8]
        return [low16, high16]

    if element_bits == 8:
        b3 = word[0:2]
        b2 = word[2:4]
        b1 = word[4:6]
        b0 = word[6:8]
        return [b0, b1, b2, b3]

    if element_bits == 32:
        return [word]

    raise ValueError("Only --element-bits 8, 16, or 32 are supported.")


def extract_matrix_words(
    memory: Dict[int, str],
    start_addr: int,
    rows: int,
    cols: int,
    address_stride: int,
    element_bits: int,
) -> List[str]:
    needed_elements = rows * cols
    elements_per_32bit_word = 32 // element_bits

    if 32 % element_bits != 0:
        raise ValueError("element_bits must divide 32.")

    if needed_elements % elements_per_32bit_word != 0:
        raise ValueError(
            "This extractor expects the matrix element count to be an integer "
            "number of 32-bit words."
        )

    needed_32bit_words = needed_elements // elements_per_32bit_word

    extracted: List[str] = []

    for i in range(needed_32bit_words):
        address = start_addr + i * address_stride

        if address not in memory:
            raise KeyError(
                f"Missing expected address 0x{address:X} in gpgpu_rdata.log"
            )

        extracted.extend(split_32bit_word(memory[address], element_bits))

    if len(extracted) != needed_elements:
        raise RuntimeError(
            f"Internal extraction error: got {len(extracted)} elements, "
            f"expected {needed_elements}"
        )

    return extracted


def words_to_matrix_lines(words: List[str], rows: int, cols: int) -> List[str]:
    lines: List[str] = []

    for r in range(rows):
        row = words[r * cols : (r + 1) * cols]
        lines.append(" ".join(row))

    return lines


def write_matrix(path: Path, matrix_lines: List[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(matrix_lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Extract an encoded D matrix from FlexGrip Plus gpgpu_rdata.log."
    )

    parser.add_argument("-i", "--input", required=True, type=Path, help="Input gpgpu_rdata.log file.")
    parser.add_argument("-o", "--output", required=True, type=Path, help="Output matrix text file.")
    parser.add_argument("--start-addr", default="0x600", help="Start address of D matrix. Default: 0x600.")
    parser.add_argument("--rows", type=int, default=16, help="Matrix rows. Default: 16.")
    parser.add_argument("--cols", type=int, default=16, help="Matrix columns. Default: 16.")
    parser.add_argument("--address-stride", type=int, default=4, help="Address step between 32-bit words. Default: 4.")
    parser.add_argument("--element-bits", type=int, choices=[8, 16, 32], default=16, help="Matrix element width. Default: 16.")

    args = parser.parse_args()

    start_addr = parse_address(args.start_addr)

    memory = parse_gpgpu_rdata_log(args.input)

    extracted_words = extract_matrix_words(
        memory=memory,
        start_addr=start_addr,
        rows=args.rows,
        cols=args.cols,
        address_stride=args.address_stride,
        element_bits=args.element_bits,
    )

    matrix_lines = words_to_matrix_lines(extracted_words, args.rows, args.cols)
    write_matrix(args.output, matrix_lines)

    print("Extracted FlexGrip Plus hardware D matrix.")
    print(f"Input log:      {args.input}")
    print(f"Output matrix:  {args.output}")
    print(f"Start address:  0x{start_addr:X}")
    print(f"Matrix shape:   {args.rows}x{args.cols}")
    print(f"Element bits:   {args.element_bits}")
    print(f"Elements:       {args.rows * args.cols}")
    print(f"32-bit words:   {(args.rows * args.cols) // (32 // args.element_bits)}")
    print()
    print("First output row:")
    print(matrix_lines[0])

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
