#!/usr/bin/env python3
import argparse
import bisect
import csv
from pathlib import Path

LABELS = [
    "A0", "A1", "A2", "A3",
    "B0", "B1", "B2", "B3",
    "C0",
]

NBITS = 16
ES = 1
NAR = 0x8000
MASK = (1 << NBITS) - 1


def decode_posit(raw: int):
    """Decode one finite posit<16,1> bit pattern to Python float.

    Returns None for NaR.
    """
    raw &= MASK

    if raw == 0:
        return 0.0

    if raw == NAR:
        return None

    sign = (raw >> (NBITS - 1)) & 1

    # Negative posits are decoded from their two's-complement magnitude.
    ui = ((~raw + 1) & MASK) if sign else raw

    index = NBITS - 2
    regime_bit = (ui >> index) & 1
    run_length = 0

    while index >= 0 and ((ui >> index) & 1) == regime_bit:
        run_length += 1
        index -= 1

    k = run_length - 1 if regime_bit else -run_length

    # Skip the terminating regime bit when it exists.
    if index >= 0:
        index -= 1

    exponent = 0

    for _ in range(ES):
        exponent <<= 1

        if index >= 0:
            exponent |= (ui >> index) & 1
            index -= 1

    fraction = 1.0
    weight = 0.5

    while index >= 0:
        if (ui >> index) & 1:
            fraction += weight

        weight *= 0.5
        index -= 1

    useed = 2.0 ** (2 ** ES)
    value = (useed ** k) * (2.0 ** exponent) * fraction

    return -value if sign else value


def build_sorted_finite_table():
    entries = []

    for raw in range(1 << NBITS):
        value = decode_posit(raw)

        if value is not None:
            entries.append((value, raw))

    entries.sort(key=lambda item: item[0])

    values = [value for value, _ in entries]
    raws = [raw for _, raw in entries]

    return values, raws


POSIT_VALUES, POSIT_RAWS = build_sorted_finite_table()


def quantize_to_posit16(value: float):
    """Round a real value to the nearest finite posit<16,1>."""
    index = bisect.bisect_left(POSIT_VALUES, value)

    candidates = []

    if index > 0:
        candidates.append(index - 1)

    if index < len(POSIT_VALUES):
        candidates.append(index)

    if not candidates:
        raise RuntimeError("The Posit16 lookup table is empty.")

    best_index = min(
        candidates,
        key=lambda candidate: (
            abs(POSIT_VALUES[candidate] - value),
            POSIT_RAWS[candidate] & 1,
            POSIT_RAWS[candidate],
        ),
    )

    return (
        POSIT_RAWS[best_index],
        POSIT_VALUES[best_index],
    )


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
            "script is run from 100vectors/posit16/."
        ),
    )
    parser.add_argument(
        "--output-dir",
        default="generated_posit16_vectors_100",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    vectors = read_real_vectors(input_path)

    encoded_path = output_dir / "posit16_vectors.txt"
    report_path = output_dir / "posit16_report.csv"
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
            "posit16_hex",
            "decoded_posit16",
            "quantization_error",
        ])

        for vector_id, real_values in enumerate(vectors):
            encoded_tokens = []

            audit_file.write(
                " ".join(f"{value:.10f}" for value in real_values)
                + "\n"
            )

            for label, value in zip(LABELS, real_values):
                raw, decoded = quantize_to_posit16(value)
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
    print("Format:             posit<16,1>")
    print(f"Operand order:      {' '.join(LABELS)}")
    print(f"Input real vectors: {input_path}")
    print(f"Posit16 vectors:    {encoded_path}")
    print(f"Report:             {report_path}")
    print(f"Audit copy:         {audit_path}")


if __name__ == "__main__":
    main()
