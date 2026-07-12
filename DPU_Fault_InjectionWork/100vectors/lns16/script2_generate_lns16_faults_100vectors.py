#!/usr/bin/env python3
import argparse
import csv
from pathlib import Path

LABELS = ["A0", "A1", "A2", "A3", "B0", "B1", "B2", "B3", "C0"]
WIDTH_BITS = 16

def read_vectors(path):
    vectors = []
    for line_number, line in enumerate(Path(path).read_text(encoding="utf-8").splitlines(), start=1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        tokens = line.split()
        if len(tokens) != 9:
            raise ValueError(f"Line {line_number}: expected 9 operands, found {len(tokens)}.")
        values = []
        for token, label in zip(tokens, LABELS):
            if len(token) != 4:
                raise ValueError(f"Line {line_number}, {label}: expected four hex digits.")
            values.append(int(token, 16))
        vectors.append(values)
    if not vectors:
        raise ValueError("No vectors found.")
    return vectors

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", nargs="?", default="generated_lns16_vectors_100/lns16_vectors.txt")
    parser.add_argument("--output-dir", default="lns16_input_faults_100")
    args = parser.parse_args()

    vectors = read_vectors(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    fault_vectors_path = output_dir / "fault_vectors.txt"
    manifest_path = output_dir / "fault_manifest.csv"

    with fault_vectors_path.open("w", encoding="utf-8") as vectors_file, \
         manifest_path.open("w", newline="", encoding="utf-8") as manifest_file:
        writer = csv.writer(manifest_file)
        writer.writerow([
            "row", "vector_id", "target", "operand_index", "width_bits",
            "bit", "stuck_at", "original", "faulty", "activated"
        ])
        row = 0
        for vector_id, original_values in enumerate(vectors):
            for operand_index, label in enumerate(LABELS):
                for bit in range(WIDTH_BITS):
                    for stuck_at in (0, 1):
                        faulty_values = original_values.copy()
                        mask = 1 << bit
                        if stuck_at:
                            faulty_values[operand_index] |= mask
                        else:
                            faulty_values[operand_index] &= ~mask
                        vectors_file.write(" ".join(f"{value:04X}" for value in faulty_values) + "\n")
                        writer.writerow([
                            row, vector_id, label, operand_index, WIDTH_BITS, bit, stuck_at,
                            f"{original_values[operand_index]:04X}",
                            f"{faulty_values[operand_index]:04X}",
                            faulty_values[operand_index] != original_values[operand_index],
                        ])
                        row += 1

    bits_per_vector = len(LABELS) * WIDTH_BITS
    expected = len(vectors) * bits_per_vector * 2
    if row != expected:
        raise AssertionError(f"Expected {expected} rows, generated {row}.")
    print(f"Input vectors:       {len(vectors)}")
    print(f"Bits per vector:     {bits_per_vector}")
    print(f"Fault rows:          {row}")
    print(f"Expected activated:  {len(vectors) * bits_per_vector}")
    print(f"Vectors:             {fault_vectors_path}")
    print(f"Manifest:            {manifest_path}")

if __name__ == "__main__":
    main()
