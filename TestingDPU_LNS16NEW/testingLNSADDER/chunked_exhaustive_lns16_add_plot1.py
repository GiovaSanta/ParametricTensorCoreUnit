#!/usr/bin/env python3
"""
Chunked exhaustive LNS16 ADD Plot-1 workflow.

This avoids creating one gigantic exhaustive_lns16_add_vectors.txt file.

Instead:
  1) Emit a manageable chunk of input vectors.
  2) Run that chunk in the VHDL testbench.
  3) Analyze that chunk and accumulate delta-bin statistics.
  4) Repeat chunks until you have covered as much of the exhaustive space as desired.
  5) Plot the accumulated bins.

Total exhaustive space:
  values = 16385
  ordered ADD pairs = 16385 * 16385 = 268,468,225

Pair indexing:
  pair_id = a_index * 16385 + b_index

Value indexing:
  value_index = 0       -> 0x0000
  value_index = 1..8192 -> positive normal values, log=-4096..4095
  value_index = 8193..16384 -> negative normal values, log=-4096..4095

Commands
--------

Emit chunk:
  python chunked_exhaustive_lns16_add_plot1.py emit-chunk \
    --start-id 0 --count 1000000 --out add_chunk_000.txt

Hardware output should preferably contain:
  vector_id obtained_hex

Example:
  0 0000
  1 4000
  2 4001

Analyze and accumulate:
  python chunked_exhaustive_lns16_add_plot1.py analyze-chunk \
    --results add_chunk_000_hw.txt \
    --bins-out accumulated_bins.csv

Next chunk:
  python chunked_exhaustive_lns16_add_plot1.py emit-chunk \
    --start-id 1000000 --count 1000000 --out add_chunk_001.txt

Analyze next chunk and merge:
  python chunked_exhaustive_lns16_add_plot1.py analyze-chunk \
    --results add_chunk_001_hw.txt \
    --bins-in accumulated_bins.csv \
    --bins-out accumulated_bins.csv

Plot:
  python chunked_exhaustive_lns16_add_plot1.py plot \
    --bins accumulated_bins.csv \
    --outdir plot1_results

Self-test a chunk without hardware:
  python chunked_exhaustive_lns16_add_plot1.py self-test-chunk \
    --start-id 0 --count 1000000 \
    --bins-out accumulated_bins.csv
"""

import argparse
import csv
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, Iterator, Optional, Tuple

import matplotlib.pyplot as plt


WF = 9
SCALE = 1 << WF

LOG_MIN = -4096
LOG_MAX = 4095
NUM_LOGS = LOG_MAX - LOG_MIN + 1

N_VALUES = 1 + 2 * NUM_LOGS
TOTAL_PAIRS = N_VALUES * N_VALUES

STATUS_NORMAL_PREFIX = 0x4000
SIGN_BIT_MASK = 0x2000
LOG_MASK = 0x1FFF

NEAR_ZERO_ABS_TOL = 0.25
ABS_TOL = 0.5
LOG_LSB_TOL = 128


@dataclass(frozen=True)
class Decoded:
    bits: int
    is_zero: bool
    is_normal: bool
    sign: int
    log_int: int
    value: float


@dataclass
class BinStats:
    count: int = 0
    fail_count: int = 0

    same_count: int = 0
    same_fail: int = 0

    opp_count: int = 0
    opp_fail: int = 0

    sum_log_err: float = 0.0
    max_log_err: int = 0

    sum_abs_err: float = 0.0
    max_abs_err: float = 0.0


def signed13_to_bits(x: int) -> int:
    if x < 0:
        x = (1 << 13) + x
    return x & LOG_MASK


def bits_to_signed13(x: int) -> int:
    v = x & LOG_MASK
    if v & 0x1000:
        v -= 0x2000
    return v


def make_lns16(sign: int, log_int: int) -> int:
    return STATUS_NORMAL_PREFIX | ((sign & 1) << 13) | signed13_to_bits(log_int)


def value_from_index(idx: int) -> int:
    if not (0 <= idx < N_VALUES):
        raise ValueError(f"value index out of range: {idx}")

    if idx == 0:
        return 0x0000

    n = idx - 1

    if n < NUM_LOGS:
        sign = 0
        log_int = LOG_MIN + n
    else:
        sign = 1
        log_int = LOG_MIN + (n - NUM_LOGS)

    return make_lns16(sign, log_int)


def pair_from_id(pair_id: int) -> Tuple[int, int]:
    if not (0 <= pair_id < TOTAL_PAIRS):
        raise ValueError(f"pair_id out of range: {pair_id}")

    a_idx = pair_id // N_VALUES
    b_idx = pair_id % N_VALUES
    return value_from_index(a_idx), value_from_index(b_idx)


