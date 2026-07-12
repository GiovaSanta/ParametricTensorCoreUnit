#!/usr/bin/env python3
import argparse
import csv
import math
import re
import statistics
from collections import defaultdict
from pathlib import Path

HEX16 = re.compile(r"^[0-9A-F]{4}$")

def read_hex16_lines(path):
    values = [
        line.strip().upper()
        for line in Path(path).read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    for line_number, value in enumerate(values, start=1):
        if not HEX16.fullmatch(value):
            raise ValueError(
                f"{path}, line {line_number}: expected four hex digits, found {value!r}."
            )
    return values

def lns_kind(hex_value):
    top = (int(hex_value, 16) >> 14) & 0b11
    return {
        0b00: "Zero class",
        0b01: "Normal",
        0b10: "Special 10",
        0b11: "Special 11",
    }[top]

def percentage(count, denominator):
    return 0.0 if denominator == 0 else 100.0 * count / denominator

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default="lns16_input_faults_100/fault_manifest.csv")
    parser.add_argument("--golden", default="lns16_results_100/golden_results.txt")
    parser.add_argument("--faulty", default="lns16_results_100/faulty_results.txt")
    parser.add_argument("--classification", default="lns16_results_100/fault_classification.csv")
    parser.add_argument("--overall-summary", default="lns16_results_100/fault_summary_overall.csv")
    parser.add_argument("--vector-summary", default="lns16_results_100/fault_summary_by_vector.csv")
    parser.add_argument("--site-summary", default="lns16_results_100/fault_summary_by_operand_bit.csv")
    args = parser.parse_args()

    golden_values = read_hex16_lines(args.golden)
    faulty_values = read_hex16_lines(args.faulty)

    with open(args.manifest, newline="", encoding="utf-8") as manifest_file:
        manifest_rows = list(csv.DictReader(manifest_file))
    manifest_rows.sort(key=lambda row: int(row["row"]))

    if len(manifest_rows) != len(faulty_values):
        raise ValueError(
            f"Manifest has {len(manifest_rows)} rows, "
            f"but faulty results has {len(faulty_values)} values."
        )

    vector_ids = sorted({int(row["vector_id"]) for row in manifest_rows})
    if vector_ids != list(range(len(golden_values))):
        raise ValueError("Manifest vector IDs do not match golden outputs.")

    overall = defaultdict(int)
    per_vector = defaultdict(lambda: defaultdict(int))
    per_site = defaultdict(lambda: defaultdict(int))
    classification_rows = []

    for row, faulty in zip(manifest_rows, faulty_values):
        vector_id = int(row["vector_id"])
        golden = golden_values[vector_id]
        activated = row["activated"].strip().lower() == "true"

        if not activated:
            fault_class = "Not activated"
        elif faulty == golden:
            fault_class = "Masked"
        else:
            fault_class = "SDC"

        if not activated and faulty != golden:
            raise RuntimeError(
                f"Nonactivated case changed output at manifest row {row['row']}."
            )

        overall["total_cases"] += 1
        per_vector[vector_id]["total_cases"] += 1
        site_key = (row["target"], int(row["bit"]), int(row["stuck_at"]))
        per_site[site_key]["total_cases"] += 1

        kind = lns_kind(faulty)
        if kind == "Zero class":
            overall["faulty_zero_class_results"] += 1
        elif kind == "Special 10":
            overall["faulty_special_10_results"] += 1
        elif kind == "Special 11":
            overall["faulty_special_11_results"] += 1

        if fault_class == "Not activated":
            key = "not_activated"
            overall[key] += 1
            per_vector[vector_id][key] += 1
            per_site[site_key][key] += 1
        else:
            overall["activated_cases"] += 1
            per_vector[vector_id]["activated_cases"] += 1
            per_site[site_key]["activated_cases"] += 1

            if fault_class == "Masked":
                key = "activated_masked"
            else:
                key = "activated_sdc"
            overall[key] += 1
            per_vector[vector_id][key] += 1
            per_site[site_key][key] += 1

        classification_rows.append({
            **row,
            "golden": golden,
            "golden_kind": lns_kind(golden),
            "faulty_result": faulty,
            "faulty_kind": kind,
            "class": fault_class,
        })

    classification_path = Path(args.classification)
    overall_path = Path(args.overall_summary)
    vector_path = Path(args.vector_summary)
    site_path = Path(args.site_summary)

    for path in [classification_path, overall_path, vector_path, site_path]:
        path.parent.mkdir(parents=True, exist_ok=True)

    with classification_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=classification_rows[0].keys())
        writer.writeheader()
        writer.writerows(classification_rows)

    vector_rows = []
    for vector_id in vector_ids:
        data = per_vector[vector_id]
        vector_rows.append({
            "vector_id": vector_id,
            "golden": golden_values[vector_id],
            "golden_kind": lns_kind(golden_values[vector_id]),
            "total_cases": data["total_cases"],
            "not_activated": data["not_activated"],
            "activated_cases": data["activated_cases"],
            "activated_masked": data["activated_masked"],
            "activated_sdc": data["activated_sdc"],
            "activated_masked_percent": f"{percentage(data['activated_masked'], data['activated_cases']):.6f}",
            "activated_sdc_percent": f"{percentage(data['activated_sdc'], data['activated_cases']):.6f}",
        })

    with vector_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=vector_rows[0].keys())
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
            "activated_sdc_percent": f"{percentage(data['activated_sdc'], data['activated_cases']):.6f}",
        })

    with site_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=site_rows[0].keys())
        writer.writeheader()
        writer.writerows(site_rows)

    rates = [float(row["activated_sdc_percent"]) for row in vector_rows]
    mean_rate = statistics.mean(rates)
    stdev_rate = statistics.stdev(rates) if len(rates) > 1 else 0.0
    se = stdev_rate / math.sqrt(len(rates))
    ci_low = mean_rate - 1.96 * se
    ci_high = mean_rate + 1.96 * se

    overall_rows = [
        ["num_vectors", len(golden_values), ""],
        ["total_cases", overall["total_cases"], "100.000000"],
        ["not_activated", overall["not_activated"], f"{percentage(overall['not_activated'], overall['total_cases']):.6f}"],
        ["activated_cases", overall["activated_cases"], f"{percentage(overall['activated_cases'], overall['total_cases']):.6f}"],
        ["activated_masked", overall["activated_masked"], f"{percentage(overall['activated_masked'], overall['activated_cases']):.6f}"],
        ["activated_sdc", overall["activated_sdc"], f"{percentage(overall['activated_sdc'], overall['activated_cases']):.6f}"],
        ["faulty_zero_class_results", overall["faulty_zero_class_results"], f"{percentage(overall['faulty_zero_class_results'], overall['total_cases']):.6f}"],
        ["faulty_special_10_results", overall["faulty_special_10_results"], f"{percentage(overall['faulty_special_10_results'], overall['total_cases']):.6f}"],
        ["faulty_special_11_results", overall["faulty_special_11_results"], f"{percentage(overall['faulty_special_11_results'], overall['total_cases']):.6f}"],
        ["mean_vector_activated_sdc_percent", "", f"{mean_rate:.6f}"],
        ["stdev_vector_activated_sdc_percent", "", f"{stdev_rate:.6f}"],
        ["standard_error_vector_sdc_percent", "", f"{se:.6f}"],
        ["approx_95ci_low_percent", "", f"{ci_low:.6f}"],
        ["approx_95ci_high_percent", "", f"{ci_high:.6f}"],
        ["min_vector_activated_sdc_percent", "", f"{min(rates):.6f}"],
        ["max_vector_activated_sdc_percent", "", f"{max(rates):.6f}"],
    ]

    with overall_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.writer(output_file)
        writer.writerow(["metric", "count", "percentage"])
        writer.writerows(overall_rows)

    print(f"Vectors:           {len(golden_values)}")
    print(f"Total cases:       {overall['total_cases']}")
    print(f"Not activated:     {overall['not_activated']}")
    print(f"Activated cases:   {overall['activated_cases']}")
    print(f"Activated masked:  {overall['activated_masked']} ({percentage(overall['activated_masked'], overall['activated_cases']):.2f}%)")
    print(f"Activated SDC:     {overall['activated_sdc']} ({percentage(overall['activated_sdc'], overall['activated_cases']):.2f}%)")
    print(f"Per-vector SDC:    mean={mean_rate:.2f}%, stdev={stdev_rate:.2f}%, min={min(rates):.2f}%, max={max(rates):.2f}%")
    print(f"Approx. 95% CI:    {ci_low:.2f}% to {ci_high:.2f}%")
    print(f"Faulty zero-class results:{overall['faulty_zero_class_results']:>7}")
    print(f"Faulty special-10 results:{overall['faulty_special_10_results']:>4}")
    print(f"Faulty special-11 results:{overall['faulty_special_11_results']:>4}")
    print(f"Classification:    {classification_path}")
    print(f"Overall summary:   {overall_path}")
    print(f"Vector summary:    {vector_path}")
    print(f"Site summary:      {site_path}")

if __name__ == "__main__":
    main()
