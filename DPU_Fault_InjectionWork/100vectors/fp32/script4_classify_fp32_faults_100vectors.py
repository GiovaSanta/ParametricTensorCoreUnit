#!/usr/bin/env python3
import argparse
import csv
import math
import re
import statistics
from collections import defaultdict
from pathlib import Path

HEX32 = re.compile(r"^[0-9A-F]{8}$")


def read_hex32_lines(path):
    values = [
        line.strip().upper()
        for line in Path(path).read_text(
            encoding="utf-8"
        ).splitlines()
        if line.strip()
    ]

    for line_number, value in enumerate(values, start=1):
        if not HEX32.fullmatch(value):
            raise ValueError(
                f"{path}, line {line_number}: expected an "
                f"eight-digit hexadecimal result, found {value!r}."
            )

    return values


def fp32_kind(hex_value):
    raw = int(hex_value, 16)
    exponent = (raw >> 23) & 0xFF
    fraction = raw & 0x7FFFFF

    if exponent == 0:
        return "Zero" if fraction == 0 else "Subnormal"

    if exponent == 0xFF:
        return "Infinity" if fraction == 0 else "NaN"

    return "Normal"


def percentage(count, denominator):
    if denominator == 0:
        return 0.0
    return 100.0 * count / denominator


parser = argparse.ArgumentParser()
parser.add_argument(
    "--manifest",
    default="fp32_input_faults_100/fault_manifest.csv",
)
parser.add_argument(
    "--golden",
    default="fp32_results_100/golden_results.txt",
)
parser.add_argument(
    "--faulty",
    default="fp32_results_100/faulty_results.txt",
)
parser.add_argument(
    "--classification",
    default="fp32_results_100/fault_classification.csv",
)
parser.add_argument(
    "--overall-summary",
    default="fp32_results_100/fault_summary_overall.csv",
)
parser.add_argument(
    "--vector-summary",
    default="fp32_results_100/fault_summary_by_vector.csv",
)
parser.add_argument(
    "--site-summary",
    default="fp32_results_100/fault_summary_by_operand_bit.csv",
)
args = parser.parse_args()

golden_values = read_hex32_lines(args.golden)
faulty_values = read_hex32_lines(args.faulty)

with open(
    args.manifest,
    newline="",
    encoding="utf-8",
) as manifest_file:
    manifest_rows = list(csv.DictReader(manifest_file))

manifest_rows.sort(key=lambda row: int(row["row"]))

if len(manifest_rows) != len(faulty_values):
    raise ValueError(
        f"Manifest has {len(manifest_rows)} rows, "
        f"but faulty results has "
        f"{len(faulty_values)} values."
    )

vector_ids = sorted({
    int(row["vector_id"])
    for row in manifest_rows
})

if vector_ids != list(range(len(golden_values))):
    raise ValueError(
        "Manifest vector IDs must be consecutive and match "
        "the number of golden outputs."
    )

overall = defaultdict(int)
per_vector = defaultdict(lambda: defaultdict(int))
per_site = defaultdict(lambda: defaultdict(int))
classification_rows = []

for row, faulty in zip(manifest_rows, faulty_values):
    vector_id = int(row["vector_id"])
    golden = golden_values[vector_id]
    activated = (
        row["activated"].strip().lower() == "true"
    )
    faulty_kind = fp32_kind(faulty)

    if not activated:
        fault_class = "Not activated"
    elif faulty == golden:
        fault_class = "Masked"
    else:
        fault_class = "SDC"

    if not activated and faulty != golden:
        raise RuntimeError(
            "A nonactivated case changed the output. "
            f"Manifest row {row['row']} is inconsistent."
        )

    overall["total_cases"] += 1
    per_vector[vector_id]["total_cases"] += 1

    site_key = (
        row["target"],
        int(row["bit"]),
        int(row["stuck_at"]),
    )
    per_site[site_key]["total_cases"] += 1

    overall[f"faulty_{faulty_kind.lower()}_results"] += 1

    if fault_class == "Not activated":
        overall["not_activated"] += 1
        per_vector[vector_id]["not_activated"] += 1
        per_site[site_key]["not_activated"] += 1
    else:
        overall["activated_cases"] += 1
        per_vector[vector_id]["activated_cases"] += 1
        per_site[site_key]["activated_cases"] += 1

        if fault_class == "Masked":
            overall["activated_masked"] += 1
            per_vector[vector_id]["activated_masked"] += 1
            per_site[site_key]["activated_masked"] += 1
        else:
            overall["activated_sdc"] += 1
            per_vector[vector_id]["activated_sdc"] += 1
            per_site[site_key]["activated_sdc"] += 1

    classification_rows.append({
        **row,
        "golden": golden,
        "golden_kind": fp32_kind(golden),
        "faulty_result": faulty,
        "faulty_kind": faulty_kind,
        "class": fault_class,
    })