def decode(bits_or_hex) -> Decoded:
    if isinstance(bits_or_hex, str):
        bits = int(bits_or_hex.strip(), 16) & 0xFFFF
    else:
        bits = int(bits_or_hex) & 0xFFFF

    if bits == 0:
        return Decoded(bits, True, False, 0, 0, 0.0)

    status = (bits >> 14) & 0x3
    sign = (bits >> 13) & 0x1
    log_int = bits_to_signed13(bits)

    if status != 0b01:
        return Decoded(bits, False, False, sign, log_int, float("nan"))

    mag = 2.0 ** (log_int / SCALE)
    value = -mag if sign else mag
    return Decoded(bits, False, True, sign, log_int, value)


def encode_real_to_lns16(x: float) -> int:
    if not math.isfinite(x):
        raise ValueError(f"Cannot encode non-finite result: {x}")

    if x == 0.0:
        return 0x0000

    sign = 1 if x < 0.0 else 0
    mag = abs(x)
    log_int = int(round(math.log2(mag) * SCALE))

    if log_int < LOG_MIN:
        return 0x0000

    if log_int > LOG_MAX:
        # Saturate golden for overflow-like edge cases.
        # For LNS16 ADD, max + max slightly exceeds max representable.
        log_int = LOG_MAX

    return make_lns16(sign, log_int)


def golden_add(a_bits: int, b_bits: int) -> int:
    a = decode(a_bits)
    b = decode(b_bits)
    return encode_real_to_lns16(a.value + b.value)


def delta_and_case(a_bits: int, b_bits: int) -> Tuple[int, str]:
    a = decode(a_bits)
    b = decode(b_bits)

    if a.is_zero or b.is_zero:
        return -1, "zero_operand"

    delta = abs(a.log_int - b.log_int)
    case = "same_sign" if a.sign == b.sign else "opposite_sign"
    return delta, case


def is_near_zero(d: Decoded) -> bool:
    return d.is_zero or (math.isfinite(d.value) and abs(d.value) <= NEAR_ZERO_ABS_TOL)


def compare(got_bits: int, gold_bits: int) -> Tuple[bool, float, int, str]:
    got = decode(got_bits)
    gold = decode(gold_bits)

    if is_near_zero(got) and is_near_zero(gold):
        return True, abs(got.value - gold.value), 0, "near_zero_accepted"

    if not got.is_zero and not got.is_normal:
        return False, float("inf"), 8192, "got_non_normal"

    if not gold.is_zero and not gold.is_normal:
        return False, float("inf"), 8192, "gold_non_normal"

    if is_near_zero(got) != is_near_zero(gold):
        return False, abs(got.value - gold.value), abs(got.log_int - gold.log_int), "zero_near_zero_mismatch"

    if got.sign != gold.sign:
        return False, abs(got.value - gold.value), abs(got.log_int - gold.log_int), "sign_mismatch"

    abs_err = abs(got.value - gold.value)
    log_err = abs(got.log_int - gold.log_int)

    if abs_err <= ABS_TOL:
        return True, abs_err, log_err, "abs_tolerance"

    if log_err <= LOG_LSB_TOL:
        return True, abs_err, log_err, "log_tolerance"

    return False, abs_err, log_err, "log_abs_failed"


def update_bin(b: BinStats, passed: bool, case: str, abs_err: float, log_err: int):
    b.count += 1
    if not passed:
        b.fail_count += 1

    if case == "same_sign":
        b.same_count += 1
        if not passed:
            b.same_fail += 1
    elif case == "opposite_sign":
        b.opp_count += 1
        if not passed:
            b.opp_fail += 1

    b.sum_log_err += log_err
    b.max_log_err = max(b.max_log_err, log_err)

    if math.isfinite(abs_err):
        b.sum_abs_err += abs_err
        b.max_abs_err = max(b.max_abs_err, abs_err)


def empty_bins() -> Dict[int, BinStats]:
    return {d: BinStats() for d in range(NUM_LOGS)}


