#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import argparse
import csv
import re


ORDER = [
    "fp8",
    "fp16",
    "fp32",
    "posit8",
    "posit16",
    "posit32",
    "lns16",
    "fxp8_16",
    "fxp16_32",
    "int8_16",
    "int16_32",
]


def grab(text: str, label: str, default: str = "") -> str:
    pattern = rf"^{re.escape(label)}:\s*(.+?)\s*$"
    match = re.search(pattern, text, re.MULTILINE)
    return match.group(1).strip() if match else default


def parse_report(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")

    fmt = grab(text, "Format")
    exact_matches_raw = grab(text, "Exact encoded matches")
    exact_matches = ""
    total_from_exact = ""

    if "/" in exact_matches_raw:
        left, right = exact_matches_raw.split("/", 1)
        exact_matches = left.strip()
        total_from_exact = right.strip()

    encoded_result = grab(text, "Encoded result")
    decoded_result = grab(text, "Decoded-real result")

    if encoded_result == "EXACT MATCH" and decoded_result == "ZERO ERROR":
        status = "Exact"
    else:
        status = "Validated, nonzero numerical error"

    return {
        "format": fmt,
        "folder": path.parent.name,
        "total_elements": grab(text, "Total elements", total_from_exact),
        "exact_encoded_matches": exact_matches,
        "exact_encoded_match_percent": grab(text, "Exact encoded match %"),
        "encoded_mismatches": grab(text, "Encoded mismatches"),
        "mean_absolute_error": grab(text, "Mean absolute error"),
        "max_absolute_error": grab(text, "Max absolute error"),
        "rmse": grab(text, "RMSE"),
        "mean_relative_error": grab(text, "Mean relative error"),
        "max_relative_error": grab(text, "Max relative error"),
        "infinite_relative_errors": grab(text, "Infinite relative errors"),
        "nan_related_error_rows": grab(text, "NaN-related error rows"),
        "encoded_result": encoded_result,
        "decoded_real_result": decoded_result,
        "status": status,
        "report_path": str(path),
    }


def sort_key(row: dict) -> tuple:
    fmt = row["format"]
    try:
        return (ORDER.index(fmt), fmt)
    except ValueError:
        return (999, fmt)


def write_markdown(rows: list[dict], path: Path) -> None:
    headers = [
        "Format",
        "Exact match %",
        "Mean abs error",
        "Max abs error",
        "RMSE",
        "Mean rel error",
        "Max rel error",
        "Status",
    ]

    lines = []
    lines.append("# Klessydra TCU automated validation summary")
    lines.append("")
    lines.append("| " + " | ".join(headers) + " |")
    lines.append("| " + " | ".join(["---"] * len(headers)) + " |")

    for r in rows:
        lines.append(
            "| "
            + " | ".join(
                [
                    r["format"],
                    r["exact_encoded_match_percent"],
                    r["mean_absolute_error"],
                    r["max_absolute_error"],
                    r["rmse"],
                    r["mean_relative_error"],
                    r["max_relative_error"],
                    r["status"],
                ]
            )
            + " |"
        )

    lines.append("")
    lines.append("Generated from the per-format `validation_report.txt` files.")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        type=Path,
        default=Path("pulpino-klessydra/sw/apps/klessydra_tests/klessydra_tcu_tests"),
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path("pulpino-klessydra/sw/apps/klessydra_tests/klessydra_tcu_tests/validation_summary"),
    )
    args = parser.parse_args()

    reports = sorted(args.root.glob("TCUop*/validation_report.txt"))
    rows = [parse_report(path) for path in reports]
    rows = sorted(rows, key=sort_key)

    args.out_dir.mkdir(parents=True, exist_ok=True)

    csv_path = args.out_dir / "klessydra_validation_summary.csv"
    md_path = args.out_dir / "klessydra_validation_summary.md"

    fieldnames = [
        "format",
        "folder",
        "total_elements",
        "exact_encoded_matches",
        "exact_encoded_match_percent",
        "encoded_mismatches",
        "mean_absolute_error",
        "max_absolute_error",
        "rmse",
        "mean_relative_error",
        "max_relative_error",
        "infinite_relative_errors",
        "nan_related_error_rows",
        "encoded_result",
        "decoded_real_result",
        "status",
        "report_path",
    ]

    with csv_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    write_markdown(rows, md_path)

    print(f"Reports found: {len(rows)}")
    print(f"CSV written:   {csv_path}")
    print(f"MD written:    {md_path}")
    print()
    print(md_path.read_text(encoding="utf-8"))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
