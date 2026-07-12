#!/usr/bin/env python3
import argparse
import csv
import math
from pathlib import Path

LABELS = ["A0", "A1", "A2", "A3", "B0", "B1", "B2", "B3", "C0"]
WF = 9
SCALE = 1 << WF
MIN_LOG = -4096
MAX_LOG = 4095
MIN_MAG = 2.0 ** (MIN_LOG / SCALE)

def signed13_to_bits(value: int) -> int:
    if value < 0:
        value = (1 << 13) + value
    return value & 0x1FFF

def bits_to_signed13(raw: int) -> int:
    value = raw & 0x1FFF
    if value & 0x1000:
        value -= 0x2000
    return value

def make_lns(sign: int, log_fixed: int) -> int:
    if not MIN_LOG <= log_fixed <= MAX_LOG:
        raise ValueError(f"Signed log field outside LNS16 range: {log_fixed}")
    return 0x4000 | ((sign & 1) << 13) | signed13_to_bits(log_fixed)

def decode_lns16(raw: int) -> float:
    raw &= 0xFFFF
    if raw == 0x0000:
        return 0.0
    if (raw >> 14) != 0b01:
        raise ValueError(f"Unsupported non-normal LNS16 encoding: {raw:04X}")
    sign = -1.0 if ((raw >> 13) & 1) else 1.0
    log_fixed = bits_to_signed13(raw)
    return sign * (2.0 ** (log_fixed / SCALE))

def encode_lns16(value: float):
    value = float(value)
    if not math.isfinite(value):
        raise ValueError(f"Cannot encode non-finite value: {value}")
    magnitude = abs(value)
    if magnitude < MIN_MAG:
        return 0x0000, 0.0, True
    sign = 1 if value < 0.0 else 0
    log_fixed = int(round(math.log2(magnitude) * SCALE))
    if log_fixed < MIN_LOG:
        return 0x0000, 0.0, True
    if log_fixed > MAX_LOG:
        log_fixed = MAX_LOG
    raw = make_lns(sign, log_fixed)
    return raw, decode_lns16(raw), False

def read_real_vectors(path: Path):
    vectors = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        tokens = line.split()
        if len(tokens) != len(LABELS):
            raise ValueError(f"{path}, line {line_number}: expected 9 operands, found {len(tokens)}.")
        vectors.append([float(token) for token in tokens])
    if not vectors:
        raise ValueError(f"No vectors found in {path}.")
    return vectors

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="../generated_fp8_vectors_100/real_vectors.txt")
    parser.add_argument("--output-dir", default="generated_lns16_vectors_100")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    vectors = read_real_vectors(input_path)

    encoded_path = output_dir / "lns16_vectors.txt"
    report_path = output_dir / "lns16_report.csv"
    audit_path = output_dir / "real_vectors.txt"
    underflow_count = 0

    with encoded_path.open("w", encoding="utf-8") as encoded_file, \
         report_path.open("w", newline="", encoding="utf-8") as report_file, \
         audit_path.open("w", encoding="utf-8") as audit_file:
        writer = csv.writer(report_file)
        writer.writerow([
            "vector_id", "label", "original", "lns16_hex",
            "decoded_lns16", "quantization_error", "underflow_to_zero"
        ])
        for vector_id, real_values in enumerate(vectors):
            audit_file.write(" ".join(f"{value:.10f}" for value in real_values) + "\n")
            encoded_tokens = []
            for label, value in zip(LABELS, real_values):
                raw, decoded, underflow = encode_lns16(value)
                encoded_tokens.append(f"{raw:04X}")
                underflow_count += int(underflow)
                writer.writerow([
                    vector_id, label, f"{value:.10f}", f"{raw:04X}",
                    f"{decoded:.12g}", f"{decoded - value:.12g}", underflow
                ])
            encoded_file.write(" ".join(encoded_tokens) + "\n")

    print(f"Source vectors:     {len(vectors)}")
    print("Format:             LNS16, wE=4, wF=9")
    print("Normal encoding:    01 | sign | signed-log13")
    print(f"Minimum magnitude:  {MIN_MAG}")
    print(f"Underflowed inputs: {underflow_count}")
    print(f"Operand order:      {' '.join(LABELS)}")
    print(f"Input real vectors: {input_path}")
    print(f"LNS16 vectors:      {encoded_path}")
    print(f"Report:             {report_path}")
    print(f"Audit copy:         {audit_path}")

if __name__ == "__main__":
    main()
