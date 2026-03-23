import re
import sys
import struct
import numpy as np


def parse_matrices(filename):
    matrices = {}
    current = None
    data = []

    with open(filename, "r") as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            if line.startswith("#"):
                if current and data:
                    matrices[current] = np.array(data, dtype=float)
                name = line.split()[0][1:]  # remove '#'
                current = name
                data = []
            else:
                row = [float(x) for x in line.split()]
                data.append(row)

    if current and data:
        matrices[current] = np.array(data, dtype=float)

    return matrices


def compute_results(m):
    A00 = m["A00"]
    B00 = m["B00"]
    C00 = m["C00"]
    A01 = m["A01"]
    C01 = m["C01"]

    D00 = A00 @ B00 + C00
    D01 = A01 @ B00 + C01

    return D00, D01


def float_to_fp16_hex(value: float) -> str:
    """Convert Python float to IEEE-754 FP16 hex string."""
    packed = struct.pack(">e", float(value))   # half precision
    intval = struct.unpack(">H", packed)[0]
    return f"{intval:04X}"


def write_matrix_float(f, name, M):
    f.write(f"#{name} result matrix (decoded float values)\n")
    for row in M:
        f.write(" ".join(f"{v:.6f}" for v in row) + "\n")
    f.write("\n")


def write_matrix_fp16_hex(f, name, M):
    f.write(f"#{name} result matrix (FP16 encoded hex values)\n")
    for row in M:
        f.write(" ".join(float_to_fp16_hex(v) for v in row) + "\n")
    f.write("\n")


def main():
    if len(sys.argv) != 3:
        print("Usage: python compute_hmma_reference.py input.txt results.txt")
        return

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    matrices = parse_matrices(input_file)
    D00, D01 = compute_results(matrices)

    with open(output_file, "w") as f:
        write_matrix_float(f, "D00", D00)
        write_matrix_fp16_hex(f, "D00", D00)

        write_matrix_float(f, "D01", D01)
        write_matrix_fp16_hex(f, "D01", D01)

    print("Results written to:", output_file)


if __name__ == "__main__":
    main()