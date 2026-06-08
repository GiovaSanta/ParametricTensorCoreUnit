#!/usr/bin/env python3
"""
Patch Klessydra TCUopFIXED16_32.c from a generated 16x16 FXP16_32 experiment file.

Expected experiment file sections:
    #FULL_A_16x16 encoded                                  -> 16-bit A
    #FULL_B_16x16 encoded                                  -> 16-bit B
    #FULL_C_16x16 encoded                                  -> 32-bit C
    #FULL_D_16x16_full_precision_real_reference_rounded_fxp32 encoded
       preferred golden D reference for validation/reporting
    fallback:
    #FULL_D_16x16_one_shot_reference encoded

Klessydra FXP16_32 C benchmark convention:
    A   is 16-bit and stored row-major.
    B_T is 16-bit and stored as B transpose.
    C   is 32-bit and stored row-major.
    D   is 32-bit, zero-initialized, and filled by the HMMA assembly code.

This patcher detects the actual declaration prefix of A, B_T, C, and D,
so it handles fixed16_t / fixed32_t / volatile spacing robustly.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import List


HEX16_RE = re.compile(r"^[0-9A-Fa-f]{1,4}$")
HEX32_RE = re.compile(r"^[0-9A-Fa-f]{1,8}$")


PREFERRED_D_LABEL = "#FULL_D_16x16_full_precision_real_reference_rounded_fxp32 encoded"
FALLBACK_D_LABEL = "#FULL_D_16x16_one_shot_reference encoded"


def normalize_hex(token: str, bits: int) -> str:
    token = token.strip()

    if bits == 16:
        if not HEX16_RE.fullmatch(token):
            raise ValueError(f"Invalid 16-bit hex token: {token!r}")
        return "0x" + token.upper().zfill(4)

    if bits == 32:
        if not HEX32_RE.fullmatch(token):
            raise ValueError(f"Invalid 32-bit hex token: {token!r}")
        return "0x" + token.upper().zfill(8)

    raise ValueError(f"Unsupported bit width: {bits}")


def find_section_line(lines: list[str], label: str) -> int:
    wanted = label.strip().lower()
    for idx, line in enumerate(lines):
        if line.strip().lower() == wanted:
            return idx
    raise ValueError(f"Could not find section label: {label}")


def section_exists(path: Path, label: str) -> bool:
    wanted = label.strip().lower()
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip().lower() == wanted:
            return True
    return False


def read_matrix_after_section(
    path: Path,
    label: str,
    bits: int,
    rows: int = 16,
    cols: int = 16,
) -> List[List[str]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    start = find_section_line(lines, label) + 1

    tokens: list[str] = []
    needed = rows * cols

    for raw in lines[start:]:
        stripped = raw.strip()
        if not stripped:
            continue

        if stripped.startswith("#"):
            if tokens:
                break
            continue

        for tok in stripped.split():
            tokens.append(normalize_hex(tok, bits))

        if len(tokens) >= needed:
            break

    if len(tokens) != needed:
        raise ValueError(f"Section {label!r} has {len(tokens)} values; expected {needed}.")

    return [tokens[r * cols:(r + 1) * cols] for r in range(rows)]


def transpose_matrix(m: List[List[str]]) -> List[List[str]]:
    return [list(row) for row in zip(*m)]


def zeros_matrix(bits: int, rows: int = 16, cols: int = 16) -> List[List[str]]:
    zero = "0x0000" if bits == 16 else "0x00000000"
    return [[zero for _ in range(cols)] for _ in range(rows)]


def find_declaration_prefix(source: str, name: str) -> str:
    pattern = re.compile(
        rf"(?m)^\s*((?:volatile\s+)?[A-Za-z_][A-Za-z0-9_]*\s+){re.escape(name)}\s*\["
    )
    match = pattern.search(source)
    if not match:
        raise RuntimeError(f"Could not find declaration prefix for array {name}")
    return match.group(1).strip()


def c_matrix_initializer(prefix: str, name: str, dims: str, matrix: List[List[str]], comment: str = "") -> str:
    comment_part = f" {comment}" if comment else ""
    out: list[str] = []
    out.append(f"{prefix} {name}{dims} = {{{comment_part}")
    out.append("")
    for r, row in enumerate(matrix):
        comma = "," if r != len(matrix) - 1 else ""
        out.append("    { " + ", ".join(row) + f" }}{comma}")
        out.append("")
    out.append("};")
    return "\n".join(out)


def replace_c_array(source: str, name: str, replacement: str) -> str:
    pattern = re.compile(
        rf"(?m)^\s*(?:volatile\s+)?[A-Za-z_][A-Za-z0-9_]*\s+"
        rf"{re.escape(name)}\s*\[[^\]]+\]\s*\[[^\]]+\]\s*=\s*\{{.*?\n\s*\}};",
        re.DOTALL,
    )

    new_source, count = pattern.subn(replacement, source, count=1)
    if count != 1:
        raise RuntimeError(f"Could not replace C array {name}; matches found: {count}")

    return new_source


def write_plain_matrix(path: Path, matrix: List[List[str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    clean = [[v[2:].upper() if v.startswith("0x") else v.upper() for v in row] for row in matrix]
    path.write_text("\n".join(" ".join(row) for row in clean) + "\n", encoding="utf-8")


def choose_golden_d_label(experiment_file: Path) -> str:
    if section_exists(experiment_file, PREFERRED_D_LABEL):
        return PREFERRED_D_LABEL
    if section_exists(experiment_file, FALLBACK_D_LABEL):
        return FALLBACK_D_LABEL
    raise ValueError(
        "Could not find a usable D golden section. Tried:\n"
        f"  {PREFERRED_D_LABEL}\n"
        f"  {FALLBACK_D_LABEL}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Patch Klessydra FXP16_32 C matrices from generated experiment.")
    parser.add_argument("--experiment-file", required=True, type=Path)
    parser.add_argument("--c-file", required=True, type=Path)
    parser.add_argument("--output-c-file", type=Path, default=None,
                        help="Optional output C file. Default: patch --c-file in place.")
    parser.add_argument("--golden-out", type=Path, default=None,
                        help="Optional output plain 16x16 golden D matrix file.")
    parser.add_argument("--backup", action="store_true",
                        help="Create a .bak copy of the original C file before overwriting in place.")
    args = parser.parse_args()

    A = read_matrix_after_section(args.experiment_file, "#FULL_A_16x16 encoded", bits=16)
    B = read_matrix_after_section(args.experiment_file, "#FULL_B_16x16 encoded", bits=16)
    C = read_matrix_after_section(args.experiment_file, "#FULL_C_16x16 encoded", bits=32)

    d_label = choose_golden_d_label(args.experiment_file)
    D_golden = read_matrix_after_section(args.experiment_file, d_label, bits=32)

    B_T = transpose_matrix(B)
    D_zero = zeros_matrix(bits=32)

    source = args.c_file.read_text(encoding="utf-8")

    prefix_A = find_declaration_prefix(source, "A")
    prefix_B = find_declaration_prefix(source, "B_T")
    prefix_C = find_declaration_prefix(source, "C")
    prefix_D = find_declaration_prefix(source, "D")

    source = replace_c_array(
        source,
        "A",
        c_matrix_initializer(prefix_A, "A", "[N_ROW_1][N_COL_1]", A, "//A is stored in row major layout"),
    )

    source = replace_c_array(
        source,
        "B_T",
        c_matrix_initializer(prefix_B, "B_T", "[N_COL_2][N_COL_1]", B_T, "//B is stored in column major layout in memory (so this below is B transpose)"),
    )

    source = replace_c_array(
        source,
        "C",
        c_matrix_initializer(prefix_C, "C", "[N_ROW_1][N_COL_2]", C, "// C is stored in row major layout in memory"),
    )

    source = replace_c_array(
        source,
        "D",
        c_matrix_initializer(prefix_D, "D", "[N_ROW_1][N_COL_2]", D_zero, "// D is stored in row-major layout in memory"),
    )

    out_c = args.output_c_file or args.c_file

    if args.output_c_file is None and args.backup:
        backup_path = args.c_file.with_suffix(args.c_file.suffix + ".bak")
        backup_path.write_text(args.c_file.read_text(encoding="utf-8"), encoding="utf-8")
        print(f"Backup written: {backup_path}")

    out_c.write_text(source, encoding="utf-8")

    print("Patched Klessydra FXP16_32 C matrices.")
    print(f"Experiment file: {args.experiment_file}")
    print(f"C file written:  {out_c}")
    print(f"A declaration:   {prefix_A}")
    print(f"B_T declaration: {prefix_B}")
    print(f"C declaration:   {prefix_C}")
    print(f"D declaration:   {prefix_D}")
    print(f"Golden D label:  {d_label}")
    print("A:   16-bit row-major")
    print("B_T: 16-bit transpose of FULL_B_16x16")
    print("C:   32-bit row-major")
    print("D:   32-bit zero-initialized")

    if args.golden_out is not None:
        write_plain_matrix(args.golden_out, D_golden)
        print(f"Golden D matrix written: {args.golden_out}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