classification_path = Path(args.classification)
overall_path = Path(args.overall_summary)
vector_path = Path(args.vector_summary)
site_path = Path(args.site_summary)

for path in [
    classification_path,
    overall_path,
    vector_path,
    site_path,
]:
    path.parent.mkdir(parents=True, exist_ok=True)

with classification_path.open(
    "w", newline="", encoding="utf-8"
) as output_file:
    writer = csv.DictWriter(
        output_file,
        fieldnames=classification_rows[0].keys(),
    )
    writer.writeheader()
    writer.writerows(classification_rows)

vector_rows = []

for vector_id in vector_ids:
    data = per_vector[vector_id]

    vector_rows.append({
        "vector_id": vector_id,
        "golden": golden_values[vector_id],
        "golden_kind": fp32_kind(golden_values[vector_id]),
        "total_cases": data["total_cases"],
        "not_activated": data["not_activated"],
        "activated_cases": data["activated_cases"],
        "activated_masked": data["activated_masked"],
        "activated_sdc": data["activated_sdc"],
        "activated_masked_percent": (
            f"{percentage(
                data['activated_masked'],
                data['activated_cases']
            ):.6f}"
        ),
        "activated_sdc_percent": (
            f"{percentage(
                data['activated_sdc'],
                data['activated_cases']
            ):.6f}"
        ),
    })

with vector_path.open(
    "w", newline="", encoding="utf-8"
) as output_file:
    writer = csv.DictWriter(
        output_file,
        fieldnames=vector_rows[0].keys(),
    )
    writer.writeheader()
    writer.writerows(vector_rows)

site_rows = []

for target, bit, stuck_at in sorted(per_site):
    data = per_site[(target, bit, stuck_at)]

    site_rows.append({
        "target": target,
        "bit": bit,
        "stuck_at": stuck_at,
        "total_cases": data["total_cases"],
        "not_activated": data["not_activated"],
        "activated_cases": data["activated_cases"],
        "activated_masked": data["activated_masked"],
        "activated_sdc": data["activated_sdc"],
        "activated_sdc_percent": (
            f"{percentage(
                data['activated_sdc'],
                data['activated_cases']
            ):.6f}"
        ),
    })

with site_path.open(
    "w", newline="", encoding="utf-8"
) as output_file:
    writer = csv.DictWriter(
        output_file,
        fieldnames=site_rows[0].keys(),
    )
    writer.writeheader()
    writer.writerows(site_rows)

vector_sdc_rates = [
    float(row["activated_sdc_percent"])
    for row in vector_rows
]

mean_vector_sdc = statistics.mean(vector_sdc_rates)
stdev_vector_sdc = (
    statistics.stdev(vector_sdc_rates)
    if len(vector_sdc_rates) > 1
    else 0.0
)
standard_error = stdev_vector_sdc / math.sqrt(
    len(vector_sdc_rates)
)
approx_ci_low = mean_vector_sdc - 1.96 * standard_error
approx_ci_high = mean_vector_sdc + 1.96 * standard_error

