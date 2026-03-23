#!/usr/bin/env python3

import math
from pathlib import Path

COLS = ["a0","a1","a2","a3","b0","b1","b2","b3","c0","r","r_gold"]

INPUT_FILE = "output_file.txt"
OUTPUT_FILE = "outputFromScript.txt"


def hexbyte_to_u8(tok):
    tok = tok.strip()
    if tok.lower().startswith("0x"):
        tok = tok[2:]
    return int(tok, 16)


def fp8_e4m3_to_float(u8):
    sign = -1.0 if (u8 & 0x80) else 1.0
    exp = (u8 >> 3) & 0x0F
    frac = u8 & 0x07
    bias = 7

    if exp == 0:
        if frac == 0:
            return 0.0 * sign
        e = 1 - bias
        m = frac / 8.0
        return sign * math.ldexp(m, e)

    if exp == 15:
        if frac == 0:
            return sign * float("inf")
        return float("nan")

    e = exp - bias
    m = 1.0 + frac / 8.0
    return sign * math.ldexp(m, e)


def main():

    rows = []

    with open(INPUT_FILE,"r") as f:
        for line in f:

            line=line.strip()
            if not line:
                continue

            parts=line.split()

            if len(parts)!=11:
                raise ValueError("Each row must contain 11 hex values")

            values=[hexbyte_to_u8(p) for p in parts]

            decoded=[fp8_e4m3_to_float(v) for v in values]

            rows.append(decoded)

    with open(OUTPUT_FILE,"w") as out:

        # column description
        header=" ".join([f"<{c}>" for c in COLS])
        out.write(header+"\n")

        for row in rows:
            line=" ".join([f"{v:.6g}" for v in row])
            out.write(line+"\n")

    print("Results written to:", OUTPUT_FILE)


if __name__=="__main__":
    main()