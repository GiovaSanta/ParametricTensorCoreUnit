#!/usr/bin/env python3
import argparse
import csv
from pathlib import Path

LABELS = [
    "A0", "A1", "A2", "A3",
    "B0", "B1", "B2", "B3",
    "C0",
]

INPUT_WIDTH = 16
INPUT_FRAC_BITS = 10
ACC_WIDTH = 32
ACC_FRAC_BITS = 20

INPUT_MIN_RAW = -(1 << (INPUT_WIDTH - 1))
INPUT_MAX_RAW = (1 << (INPUT_WIDTH - 1)) - 1
ACC_MIN_RAW = -(1 << (ACC_WIDTH - 1))
ACC_MAX_RAW = (1 << (ACC_WIDTH - 1)) - 1


def clamp(value: int, minimum: int, maximum: int) -> int:
    return max(minimum, min(maximum, int(value)))


def quantize_signed_fixed(
    value: float,
    width: int,
    fractional_bits: int,
):
    minimum = -(1 << (width - 1))
    maximum = (1 << (width - 1)) - 1

    signed_raw = clamp(
        round(value * (1 << fractional_bits)),
        minimum,
        maximum,
    )
    encoded = signed_raw & ((1 << width) - 1)
    decoded = signed_raw / float(1 << fractional_bits)

    return signed_raw, encoded, decoded


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
            "script is run from 100vectors/fxp16_32/."
        ),
    )
    parser.add_argument(
        "--output-dir",
        default="generated_fxp16_32_vectors_100",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    vectors = read_real_vectors(input_path)

    encoded_path = output_dir / "fxp16_32_vectors.txt"
    report_path = output_dir / "fxp16_32_report.csv"
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
            "width_bits",
            "fraction_bits",
            "original",
            "signed_raw",
            "encoded_hex",
            "decoded_fixed",
            "quantization_error",
        ])

        for vector_id, real_values in enumerate(vectors):
            encoded_tokens = []

            audit_file.write(
                " ".join(f"{value:.10f}" for value in real_values)
                + "\n"
            )

            for operand_index, (label, value) in enumerate(
                zip(LABELS, real_values)
            ):
                if operand_index < 8:
                    width = INPUT_WIDTH
                    fractional_bits = INPUT_FRAC_BITS
                    hex_digits = 4
                else:
                    width = ACC_WIDTH
                    fractional_bits = ACC_FRAC_BITS
                    hex_digits = 8

                signed_raw, encoded, decoded = quantize_signed_fixed(
                    value,
                    width,
                    fractional_bits,
                )

                encoded_tokens.append(
                    f"{encoded:0{hex_digits}X}"
                )

                writer.writerow([
                    vector_id,
                    label,
                    width,
                    fractional_bits,
                    f"{value:.10f}",
                    signed_raw,
                    f"{encoded:0{hex_digits}X}",
                    f"{decoded:.12g}",
                    f"{decoded - value:.12g}",
                ])

            encoded_file.write(
                " ".join(encoded_tokens) + "\n"
            )

    print(f"Source vectors:     {len(vectors)}")
    print("A/B format:         signed_5_M10, 16 bits")
    print("C/R format:         signed_11_M20, 32 bits")
    print(f"Operand order:      {' '.join(LABELS)}")
    print(f"Input real vectors: {input_path}")
    print(f"FXP16_32 vectors:   {encoded_path}")
    print(f"Report:             {report_path}")
    print(f"Audit copy:         {audit_path}")


if __name__ == "__main__":
    main()