overall_rows = [
    ["num_vectors", len(golden_values), ""],
    ["total_cases", overall["total_cases"], "100.000000"],
    [
        "not_activated",
        overall["not_activated"],
        f"{percentage(
            overall['not_activated'],
            overall['total_cases']
        ):.6f}",
    ],
    [
        "activated_cases",
        overall["activated_cases"],
        f"{percentage(
            overall['activated_cases'],
            overall['total_cases']
        ):.6f}",
    ],
    [
        "activated_masked",
        overall["activated_masked"],
        f"{percentage(
            overall['activated_masked'],
            overall['activated_cases']
        ):.6f}",
    ],
    [
        "activated_sdc",
        overall["activated_sdc"],
        f"{percentage(
            overall['activated_sdc'],
            overall['activated_cases']
        ):.6f}",
    ],
    [
        "faulty_nan_results",
        overall["faulty_nan_results"],
        f"{percentage(
            overall['faulty_nan_results'],
            overall['total_cases']
        ):.6f}",
    ],
    [
        "faulty_infinity_results",
        overall["faulty_infinity_results"],
        f"{percentage(
            overall['faulty_infinity_results'],
            overall['total_cases']
        ):.6f}",
    ],
    [
        "faulty_subnormal_results",
        overall["faulty_subnormal_results"],
        f"{percentage(
            overall['faulty_subnormal_results'],
            overall['total_cases']
        ):.6f}",
    ],
    [
        "faulty_zero_results",
        overall["faulty_zero_results"],
        f"{percentage(
            overall['faulty_zero_results'],
            overall['total_cases']
        ):.6f}",
    ],
    [
        "mean_vector_activated_sdc_percent",
        "",
        f"{mean_vector_sdc:.6f}",
    ],
    [
        "stdev_vector_activated_sdc_percent",
        "",
        f"{stdev_vector_sdc:.6f}",
    ],
    [
        "standard_error_vector_sdc_percent",
        "",
        f"{standard_error:.6f}",
    ],
    [
        "approx_95ci_low_percent",
        "",
        f"{approx_ci_low:.6f}",
    ],
    [
        "approx_95ci_high_percent",
        "",
        f"{approx_ci_high:.6f}",
    ],
    [
        "min_vector_activated_sdc_percent",
        "",
        f"{min(vector_sdc_rates):.6f}",
    ],
    [
        "max_vector_activated_sdc_percent",
        "",
        f"{max(vector_sdc_rates):.6f}",
    ],
]

with overall_path.open(
    "w", newline="", encoding="utf-8"
) as output_file:
    writer = csv.writer(output_file)
    writer.writerow(["metric", "count", "percentage"])
    writer.writerows(overall_rows)

print(f"Vectors:           {len(golden_values)}")
print(f"Total cases:       {overall['total_cases']}")
print(f"Not activated:     {overall['not_activated']}")
print(f"Activated cases:   {overall['activated_cases']}")
print(
    f"Activated masked:  "
    f"{overall['activated_masked']} "
    f"({percentage(
        overall['activated_masked'],
        overall['activated_cases']
    ):.2f}%)"
)
print(
    f"Activated SDC:     {overall['activated_sdc']} "
    f"({percentage(
        overall['activated_sdc'],
        overall['activated_cases']
    ):.2f}%)"
)
print(
    f"Per-vector SDC:    mean={mean_vector_sdc:.2f}%, "
    f"stdev={stdev_vector_sdc:.2f}%, "
    f"min={min(vector_sdc_rates):.2f}%, "
    f"max={max(vector_sdc_rates):.2f}%"
)
print(
    f"Approx. 95% CI:    "
    f"{approx_ci_low:.2f}% to "
    f"{approx_ci_high:.2f}%"
)
print(f"Faulty NaN results:       {overall['faulty_nan_results']}")
print(f"Faulty Infinity results:  {overall['faulty_infinity_results']}")
print(f"Faulty Subnormal results: {overall['faulty_subnormal_results']}")
print(f"Classification:    {classification_path}")
print(f"Overall summary:   {overall_path}")
print(f"Vector summary:    {vector_path}")
print(f"Site summary:      {site_path}")
