#!/usr/bin/env python3
import argparse
import csv
import struct
from pathlib import Path

LABELS = [
    "A0", "A1", "A2", "A3",
    "B0", "B1", "B2", "B3",
    "C0",
]


def float_to_fp16_raw(value: float) -> int:
    """Quantize a Python float to IEEE-754 binary16."""
    packed = struct.pack(">e", value)
    return int.from_bytes(packed, byteorder="big", signed=False)


def fp16_raw_to_float(raw: int) -> float:
    packed = int(raw).to_bytes(2, byteorder="big", signed=False)
    return struct.unpack(">e", packed)[0]


def read_real_vectors(path: Path):
    vectors = []

    for line_number, line in enumerate(
        path.read_text(encoding="utf-8").splitlines(),
        start=1,
    ):
        line = line.strip()

        if not line or line.startswith("#"):
            continue

        tokens = line.split()

        if len(tokens) != len(LABELS):
            raise ValueError(
                f"{path}, line {line_number}: expected "
                f"{len(LABELS)} real operands, found {len(tokens)}."
            )

        try:
            values = [float(token) for token in tokens]
        except ValueError as error:
            raise ValueError(
                f"{path}, line {line_number}: invalid real operand."
            ) from error

        vectors.append(values)

    if not vectors:
        raise ValueError(f"No vectors found in {path}.")

    return vectors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        default="../generated_fp8_vectors_100/real_vectors.txt",
        help=(
            "Common source real vectors. The default assumes this "
            "script is run from 100vectors/fp16/."
        ),
    )
    parser.add_argument(
        "--output-dir",
        default="generated_fp16_vectors_100",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    vectors = read_real_vectors(input_path)

    encoded_path = output_dir / "fp16_vectors.txt"
    report_path = output_dir / "fp16_report.csv"
    audit_path = output_dir / "real_vectors.txt"

    with encoded_path.open(
        "w", encoding="utf-8"
    ) as encoded_file, report_path.open(
        "w", newline="", encoding="utf-8"
    ) as report_file, audit_path.open(
        "w", encoding="utf-8"
    ) as audit_file:

        writer = csv.writer(report_file)
        writer.writerow([
            "vector_id",
            "label",
            "original",
            "fp16_hex",
            "decoded_fp16",
            "quantization_error",
        ])

        for vector_id, real_values in enumerate(vectors):
            encoded_tokens = []

            audit_file.write(
                " ".join(f"{value:.10f}" for value in real_values)
                + "\n"
            )

            for label, value in zip(LABELS, real_values):
                raw = float_to_fp16_raw(value)
                decoded = fp16_raw_to_float(raw)
                encoded_tokens.append(f"{raw:04X}")

                writer.writerow([
                    vector_id,
                    label,
                    f"{value:.10f}",
                    f"{raw:04X}",
                    f"{decoded:.12g}",
                    f"{decoded - value:.12g}",
                ])

            encoded_file.write(
                " ".join(encoded_tokens) + "\n"
            )

    print(f"Source vectors:     {len(vectors)}")
    print("Format:             IEEE-754 binary16")
    print(f"Operand order:      {' '.join(LABELS)}")
    print(f"Input real vectors: {input_path}")
    print(f"FP16 vectors:       {encoded_path}")
    print(f"Report:             {report_path}")
    print(f"Audit copy:         {audit_path}")


if __name__ == "__main__":
    main()
