import numpy as np
import sys

def fp16_hex(x: float) -> str:
    """Return IEEE-754 binary16 bits as 4 hex chars (uppercase)."""
    fp16 = np.float16(x)
    bits = np.frombuffer(fp16.tobytes(), dtype=np.uint16)[0]
    return f"{bits:04X}"

def convert_file(input_file: str,
                 output_file: str,
                 addr_width_hex: int = 3,
                 placeholder_mode: str = "comment"):
    """
    placeholder_mode:
      - "comment": keep addr-only lines as comments in output (default)
      - "zero": output addr + 00000000 for addr-only or incomplete numeric lines
      - "skip": drop addr-only or incomplete numeric lines
    """
    valid_modes = {"comment", "zero", "skip"}
    if placeholder_mode not in valid_modes:
        raise ValueError(f"placeholder_mode must be one of {valid_modes}")

    with open(input_file, "r") as fin, open(output_file, "w") as fout:
        for lineno, raw in enumerate(fin, start=1):
            # Preserve original line ending style? We'll write '\n' consistently.
            line = raw.rstrip("\n")

            stripped = line.strip()

            # Preserve blank lines
            if stripped == "":
                fout.write("\n")
                continue

            # Preserve comments exactly
            if stripped.startswith("#"):
                fout.write(line + "\n")
                continue

            parts = stripped.split()

            # If it's not even an address, pass through as a comment (rare)
            if len(parts) < 1:
                fout.write(f"# [SKIP unparsable line {lineno}] {line}\n")
                continue

            # Parse decimal address
            try:
                addr_dec = int(parts[0], 10)
            except ValueError:
                # If someone accidentally used hex, you can decide what to do.
                fout.write(f"# [BAD ADDR line {lineno}] {line}\n")
                continue

            addr_hex = f"{addr_dec:0{addr_width_hex}X}"

            # Case A: full triple "addr a b"
            if len(parts) >= 3:
                try:
                    a = float(parts[1])
                    b = float(parts[2])
                except ValueError:
                    # bad numbers
                    if placeholder_mode == "zero":
                        fout.write(f"{addr_hex} 00000000\n")
                    elif placeholder_mode == "comment":
                        fout.write(f"# [BAD NUM line {lineno}] {addr_hex} {line}\n")
                    # skip otherwise
                    continue

                out = fp16_hex(a) + fp16_hex(b)
                fout.write(f"{addr_hex} {out}\n")
                continue

            # Case B: addr-only or incomplete line
            if placeholder_mode == "zero":
                fout.write(f"{addr_hex} 00000000\n")
            elif placeholder_mode == "comment":
                fout.write(f"# [PLACEHOLDER] {addr_hex}\n")
            # skip if placeholder_mode == "skip"

if __name__ == "__main__":
    if len(sys.argv) not in (3, 4, 5):
        print("Usage:")
        print("  python fp16_rf_generator.py input.txt output.txt [addr_hex_digits] [placeholder_mode]")
        print("Examples:")
        print("  python fp16_rf_generator.py in.txt out.txt")
        print("  python fp16_rf_generator.py in.txt out.txt 3 comment")
        print("  python fp16_rf_generator.py in.txt out.txt 3 zero")
        sys.exit(1)

    addr_digits = int(sys.argv[3]) if len(sys.argv) >= 4 else 3
    mode = sys.argv[4] if len(sys.argv) == 5 else "comment"
    convert_file(sys.argv[1], sys.argv[2], addr_width_hex=addr_digits, placeholder_mode=mode)