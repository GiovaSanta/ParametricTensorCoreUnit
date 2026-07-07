#!/usr/bin/env python3

import csv
from pathlib import Path


FAULT_ROOT = Path(__file__).resolve().parents[1]

GOLDEN_FILE = (
    FAULT_ROOT
    / "results"
    / "fp16_golden_outputs"
    / "fp16_golden_100.txt"
)

FAULT_OUTPUT_DIR = (
    FAULT_ROOT
    / "results"
    / "fp16_fault_outputs"
)

RESULT_CSV = (
    FAULT_ROOT
    / "results"
    / "fp16_output_fault_results_v0.csv"
)

SUMMARY_CSV = (
    FAULT_ROOT
    / "results"
    / "fp16_output_fault_summary_v0.csv"
)


def read_hex_lines(path: Path) -> list[str]:
    with path.open("r", encoding="utf-8") as f:
        return [line.strip().upper() for line in f if line.strip()]


def main() -> None:
    vector_id = 0
    target_id = 0
    target_name = "R"

    golden = read_hex_lines(GOLDEN_FILE)

    rows = []

    for bit_id in range(16):
        fault_file = (
            FAULT_OUTPUT_DIR
            / f"fp16_fault_v{vector_id}_t{target_id}_b{bit_id}.txt"
        )

        if not fault_file.exists():
            raise FileNotFoundError(f"Missing fault file: {fault_file}")

        faulty = read_hex_lines(fault_file)

        golden_hex = golden[vector_id]
        faulty_hex = faulty[vector_id]

        xor_value = int(golden_hex, 16) ^ int(faulty_hex, 16)

        if golden_hex == faulty_hex:
            classification = "ND"
        else:
            classification = "SDC"

        rows.append(
            {
                "fault_id": len(rows),
                "format": "FP16",
                "target_id": target_id,
                "target_name": target_name,
                "vector_id": vector_id,
                "bit_id": bit_id,
                "golden_hex": golden_hex,
                "faulty_hex": faulty_hex,
                "xor_hex": f"{xor_value:04X}",
                "classification": classification,
            }
        )

    RESULT_CSV.parent.mkdir(parents=True, exist_ok=True)

    with RESULT_CSV.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "fault_id",
                "format",
                "target_id",
                "target_name",
                "vector_id",
                "bit_id",
                "golden_hex",
                "faulty_hex",
                "xor_hex",
                "classification",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)

    total = len(rows)
    nd = sum(1 for r in rows if r["classification"] == "ND")
    sdc = sum(1 for r in rows if r["classification"] == "SDC")

    with SUMMARY_CSV.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "format",
                "target_name",
                "vector_id",
                "total_faults",
                "ND",
                "SDC",
                "ND_percent",
                "SDC_percent",
            ],
        )
        writer.writeheader()
        writer.writerow(
            {
                "format": "FP16",
                "target_name": target_name,
                "vector_id": vector_id,
                "total_faults": total,
                "ND": nd,
                "SDC": sdc,
                "ND_percent": 100.0 * nd / total,
                "SDC_percent": 100.0 * sdc / total,
            }
        )

    print(f"Wrote detailed results: {RESULT_CSV}")
    print(f"Wrote summary:          {SUMMARY_CSV}")


if __name__ == "__main__":
    main()