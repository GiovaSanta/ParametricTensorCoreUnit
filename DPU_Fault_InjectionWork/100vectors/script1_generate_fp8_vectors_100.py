#!/usr/bin/env python3
import argparse
import csv
import random
from pathlib import Path

LABELS = [
    "A0", "A1", "A2", "A3",
    "B0", "B1", "B2", "B3",
    "C0",
]


def decode_e4m3(raw):
    sign = -1.0 if raw & 0x80 else 1.0
    exponent = (raw >> 3) & 0x0F
    fraction = raw & 0x07

    if exponent == 0:
        value = (fraction / 8.0) * (2.0 ** -6)
    elif exponent == 0x0F:
        return None
    else:
        value = (
            1.0 + fraction / 8.0
        ) * (2.0 ** (exponent - 7))

    return sign * value


def build_fp8_table():
    values = {}

    for raw in range(256):
        decoded = decode_e4m3(raw)

        if decoded is not None and -1.0 <= decoded <= 1.0:
            values.setdefault(decoded, raw)

    values[0.0] = 0x00
    return [(decoded, raw) for decoded, raw in values.items()]


FP8_TABLE = build_fp8_table()


def quantize_to_fp8(value):
    decoded, raw = min(
        FP8_TABLE,
        key=lambda item: (
            abs(item[0] - value),
            abs(item[0]),
            item[1],
        ),
    )
    return raw, decoded


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--num-vectors", type=int, default=100)
    parser.add_argument(
        "--output-dir",
        default="generated_fp8_vectors_100",
    )
    args = parser.parse_args()

    if args.num_vectors <= 0:
        raise ValueError("--num-vectors must be positive.")

    rng = random.Random(args.seed)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    real_txt_path = output_dir / "real_vectors.txt"
    real_csv_path = output_dir / "real_vectors.csv"
    fp8_path = output_dir / "fp8_vectors.txt"
    report_path = output_dir / "fp8_report.csv"

    with real_txt_path.open(
        "w", encoding="utf-8"
    ) as real_txt, real_csv_path.open(
        "w", newline="", encoding="utf-8"
    ) as real_csv, fp8_path.open(
        "w", encoding="utf-8"
    ) as fp8_file, report_path.open(
        "w", newline="", encoding="utf-8"
    ) as report_file:

        real_writer = csv.DictWriter(
            real_csv,
            fieldnames=["vector_id", *LABELS],
        )
        real_writer.writeheader()

        report_writer = csv.writer(report_file)
        report_writer.writerow([
            "vector_id",
            "label",
            "original",
            "fp8_hex",
            "decoded_fp8",
            "quantization_error",
        ])

        for vector_id in range(args.num_vectors):
            real_values = [
                rng.uniform(-1.0, 1.0)
                for _ in LABELS
            ]

            encoded = []
            real_row = {"vector_id": vector_id}

            for label, value in zip(LABELS, real_values):
                raw, decoded = quantize_to_fp8(value)
                encoded.append(raw)
                real_row[label] = f"{value:.10f}"

                report_writer.writerow([
                    vector_id,
                    label,
                    f"{value:.10f}",
                    f"{raw:02X}",
                    f"{decoded:.12g}",
                    f"{decoded - value:.12g}",
                ])

            real_writer.writerow(real_row)

            real_txt.write(
                " ".join(
                    f"{value:.10f}" for value in real_values
                )
                + "\n"
            )

            fp8_file.write(
                " ".join(f"{raw:02X}" for raw in encoded)
                + "\n"
            )

    print(f"Generated vectors: {args.num_vectors}")
    print(f"Seed:              {args.seed}")
    print(f"Operand order:     {' '.join(LABELS)}")
    print(f"Real vectors:      {real_txt_path}")
    print(f"FP8 vectors:       {fp8_path}")
    print(f"Report:            {report_path}")


if __name__ == "__main__":
    main()
