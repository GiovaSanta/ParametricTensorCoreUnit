#!/usr/bin/env python3
import argparse
import csv
from pathlib import Path

OPERANDS = [
    ("A0", 16), ("A1", 16), ("A2", 16), ("A3", 16),
    ("B0", 16), ("B1", 16), ("B2", 16), ("B3", 16),
    ("C0", 32),
]


def read_vectors(path):
    vectors = []

    for line_number, line in enumerate(
        Path(path).read_text(
            encoding="utf-8"
        ).splitlines(),
        start=1,
    ):
        line = line.strip()

        if not line or line.startswith("#"):
            continue

        tokens = line.split()

        if len(tokens) != len(OPERANDS):
            raise ValueError(
                f"Line {line_number}: expected "
                f"{len(OPERANDS)} operands, found {len(tokens)}."
            )

        values = []

        for token, (label, width) in zip(tokens, OPERANDS):
            expected_digits = width // 4

            if len(token) != expected_digits:
                raise ValueError(
                    f"Line {line_number}, {label}: expected "
                    f"{expected_digits} hex digits, found {token!r}."
                )

            try:
                value = int(token, 16)
            except ValueError as error:
                raise ValueError(
                    f"Line {line_number}, {label}: "
                    f"invalid hexadecimal token {token!r}."
                ) from error

            if not 0 <= value < (1 << width):
                raise ValueError(
                    f"Line {line_number}, {label}: "
                    f"value does not fit in {width} bits."
                )

            values.append(value)

        vectors.append(values)

    if not vectors:
        raise ValueError("No vectors were found.")

    return vectors


def format_vector(values):
    return " ".join(
        f"{value:0{width // 4}X}"
        for value, (_, width) in zip(values, OPERANDS)
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "input",
        nargs="?",
        default=(
            "generated_fxp16_32_vectors_100/"
            "fxp16_32_vectors.txt"
        ),
    )
    parser.add_argument(
        "--output-dir",
        default="fxp16_32_input_faults_100",
    )
    args = parser.parse_args()

    vectors = read_vectors(args.input)

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    fault_vectors_path = output_dir / "fault_vectors.txt"
    manifest_path = output_dir / "fault_manifest.csv"

    with fault_vectors_path.open(
        "w", encoding="utf-8"
    ) as vectors_file, manifest_path.open(
        "w", newline="", encoding="utf-8"
    ) as manifest_file:

        writer = csv.writer(manifest_file)
        writer.writerow([
            "row",
            "vector_id",
            "target",
            "operand_index",
            "width_bits",
            "bit",
            "stuck_at",
            "original",
            "faulty",
            "activated",
        ])

        row = 0

        for vector_id, original_values in enumerate(vectors):
            for operand_index, (label, width) in enumerate(OPERANDS):
                hex_digits = width // 4

                for bit in range(width):
                    for stuck_at in (0, 1):
                        faulty_values = original_values.copy()
                        mask = 1 << bit

                        if stuck_at == 1:
                            faulty_values[operand_index] |= mask
                        else:
                            faulty_values[operand_index] &= ~mask

                        vectors_file.write(
                            format_vector(faulty_values) + "\n"
                        )

                        writer.writerow([
                            row,
                            vector_id,
                            label,
                            operand_index,
                            width,
                            bit,
                            stuck_at,
                            format(
                                original_values[operand_index],
                                f"0{hex_digits}X",
                            ),
                            format(
                                faulty_values[operand_index],
                                f"0{hex_digits}X",
                            ),
                            (
                                faulty_values[operand_index]
                                != original_values[operand_index]
                            ),
                        ])

                        row += 1

    bits_per_vector = sum(width for _, width in OPERANDS)
    expected = len(vectors) * bits_per_vector * 2

    if row != expected:
        raise AssertionError(
            f"Expected {expected} rows, generated {row}."
        )

    print(f"Input vectors:       {len(vectors)}")
    print(f"Bits per vector:     {bits_per_vector}")
    print(f"Fault rows:          {row}")
    print(f"Expected activated:  {len(vectors) * bits_per_vector}")
    print(f"Vectors:             {fault_vectors_path}")
    print(f"Manifest:            {manifest_path}")


if __name__ == "__main__":
    main()