def load_bins(path: Optional[Path]) -> Dict[int, BinStats]:
    bins = empty_bins()

    if path is None or not path.exists():
        return bins

    with path.open("r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            d = int(row["delta_lsb"])
            bins[d] = BinStats(
                count=int(row["count"]),
                fail_count=int(row["fail_count"]),
                same_count=int(row["same_count"]),
                same_fail=int(row["same_fail"]),
                opp_count=int(row["opposite_count"]),
                opp_fail=int(row["opposite_fail"]),
                sum_log_err=float(row["sum_log_err"]),
                max_log_err=int(row["max_log_err"]),
                sum_abs_err=float(row["sum_abs_err"]),
                max_abs_err=float(row["max_abs_err"]),
            )

    return bins


def save_bins(path: Path, bins: Dict[int, BinStats]):
    with path.open("w", newline="", encoding="utf-8") as f:
        fields = [
            "delta_lsb",
            "count",
            "fail_count",
            "failure_rate",
            "same_count",
            "same_fail",
            "same_failure_rate",
            "opposite_count",
            "opposite_fail",
            "opposite_failure_rate",
            "sum_log_err",
            "mean_log_err",
            "max_log_err",
            "sum_abs_err",
            "mean_abs_err",
            "max_abs_err",
        ]
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()

        for d in range(NUM_LOGS):
            b = bins[d]
            if b.count == 0:
                continue
            w.writerow({
                "delta_lsb": d,
                "count": b.count,
                "fail_count": b.fail_count,
                "failure_rate": b.fail_count / b.count if b.count else 0.0,
                "same_count": b.same_count,
                "same_fail": b.same_fail,
                "same_failure_rate": b.same_fail / b.same_count if b.same_count else 0.0,
                "opposite_count": b.opp_count,
                "opposite_fail": b.opp_fail,
                "opposite_failure_rate": b.opp_fail / b.opp_count if b.opp_count else 0.0,
                "sum_log_err": b.sum_log_err,
                "mean_log_err": b.sum_log_err / b.count if b.count else 0.0,
                "max_log_err": b.max_log_err,
                "sum_abs_err": b.sum_abs_err,
                "mean_abs_err": b.sum_abs_err / b.count if b.count else 0.0,
                "max_abs_err": b.max_abs_err,
            })


def emit_chunk(start_id: int, count: int, out: Path):
    if start_id < 0 or count < 0 or start_id >= TOTAL_PAIRS:
        raise ValueError("Invalid start_id/count")

    end_id = min(TOTAL_PAIRS, start_id + count)

    with out.open("w", encoding="utf-8") as f:
        f.write("# vector_id a_hex b_hex golden_hex delta sign_case\n")
        for pair_id in range(start_id, end_id):
            a_bits, b_bits = pair_from_id(pair_id)
            gold = golden_add(a_bits, b_bits)
            delta, case = delta_and_case(a_bits, b_bits)
            f.write(f"{pair_id} {a_bits:04X} {b_bits:04X} {gold:04X} {delta} {case}\n")

    print(f"Wrote chunk {start_id}..{end_id - 1} ({end_id - start_id} vectors) to {out}")


def iter_results(path: Path, start_id_if_no_id: Optional[int]) -> Iterator[Tuple[int, int]]:
    """
    Accepts:
      vector_id obtained_hex
      0 4000

    or:
      obtained_hex only
      4000
      4200

    If the result file has no vector_id, provide --start-id.
    """
    next_id = start_id_if_no_id

    with path.open("r", encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith("#"):
                continue

            parts = s.replace(",", " ").split()

            if parts[0].lower() in ("vector_id", "id"):
                continue

            if len(parts) >= 2:
                pair_id = int(parts[0])
                got_bits = int(parts[1], 16) & 0xFFFF
            else:
                if next_id is None:
                    raise ValueError("Result file has no vector_id column; use --start-id.")
                pair_id = next_id
                got_bits = int(parts[0], 16) & 0xFFFF
                next_id += 1

            yield pair_id, got_bits


def analyze_chunk(results: Path, bins_in: Optional[Path], bins_out: Path, start_id: Optional[int]):
    bins = load_bins(bins_in)

    total = 0
    fail = 0
    reason_counts = {}

    for pair_id, got_bits in iter_results(results, start_id):
        a_bits, b_bits = pair_from_id(pair_id)
        gold = golden_add(a_bits, b_bits)
        passed, abs_err, log_err, reason = compare(got_bits, gold)

        reason_counts[reason] = reason_counts.get(reason, 0) + 1

        delta, case = delta_and_case(a_bits, b_bits)

        if delta >= 0:
            update_bin(bins[delta], passed, case, abs_err, log_err)

        total += 1
        if not passed:
            fail += 1

    save_bins(bins_out, bins)

    print(f"Analyzed result vectors: {total}")
    print(f"Chunk failures: {fail}")
    print("Reasons:")
    for k in sorted(reason_counts):
        print(f"  {k}: {reason_counts[k]}")
    print(f"Updated bins written to: {bins_out}")


def self_test_chunk(start_id: int, count: int, bins_in: Optional[Path], bins_out: Path):
    bins = load_bins(bins_in)

    end_id = min(TOTAL_PAIRS, start_id + count)

    for pair_id in range(start_id, end_id):
        a_bits, b_bits = pair_from_id(pair_id)
        gold = golden_add(a_bits, b_bits)
        passed, abs_err, log_err, reason = compare(gold, gold)
        delta, case = delta_and_case(a_bits, b_bits)
        if delta >= 0:
            update_bin(bins[delta], passed, case, abs_err, log_err)

    save_bins(bins_out, bins)
    print(f"Self-tested chunk {start_id}..{end_id - 1}; bins written to {bins_out}")


def plot_bins(bins_path: Path, outdir: Path):
    outdir.mkdir(parents=True, exist_ok=True)

    rows = []
    with bins_path.open("r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    xs = [int(r["delta_lsb"]) for r in rows]
    mean_log = [float(r["mean_log_err"]) for r in rows]
    max_log = [float(r["max_log_err"]) for r in rows]
    fail_rate = [float(r["failure_rate"]) for r in rows]
    same_fail = [float(r["same_failure_rate"]) for r in rows]
    opp_fail = [float(r["opposite_failure_rate"]) for r in rows]

    total_count = sum(int(r["count"]) for r in rows)
    total_fail = sum(int(r["fail_count"]) for r in rows)

    summary = [
        "CHUNKED EXHAUSTIVE LNS16 ADD PLOT-1 SUMMARY",
        f"Total accumulated nonzero-pair samples: {total_count}",
        f"Total accumulated failures: {total_fail}",
        f"Failure rate: {total_fail / total_count if total_count else 0:.12%}",
        f"Full exhaustive nonzero-pair target, excluding zero-operand pairs: {(N_VALUES - 1) * (N_VALUES - 1)}",
        f"Full exhaustive ordered ADD target, including zero-operand pairs: {TOTAL_PAIRS}",
    ]
    (outdir / "summary.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")

    plt.figure(figsize=(12, 7))
    plt.plot(xs, mean_log, label="Mean log error")
    plt.plot(xs, max_log, label="Max log error")
    plt.xlabel("Δ = |logA - logB| [LNS LSBs]")
    plt.ylabel("Output log error [LSBs]")
    plt.title("Plot 1 — LNS16 ADD error versus logarithmic distance")
    plt.yscale("symlog", linthresh=1)
    plt.grid(True, which="both", linewidth=0.5)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outdir / "plot1_error_vs_delta.png", dpi=170)
    plt.close()

    plt.figure(figsize=(12, 7))
    plt.plot(xs, fail_rate, label="All nonzero pairs")
    plt.plot(xs, same_fail, label="Same-sign pairs")
    plt.plot(xs, opp_fail, label="Opposite-sign pairs")
    plt.xlabel("Δ = |logA - logB| [LNS LSBs]")
    plt.ylabel("Failure rate")
    plt.title("Plot 1 companion — LNS16 ADD failure rate versus Δ")
    plt.yscale("symlog", linthresh=1e-8)
    plt.grid(True, which="both", linewidth=0.5)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outdir / "plot1_failure_rate_vs_delta.png", dpi=170)
    plt.close()

    print(f"Plots and summary written to: {outdir}")


def main():
    parser = argparse.ArgumentParser(description="Chunked exhaustive LNS16 ADD Plot-1 workflow.")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_emit = sub.add_parser("emit-chunk")
    p_emit.add_argument("--start-id", type=int, required=True)
    p_emit.add_argument("--count", type=int, required=True)
    p_emit.add_argument("--out", required=True)
    p_emit.set_defaults(func=lambda a: emit_chunk(a.start_id, a.count, Path(a.out)))

    p_an = sub.add_parser("analyze-chunk")
    p_an.add_argument("--results", required=True)
    p_an.add_argument("--bins-in", default=None)
    p_an.add_argument("--bins-out", required=True)
    p_an.add_argument("--start-id", type=int, default=None, help="Use only if results file has no vector_id.")
    p_an.set_defaults(
        func=lambda a: analyze_chunk(
            results=Path(a.results),
            bins_in=Path(a.bins_in) if a.bins_in else None,
            bins_out=Path(a.bins_out),
            start_id=a.start_id,
        )
    )

    p_self = sub.add_parser("self-test-chunk")
    p_self.add_argument("--start-id", type=int, required=True)
    p_self.add_argument("--count", type=int, required=True)
    p_self.add_argument("--bins-in", default=None)
    p_self.add_argument("--bins-out", required=True)
    p_self.set_defaults(
        func=lambda a: self_test_chunk(
            start_id=a.start_id,
            count=a.count,
            bins_in=Path(a.bins_in) if a.bins_in else None,
            bins_out=Path(a.bins_out),
        )
    )

    p_plot = sub.add_parser("plot")
    p_plot.add_argument("--bins", required=True)
    p_plot.add_argument("--outdir", required=True)
    p_plot.set_defaults(func=lambda a: plot_bins(Path(a.bins), Path(a.outdir)))

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
