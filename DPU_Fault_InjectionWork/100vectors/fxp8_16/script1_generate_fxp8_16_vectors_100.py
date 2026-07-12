#!/usr/bin/env python3
import argparse
import csv
from pathlib import Path

LABELS = [
    "A0", "A1", "A2", "A3",
    "B0", "B1", "B2", "B3",
    "C0",
]

FXP8_FRAC_BITS = 5
FXP16_FRAC_BITS = 10

FXP8_MIN_RAW = -128
FXP8_MAX_RAW = 127
FXP16_MIN_RAW = -32768
FXP16_MAX_RAW = 32767


def clamp(value: int, minimum: int, maximum: int) -> int:
    return max(minimum, min(maximum, int(value)))


def quantize_fxp8(value: float):
    raw = clamp(
        round(value * (1 << FXP8_FRAC_BITS)),
        FXP8_MIN_RAW,
        FXP8_MAX_RAW,
    )
    decoded = raw / float(1 << FXP8_FRAC_BITS)
    encoded = raw & 0xFF
    return raw, encoded, decoded


def quantize_fxp16(value: float):
    raw = clamp(
        round(value * (1 << FXP16_FRAC_BITS)),
        FXP16_MIN_RAW,
        FXP16_MAX_RAW,
    )
    decoded = raw / float(1 << FXP16_FRAC_BITS)
    encoded = raw & 0xFFFF
    return raw, encoded, decoded


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
            "Common source real vectors. Default assumes this script "
            "is inside 100vectors/fxp8_16/."
        ),
    )
    parser.add_argument(
        "--output-dir",
        default="generated_fxp8_16_vectors_100",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    vectors = read_real_vectors(input_path)

    encoded_path = output_dir / "fxp8_16_vectors.txt"
    report_path = output_dir / "fxp8_16_report.csv"
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
                    raw, encoded, decoded = quantize_fxp8(value)
                    encoded_tokens.append(f"{encoded:02X}")
                    width_bits = 8
                    fraction_bits = FXP8_FRAC_BITS
                    encoded_hex = f"{encoded:02X}"
                else:
                    raw, encoded, decoded = quantize_fxp16(value)
                    encoded_tokens.append(f"{encoded:04X}")
                    width_bits = 16
                    fraction_bits = FXP16_FRAC_BITS
                    encoded_hex = f"{encoded:04X}"

                writer.writerow([
                    vector_id,
                    label,
                    width_bits,
                    fraction_bits,
                    f"{value:.10f}",
                    raw,
                    encoded_hex,
                    f"{decoded:.12g}",
                    f"{decoded - value:.12g}",
                ])

            encoded_file.write(
                " ".join(encoded_tokens) + "\n"
            )

    print(f"Source vectors:     {len(vectors)}")
    print("Format:")
    print("  A/B: signed_2_M5, 8-bit, 5 fractional bits")
    print("  C/R: signed_5_M10, 16-bit, 10 fractional bits")
    print(f"Operand order:      {' '.join(LABELS)}")
    print(f"Input real vectors: {input_path}")
    print(f"Encoded vectors:    {encoded_path}")
    print(f"Report:             {report_path}")
    print(f"Audit copy:         {audit_path}")


if __name__ == "__main__":
    main()
