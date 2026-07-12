#!/usr/bin/env python3
import argparse
import csv
from fractions import Fraction
from pathlib import Path

LABELS = [
    "A0", "A1", "A2", "A3",
    "B0", "B1", "B2", "B3",
    "C0",
]


def twos_complement_8(raw):
    return (-raw) & 0xFF


def decode_posit8(raw):
    """Decode Posit(8,0). Return Fraction, or None for NaR."""
    if raw == 0x00:
        return Fraction(0, 1)
    if raw == 0x80:
        return None

    negative = bool(raw & 0x80)
    magnitude = twos_complement_8(raw) if negative else raw

    bit_index = 6
    regime_bit = (magnitude >> bit_index) & 1
    run_length = 0

    while bit_index >= 0:
        current = (magnitude >> bit_index) & 1
        if current != regime_bit:
            break
        run_length += 1
        bit_index -= 1

    k = run_length - 1 if regime_bit else -run_length

    if bit_index >= 0:
        bit_index -= 1

    fraction_count = bit_index + 1
    if fraction_count > 0:
        mask = (1 << fraction_count) - 1
        fraction_bits = magnitude & mask
        significand = (
            Fraction(1, 1)
            + Fraction(fraction_bits, 1 << fraction_count)
        )
    else:
        significand = Fraction(1, 1)

    scale = (
        Fraction(2 ** k, 1)
        if k >= 0
        else Fraction(1, 2 ** (-k))
    )

    value = scale * significand
    return -value if negative else value


POSIT8_TABLE = [
    (decode_posit8(raw), raw)
    for raw in range(256)
    if raw != 0x80
]


def quantize_to_posit8(value):
    """Round to the nearest Posit(8,0) value."""
    decoded, raw = min(
        POSIT8_TABLE,
        key=lambda item: (
            abs(item[0] - value),
            item[1] & 1,
            abs(item[0]),
            item[1],
        ),
    )
    return raw, decoded


def fraction_to_decimal(value):
    return format(float(value), ".12g")


def read_real_vectors(path):
    vectors = []

    for line_number, line in enumerate(
        Path(path).read_text(encoding="utf-8").splitlines(),
        start=1,
    ):
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        parts = line.split()
        if len(parts) != len(LABELS):
            raise ValueError(
                f"Line {line_number}: expected {len(LABELS)} "
                f"real values, found {len(parts)}."
            )

        try:
            values = [Fraction(value) for value in parts]
        except ValueError as error:
            raise ValueError(
                f"Line {line_number}: invalid real value."
            ) from error

        for label, value in zip(LABELS, values):
            if not Fraction(-1, 1) <= value <= Fraction(1, 1):
                raise ValueError(
                    f"Line {line_number}, {label}: outside [-1,1]."
                )

        vectors.append((parts, values))

    if not vectors:
        raise ValueError("No real vectors were found.")

    return vectors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        default="generated_fp8_vectors_100/real_vectors.txt",
        help="The same 100 source real vectors used for FP8.",
    )
    parser.add_argument(
        "--output-dir",
        default="generated_posit8_vectors_100",
    )
    args = parser.parse_args()

    vectors = read_real_vectors(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    vector_path = output_dir / "posit8_vectors.txt"
    report_path = output_dir / "posit8_report.csv"
    source_copy_path = output_dir / "real_vectors.txt"

    with vector_path.open("w", encoding="utf-8") as vector_file, \
         report_path.open("w", newline="", encoding="utf-8") as report_file, \
         source_copy_path.open("w", encoding="utf-8") as source_copy:

        writer = csv.writer(report_file)
        writer.writerow([
            "vector_id",
            "label",
            "original",
            "posit8_hex",
            "decoded_posit8",
            "quantization_error",
        ])

        for vector_id, (original_strings, values) in enumerate(vectors):
            encoded = []
            source_copy.write(" ".join(original_strings) + "\n")

            for label, value, original_text in zip(
                LABELS,
                values,
                original_strings,
            ):
                raw, decoded = quantize_to_posit8(value)
                encoded.append(raw)
                writer.writerow([
                    vector_id,
                    label,
                    original_text,
                    f"{raw:02X}",
                    fraction_to_decimal(decoded),
                    fraction_to_decimal(decoded - value),
                ])

            vector_file.write(
                " ".join(f"{raw:02X}" for raw in encoded) + "\n"
            )

    print(f"Source vectors:     {len(vectors)}")
    print("Posit8 format:      Posit(8,0)")
    print(f"Operand order:      {' '.join(LABELS)}")
    print(f"Input real vectors: {args.input}")
    print(f"Generated:          {vector_path}")
    print(f"Report:             {report_path}")


if __name__ == "__main__":
    main()
