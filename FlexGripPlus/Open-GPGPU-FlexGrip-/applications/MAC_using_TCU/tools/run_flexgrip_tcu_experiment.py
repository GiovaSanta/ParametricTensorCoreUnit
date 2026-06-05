#!/usr/bin/env python3
"""
FlexGrip Plus TCU experiment runner - Version 0.3

Current scope:
  - runs a format-specific experiment generator
  - generates global_mem.mif from the generated matrix experiment file
  - copies global_mem.mif, TP_configuration.vhd, TP_instructions.vhd, and pick_bench.vhd
    into the active FlexGrip Plus RTL/TB folders
  - launches the FlexGrip Plus simulation with:
        vsim -c -do gpgpu_compile.tcl
  - copies gpgpu_rdata.log back into the selected format operands folder
  - extracts the hardware D matrix from gpgpu_rdata.log
  - compares the extracted hardware D matrix against the golden one-shot D matrix
  - writes a decoded-real validation report and per-element CSV

Usage from repository root:
  python FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/tools/run_flexgrip_tcu_experiment.py --format fp16

Usage from MAC_using_TCU:
  python tools/run_flexgrip_tcu_experiment.py --format fp16

Prepare/deploy files only, without running simulation or validation:
  python tools/run_flexgrip_tcu_experiment.py --format fp16 --skip-sim

Run simulation but skip extraction/comparison:
  python tools/run_flexgrip_tcu_experiment.py --format fp16 --skip-validation

Important:
  This script intentionally does NOT create backups.
  It overwrites the active FlexGrip Plus benchmark files.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class FormatConfig:
    name: str
    operands_dir: Path
    experiment_generator: str
    experiment_file: str
    global_mem_generator: str
    tp_configuration_file: str = "TP_configuration.vhd"
    tp_instructions_file: str = "TP_instructions.vhd"
    pick_bench_file: str = "pick_bench.vhd"
    decoded_compare_format: str | None = None
    golden_label: str = "#FULL_D_16x16_one_shot_reference encoded"


REPO_REL_FLEXGRIP_ROOT = Path("FlexGripPlus/Open-GPGPU-FlexGrip-/FlexGripPlus_4.4")
REPO_REL_MAC_APP_ROOT = Path("FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU")
REPO_REL_TOOLS_DIR = REPO_REL_MAC_APP_ROOT / "tools"

ACTIVE_TP_DIR = REPO_REL_FLEXGRIP_ROOT / "RTL/TB/TP"
ACTIVE_CONFIG_DIR = REPO_REL_FLEXGRIP_ROOT / "RTL/TB/configuration"
SIM_DIR = REPO_REL_FLEXGRIP_ROOT / "lib_m"
SIM_TCL_FILE = "gpgpu_compile.tcl"
SIM_OUTPUT_LOG = "gpgpu_rdata.log"

EXTRACT_SCRIPT = "extract_flexgrip_d_matrix.py"
COMPARE_SCRIPT = "compare_flexgrip_d_matrix.py"

HW_D_MATRIX_FILE = "hw_D_matrix_extracted.txt"
VALIDATION_REPORT_FILE = "validation_report.txt"
VALIDATION_CSV_FILE = "validation_element_errors.csv"


FORMAT_CONFIGS = {
    "fp16": FormatConfig(
        name="fp16",
        operands_dir=REPO_REL_MAC_APP_ROOT / "fp16operands",
        experiment_generator="generate_fp16_experiment.py",
        experiment_file="hmma_8instr_dualTC_4octects_fp16_single_experiment.txt",
        global_mem_generator="generate_flexgrip_16bit_global_mem.py",
        decoded_compare_format="fp16",
    ),

    # LNS16 is kept in the config for preparation/simulation reuse, but decoded
    # validation is intentionally disabled until an LNS16 decoder is added to
    # compare_flexgrip_d_matrix.py.
    "lns16": FormatConfig(
        name="lns16",
        operands_dir=REPO_REL_MAC_APP_ROOT / "LNS16operands",
        experiment_generator="generate_lns16_experiment.py",
        experiment_file="hmma_8instr_dualTC_4octects_lns16_single_experiment.txt",
        global_mem_generator="generate_flexgrip_16bit_global_mem.py",
        decoded_compare_format="lns16",
    ),
}


def print_step(message: str) -> None:
    print()
    print("=" * 80)
    print(message)
    print("=" * 80)


def repo_root_from_script() -> Path:
    """
    This script is expected to live in:
      FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/tools/

    Therefore, repository root is five parents above this file:
      tools -> MAC_using_TCU -> applications -> Open-GPGPU-FlexGrip- -> FlexGripPlus -> repo root
    """
    return Path(__file__).resolve().parents[5]


def ensure_file(path: Path, description: str) -> None:
    if not path.is_file():
        raise FileNotFoundError(f"Missing {description}: {path}")


def ensure_dir(path: Path, description: str) -> None:
    if not path.is_dir():
        raise FileNotFoundError(f"Missing {description}: {path}")


def run_command(
    cmd: list[str | Path],
    cwd: Path,
    timeout_seconds: int | None = None,
) -> None:
    printable_cmd = " ".join(str(x) for x in cmd)

    print(f"Working directory: {cwd}")
    print("Command:")
    print(f"  {printable_cmd}")

    try:
        completed = subprocess.run(
            [str(x) for x in cmd],
            cwd=str(cwd),
            timeout=timeout_seconds,
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(
            f"Command timed out after {timeout_seconds} seconds: {printable_cmd}"
        ) from exc

    if completed.returncode != 0:
        raise RuntimeError(
            f"Command failed with return code {completed.returncode}: {printable_cmd}"
        )


def run_experiment_generator(repo_root: Path, cfg: FormatConfig) -> Path:
    print_step(f"Step 1 - Generate new {cfg.name.upper()} experiment file")

    operands_dir = repo_root / cfg.operands_dir
    generator_path = operands_dir / cfg.experiment_generator
    experiment_path = operands_dir / cfg.experiment_file

    ensure_dir(operands_dir, "format operands directory")
    ensure_file(generator_path, "format experiment generator")

    run_command([sys.executable, generator_path.name], cwd=operands_dir)

    ensure_file(experiment_path, "generated experiment file")

    print(f"Generated experiment file found: {experiment_path}")
    return experiment_path


def generate_global_mem(repo_root: Path, cfg: FormatConfig, experiment_path: Path) -> Path:
    print_step("Step 2 - Generate global_mem.mif from encoded A/B/C matrices")

    tools_dir = repo_root / REPO_REL_TOOLS_DIR
    global_mem_generator = tools_dir / cfg.global_mem_generator
    operands_dir = repo_root / cfg.operands_dir
    global_mem_path = operands_dir / "global_mem.mif"

    ensure_file(global_mem_generator, "global_mem.mif generator script")

    run_command(
        [
            sys.executable,
            global_mem_generator,
            "--input",
            experiment_path,
            "--output",
            global_mem_path,
        ],
        cwd=repo_root,
    )

    ensure_file(global_mem_path, "generated global_mem.mif")

    print(f"Generated global_mem.mif: {global_mem_path}")
    return global_mem_path


def copy_required_files(repo_root: Path, cfg: FormatConfig, global_mem_path: Path) -> None:
    print_step("Step 3 - Copy benchmark files into active FlexGrip Plus RTL/TB folders")

    operands_dir = repo_root / cfg.operands_dir
    active_tp_dir = repo_root / ACTIVE_TP_DIR
    active_config_dir = repo_root / ACTIVE_CONFIG_DIR

    ensure_dir(active_tp_dir, "active RTL/TB/TP directory")
    ensure_dir(active_config_dir, "active RTL/TB/configuration directory")

    source_tp_configuration = operands_dir / cfg.tp_configuration_file
    source_tp_instructions = operands_dir / cfg.tp_instructions_file
    source_pick_bench = operands_dir / cfg.pick_bench_file

    ensure_file(global_mem_path, "source global_mem.mif")
    ensure_file(source_tp_configuration, "source TP_configuration.vhd")
    ensure_file(source_tp_instructions, "source TP_instructions.vhd")
    ensure_file(source_pick_bench, "source pick_bench.vhd")

    copy_jobs = [
        (global_mem_path, active_tp_dir / "global_mem.mif"),
        (source_tp_configuration, active_tp_dir / "TP_configuration.vhd"),
        (source_tp_instructions, active_tp_dir / "TP_instructions.vhd"),
        (source_pick_bench, active_config_dir / "pick_bench.vhd"),
    ]

    for src, dst in copy_jobs:
        print("Copying:")
        print(f"  from: {src}")
        print(f"  to:   {dst}")
        shutil.copy2(src, dst)

    print()
    print("Active FlexGrip Plus benchmark files updated.")


def run_flexgrip_simulation(repo_root: Path, timeout_seconds: int | None) -> Path:
    print_step("Step 4 - Run FlexGrip Plus simulation")

    sim_dir = repo_root / SIM_DIR
    sim_tcl_path = sim_dir / SIM_TCL_FILE
    sim_output_path = sim_dir / SIM_OUTPUT_LOG

    ensure_dir(sim_dir, "FlexGrip Plus simulation/lib_m directory")
    ensure_file(sim_tcl_path, "gpgpu_compile.tcl simulation script")

    # Remove old output first so that a stale file cannot be mistaken for a new result.
    if sim_output_path.exists():
        print(f"Removing previous simulation output: {sim_output_path}")
        sim_output_path.unlink()

    run_command(
        ["vsim", "-c", "-do", SIM_TCL_FILE],
        cwd=sim_dir,
        timeout_seconds=timeout_seconds,
    )

    ensure_file(sim_output_path, "simulation output gpgpu_rdata.log")

    print(f"Simulation output generated: {sim_output_path}")
    return sim_output_path


def copy_simulation_output_to_operands(repo_root: Path, cfg: FormatConfig, sim_output_path: Path) -> Path:
    print_step("Step 5 - Copy gpgpu_rdata.log back into the format operands folder")

    operands_dir = repo_root / cfg.operands_dir
    ensure_dir(operands_dir, "format operands directory")
    ensure_file(sim_output_path, "simulation output gpgpu_rdata.log")

    destination = operands_dir / SIM_OUTPUT_LOG

    print("Copying:")
    print(f"  from: {sim_output_path}")
    print(f"  to:   {destination}")

    shutil.copy2(sim_output_path, destination)

    ensure_file(destination, "copied gpgpu_rdata.log in operands folder")

    print(f"Copied simulation output: {destination}")
    return destination


def extract_hardware_d_matrix(repo_root: Path, cfg: FormatConfig, rdata_log_path: Path) -> Path:
    print_step("Step 6 - Extract hardware D matrix from gpgpu_rdata.log")

    tools_dir = repo_root / REPO_REL_TOOLS_DIR
    extract_script = tools_dir / EXTRACT_SCRIPT

    operands_dir = repo_root / cfg.operands_dir
    hw_d_matrix_path = operands_dir / HW_D_MATRIX_FILE

    ensure_file(extract_script, "hardware D matrix extractor script")
    ensure_file(rdata_log_path, "gpgpu_rdata.log")

    run_command(
        [
            sys.executable,
            extract_script,
            "--input",
            rdata_log_path,
            "--output",
            hw_d_matrix_path,
        ],
        cwd=repo_root,
    )

    ensure_file(hw_d_matrix_path, "extracted hardware D matrix")

    print(f"Extracted hardware D matrix: {hw_d_matrix_path}")
    return hw_d_matrix_path


def compare_against_golden(
    repo_root: Path,
    cfg: FormatConfig,
    experiment_path: Path,
    hw_d_matrix_path: Path,
) -> tuple[Path, Path] | None:
    print_step("Step 7 - Compare hardware D matrix against golden one-shot D matrix")

    if cfg.decoded_compare_format is None:
        print(
            f"Decoded-real comparison is not configured for format {cfg.name!r}. "
            "Skipping comparison."
        )
        return None

    tools_dir = repo_root / REPO_REL_TOOLS_DIR
    compare_script = tools_dir / COMPARE_SCRIPT

    operands_dir = repo_root / cfg.operands_dir
    report_path = operands_dir / VALIDATION_REPORT_FILE
    csv_path = operands_dir / VALIDATION_CSV_FILE

    ensure_file(compare_script, "D matrix comparison script")
    ensure_file(experiment_path, "golden experiment file")
    ensure_file(hw_d_matrix_path, "extracted hardware D matrix file")

    run_command(
        [
            sys.executable,
            compare_script,
            "--format",
            cfg.decoded_compare_format,
            "--golden-file",
            experiment_path,
            "--hw-file",
            hw_d_matrix_path,
            "--output-report",
            report_path,
            "--output-csv",
            csv_path,
            "--golden-label",
            cfg.golden_label,
        ],
        cwd=repo_root,
    )

    ensure_file(report_path, "validation report")
    ensure_file(csv_path, "validation per-element CSV")

    print(f"Validation report: {report_path}")
    print(f"Validation CSV:    {csv_path}")

    return report_path, csv_path


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run a FlexGrip Plus TCU experiment flow for a selected numeric format."
    )
    parser.add_argument(
        "--format",
        required=True,
        choices=sorted(FORMAT_CONFIGS.keys()),
        help="Numeric format / benchmark configuration to run.",
    )
    parser.add_argument(
        "--skip-sim",
        action="store_true",
        help="Only generate/deploy benchmark files; do not run vsim or validation.",
    )
    parser.add_argument(
        "--skip-validation",
        action="store_true",
        help="Run simulation but skip extraction/comparison.",
    )
    parser.add_argument(
        "--sim-timeout",
        type=int,
        default=None,
        help=(
            "Optional maximum simulation time in seconds. "
            "Default: no timeout."
        ),
    )

    args = parser.parse_args()

    repo_root = repo_root_from_script()
    cfg = FORMAT_CONFIGS[args.format]

    print("FlexGrip Plus TCU experiment runner - Version 0.3")
    print(f"Repository root: {repo_root}")
    print(f"Selected format: {cfg.name}")
    print(f"Skip simulation: {args.skip_sim}")
    print(f"Skip validation: {args.skip_validation}")
    print(f"Simulation timeout: {args.sim_timeout}")

    experiment_path = run_experiment_generator(repo_root, cfg)
    global_mem_path = generate_global_mem(repo_root, cfg, experiment_path)
    copy_required_files(repo_root, cfg, global_mem_path)

    validation_outputs = None

    if not args.skip_sim:
        sim_output_path = run_flexgrip_simulation(
            repo_root,
            timeout_seconds=args.sim_timeout,
        )
        copied_rdata_log = copy_simulation_output_to_operands(
            repo_root,
            cfg,
            sim_output_path,
        )

        if not args.skip_validation:
            hw_d_matrix_path = extract_hardware_d_matrix(
                repo_root,
                cfg,
                copied_rdata_log,
            )
            validation_outputs = compare_against_golden(
                repo_root,
                cfg,
                experiment_path,
                hw_d_matrix_path,
            )
        else:
            print_step("Validation skipped")
            print("Simulation completed, but extraction/comparison were not launched.")
    else:
        print_step("Simulation skipped")
        print("The active FlexGrip Plus benchmark files are ready, but vsim was not launched.")

    print_step("Version 0.3 completed successfully")
    print("Done.")

    if args.skip_sim:
        print("Generated/deployed benchmark files only.")
    elif args.skip_validation:
        print(f"Simulation log copied to: {repo_root / cfg.operands_dir / SIM_OUTPUT_LOG}")
    elif validation_outputs is not None:
        report_path, csv_path = validation_outputs
        print(f"Validation report: {report_path}")
        print(f"Validation CSV:    {csv_path}")
    else:
        print("Simulation completed. Decoded validation was skipped for this format.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
