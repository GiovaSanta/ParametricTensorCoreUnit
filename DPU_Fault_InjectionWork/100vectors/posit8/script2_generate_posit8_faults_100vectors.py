#!/usr/bin/env python3
import argparse
import csv
from pathlib import Path

LABELS = [
    "A0", "A1", "A2", "A3",
    "B0", "B1", "B2", "B3",
    "C0",
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

        if len(tokens) != len(LABELS):
            raise ValueError(
                f"Line {line_number}: expected "
                f"{len(LABELS)} hexadecimal operands, "
                f"found {len(tokens)}."
            )

        try:
            values = [int(token, 16) for token in tokens]
        except ValueError as error:
            raise ValueError(
                f"Line {line_number}: invalid hexadecimal token."
            ) from error

        if any(value < 0 or value > 0xFF for value in values):
            raise ValueError(
                f"Line {line_number}: operands must be 8-bit."
            )

        vectors.append(values)

    if not vectors:
        raise ValueError("No vectors were found.")

    return vectors


parser = argparse.ArgumentParser()
parser.add_argument(
    "input",
    nargs="?",
    default="generated_posit8_vectors_100/posit8_vectors.txt",
    help="One nine-operand Posit8 vector per line.",
)
parser.add_argument(
    "--output-dir",
    default="posit8_input_faults_100",
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
        "bit",
        "stuck_at",
        "original",
        "faulty",
        "activated",
    ])

    row = 0

    for vector_id, original_values in enumerate(vectors):
        for operand_index, label in enumerate(LABELS):
            for bit in range(8):
                for stuck_at in (0, 1):
                    faulty_values = original_values.copy()
                    mask = 1 << bit

                    if stuck_at == 1:
                        faulty_values[operand_index] |= mask
                    else:
                        faulty_values[operand_index] &= ~mask

                    vectors_file.write(
                        " ".join(
                            f"{value:02X}"
                            for value in faulty_values
                        )
                        + "\n"
                    )

                    writer.writerow([
                        row,
                        vector_id,
                        label,
                        operand_index,
                        bit,
                        stuck_at,
                        f"{original_values[operand_index]:02X}",
                        f"{faulty_values[operand_index]:02X}",
                        (
                            faulty_values[operand_index]
                            != original_values[operand_index]
                        ),
                    ])

                    row += 1

expected = len(vectors) * len(LABELS) * 8 * 2

if row != expected:
    raise AssertionError(
        f"Expected {expected} rows, generated {row}."
    )

print(f"Input vectors: {len(vectors)}")
print(f"Fault rows:    {row}")
print(f"Expected:      {expected}")
print(f"Vectors:       {fault_vectors_path}")
print(f"Manifest:      {manifest_path}")
