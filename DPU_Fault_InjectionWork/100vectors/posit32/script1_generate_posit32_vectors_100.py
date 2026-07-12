#!/usr/bin/env python3
import argparse
import csv
import math
from pathlib import Path

LABELS = [
    "A0", "A1", "A2", "A3",
    "B0", "B1", "B2", "B3",
    "C0",
]

NBITS = 32
ES = 2
MASK = (1 << NBITS) - 1
NAR = 1 << (NBITS - 1)
MAXPOS = NAR - 1


def decode_posit(raw: int):
    """Decode one posit<32,2> word.

    Returns None for NaR.
    """
    raw &= MASK

    if raw == 0:
        return 0.0

    if raw == NAR:
        return None

    sign = (raw >> (NBITS - 1)) & 1

    # Negative posits use the two's-complement encoding of
    # the corresponding positive magnitude.
    ui = ((~raw + 1) & MASK) if sign else raw

    index = NBITS - 2
    regime_bit = (ui >> index) & 1
    run_length = 0

    while index >= 0 and ((ui >> index) & 1) == regime_bit:
        run_length += 1
        index -= 1

    k = run_length - 1 if regime_bit else -run_length

    # Skip the terminating regime bit when present.
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


def nearest_positive_posit(magnitude: float):
    """Return nearest positive posit<32,2> code and decoded value.

    Positive posit encodings are monotonic from zero to MAXPOS, so
    binary search avoids enumerating all 2^32 patterns.
    """
    if magnitude <= 0.0:
        return 0, 0.0

    max_value = decode_posit(MAXPOS)

    if magnitude >= max_value:
        return MAXPOS, max_value

    low = 0
    high = MAXPOS

    while low < high:
        middle = (low + high) // 2
        middle_value = decode_posit(middle)

        if middle_value < magnitude:
            low = middle + 1
        else:
            high = middle

    upper_raw = low
    lower_raw = max(0, upper_raw - 1)

    candidates = [
        (lower_raw, decode_posit(lower_raw)),
        (upper_raw, decode_posit(upper_raw)),
    ]

    # Nearest value. On an exact midpoint, prefer an even LSB.
    best_raw, best_value = min(
        candidates,
        key=lambda item: (
            abs(item[1] - magnitude),
            item[0] & 1,
            item[0],
        ),
    )

    return best_raw, best_value


def quantize_to_posit32(value: float):
    """Round a real value to nearest finite posit<32,2>."""
    value = float(value)

    if not math.isfinite(value):
        raise ValueError(f"Cannot encode non-finite value: {value}")

    if value == 0.0:
        return 0, 0.0

    magnitude_raw, magnitude_value = nearest_positive_posit(
        abs(value)
    )

    if value > 0.0:
        return magnitude_raw, magnitude_value

    raw = (-magnitude_raw) & MASK
    return raw, -magnitude_value


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
                f"{len(LABELS)} operands, found {len(tokens)}."
            )

        try:
            values = [float(token) for token in tokens]
        except ValueError as error:
            raise ValueError(
                f"{path}, line {line_number}: invalid real operand."
            ) from error

        if not all(math.isfinite(value) for value in values):
            raise ValueError(
                f"{path}, line {line_number}: all source "
                "operands must be finite."
            )

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
            "script is run from 100vectors/posit32/."
        ),
    )
    parser.add_argument(
        "--output-dir",
        default="generated_posit32_vectors_100",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    vectors = read_real_vectors(input_path)

    encoded_path = output_dir / "posit32_vectors.txt"
    report_path = output_dir / "posit32_report.csv"
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
            "posit32_hex",
            "decoded_posit32",
            "quantization_error",
        ])

        for vector_id, real_values in enumerate(vectors):
            encoded_tokens = []

            audit_file.write(
                " ".join(f"{value:.10f}" for value in real_values)
                + "\n"
            )

            for label, value in zip(LABELS, real_values):
                raw, decoded = quantize_to_posit32(value)
                encoded_tokens.append(f"{raw:08X}")

                writer.writerow([
                    vector_id,
                    label,
                    f"{value:.10f}",
                    f"{raw:08X}",
                    f"{decoded:.17g}",
                    f"{decoded - value:.17g}",
                ])

            encoded_file.write(
                " ".join(encoded_tokens) + "\n"
            )

    print(f"Source vectors:     {len(vectors)}")
    print("Format:             posit<32,2>")
    print(f"Operand order:      {' '.join(LABELS)}")
    print(f"Input real vectors: {input_path}")
    print(f"Posit32 vectors:    {encoded_path}")
    print(f"Report:             {report_path}")
    print(f"Audit copy:         {audit_path}")


if __name__ == "__main__":
    main()
