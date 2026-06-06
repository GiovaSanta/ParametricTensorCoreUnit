#!/usr/bin/env python3
"""
Klessydra TCU experiment runner - Version 0.7

Initial FP16 backend.

Current implemented flow:
  1. Generate the FP16 experiment using the existing FlexGrip-compatible generator.
  2. Patch the Klessydra TCUopFP16.c embedded matrices:
       A   <- FULL_A_16x16 encoded, row-major
       B_T <- transpose(FULL_B_16x16 encoded)
       C   <- FULL_C_16x16 encoded, row-major
       D   <- zero-initialized
     and also emit golden_D_matrix.txt from FULL_D_16x16_one_shot_reference.
  3. Run the Klessydra simulation with make TCUopFP16.vsimc.
  4. Validate only if a hardware D matrix file already exists or if a future
     extraction script is available.

Important:
  This runner does NOT modify the C benchmark to print D.
  D extraction is deliberately separated into a future non-invasive backend.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple


REPO_MARKERS = ("pulpino-klessydra", "FlexGripPlus")


@dataclass(frozen=True)
class FormatConfig:
    name: str
    generator_script: Path
    experiment_file: Path
    patcher_script_names: Tuple[Path, ...]
    c_file: Path
    golden_out: Path
    make_target: str
    compare_format: str
    final_slm_file: Path
    hw_matrix_file: Path
    validation_report: Path
    validation_csv: Path


FORMAT_CONFIGS = {
    "fp16": FormatConfig(
        name="fp16",
        generator_script=Path(
            "FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/"
            "fp16operands/generate_fp16_experiment.py"
        ),
        experiment_file=Path(
            "FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/"
            "fp16operands/hmma_8instr_dualTC_4octects_fp16_single_experiment.txt"
        ),
        patcher_script_names=(
            Path("tools/klessydra/patch_klessydra_fp16_c_from_experiment.py"),
            Path(
                "pulpino-klessydra/sw/apps/klessydra_tests/"
                "klessydra_tcu_tests/tools/patch_klessydra_fp16_c_from_experiment.py"
            ),
        ),
        c_file=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopFP16/TCUopFP16.c"
        ),
        golden_out=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopFP16/golden_D_matrix.txt"
        ),
        make_target="TCUopFP16.vsimc",
        compare_format="fp16",
        final_slm_file=Path(
            "pulpino-klessydra/sw/build/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopFP16/slm_files/final_touched_words.slm"
        ),
        hw_matrix_file=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopFP16/hw_D_matrix_extracted.txt"
        ),
        validation_report=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopFP16/validation_report.txt"
        ),
        validation_csv=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopFP16/validation_element_errors.csv"
        ),
    ),
    "posit16": FormatConfig(
        name="posit16",
        generator_script=Path(
            "FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/"
            "softPosit16_1operands/generate_posit16_experiment.py"
        ),
        experiment_file=Path(
            "FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/"
            "softPosit16_1operands/hmma_8instr_dualTC_4octects_posit16_single_experiment.txt"
        ),
        patcher_script_names=(
            Path("tools/klessydra/patch_klessydra_posit16_c_from_experiment.py"),
            Path(
                "pulpino-klessydra/sw/apps/klessydra_tests/"
                "klessydra_tcu_tests/tools/patch_klessydra_posit16_c_from_experiment.py"
            ),
        ),
        c_file=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopPOSIT16/TCUopPOSIT16.c"
        ),
        golden_out=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopPOSIT16/golden_D_matrix.txt"
        ),
        make_target="TCUopPOSIT16.vsimc",
        compare_format="posit16",
        final_slm_file=Path(
            "pulpino-klessydra/sw/build/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopPOSIT16/slm_files/final_touched_words.slm"
        ),
        hw_matrix_file=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopPOSIT16/hw_D_matrix_extracted.txt"
        ),
        validation_report=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopPOSIT16/validation_report.txt"
        ),
        validation_csv=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopPOSIT16/validation_element_errors.csv"
        ),
    ),
    "lns16": FormatConfig(
        name="lns16",
        generator_script=Path(
            "FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/"
            "LNS16operands/generate_lns16_experiment.py"
        ),
        experiment_file=Path(
            "FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/"
            "LNS16operands/hmma_8instr_dualTC_4octects_lns16_single_experiment.txt"
        ),
        patcher_script_names=(
            Path("tools/klessydra/patch_klessydra_lns16_c_from_experiment.py"),
            Path(
                "pulpino-klessydra/sw/apps/klessydra_tests/"
                "klessydra_tcu_tests/tools/patch_klessydra_lns16_c_from_experiment.py"
            ),
        ),
        c_file=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopLNS16/TCUopLNS16.c"
        ),
        golden_out=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopLNS16/golden_D_matrix.txt"
        ),
        make_target="TCUopLNS16.vsimc",
        compare_format="lns16",
        final_slm_file=Path(
            "pulpino-klessydra/sw/build/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopLNS16/slm_files/final_touched_words.slm"
        ),
        hw_matrix_file=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopLNS16/hw_D_matrix_extracted.txt"
        ),
        validation_report=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopLNS16/validation_report.txt"
        ),
        validation_csv=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopLNS16/validation_element_errors.csv"
        ),
    ),
    "fp8": FormatConfig(
        name="fp8",
        generator_script=Path(
            "FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/"
            "fp8e4m3eoperands/generate_fp8_experiment.py"
        ),
        experiment_file=Path(
            "FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/"
            "fp8e4m3eoperands/hmma_8instr_dualTC_4octects_fp8_single_experiment.txt"
        ),
        patcher_script_names=(
            Path("tools/klessydra/patch_klessydra_fp8_c_from_experiment.py"),
            Path(
                "pulpino-klessydra/sw/apps/klessydra_tests/"
                "klessydra_tcu_tests/tools/patch_klessydra_fp8_c_from_experiment.py"
            ),
        ),
        c_file=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopFP8/TCUopFP8.c"
        ),
        golden_out=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopFP8/golden_D_matrix.txt"
        ),
        make_target="TCUopFP8.vsimc",
        compare_format="fp8",
        final_slm_file=Path(
            "pulpino-klessydra/sw/build/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopFP8/slm_files/final_touched_words.slm"
        ),
        hw_matrix_file=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopFP8/hw_D_matrix_extracted.txt"
        ),
        validation_report=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopFP8/validation_report.txt"
        ),
        validation_csv=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopFP8/validation_element_errors.csv"
        ),
    ),
    "posit8": FormatConfig(
        name="posit8",
        generator_script=Path(
            "FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/"
            "softPosit8_0operands/generate_posit8_experiment.py"
        ),
        experiment_file=Path(
            "FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/"
            "softPosit8_0operands/hmma_8instr_dualTC_4octects_posit8_single_experiment.txt"
        ),
        patcher_script_names=(
            Path("tools/klessydra/patch_klessydra_posit8_c_from_experiment.py"),
            Path(
                "pulpino-klessydra/sw/apps/klessydra_tests/"
                "klessydra_tcu_tests/tools/patch_klessydra_posit8_c_from_experiment.py"
            ),
        ),
        c_file=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopPOSIT8/TCUopPOSIT8.c"
        ),
        golden_out=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopPOSIT8/golden_D_matrix.txt"
        ),
        make_target="TCUopPOSIT8.vsimc",
        compare_format="posit8",
        final_slm_file=Path(
            "pulpino-klessydra/sw/build/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopPOSIT8/slm_files/final_touched_words.slm"
        ),
        hw_matrix_file=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopPOSIT8/hw_D_matrix_extracted.txt"
        ),
        validation_report=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopPOSIT8/validation_report.txt"
        ),
        validation_csv=Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/TCUopPOSIT8/validation_element_errors.csv"
        ),
    ),
}


MAKE_CWD_CANDIDATES = (
    Path("pulpino-klessydra/sw/build"),
    Path("pulpino-klessydra/build"),
    Path("pulpino-klessydra"),
)


def auto_detect_make_cwd(repo_root: Path) -> Path:
    """
    Prefer the existing Klessydra tests build directory.

    In the user's VM layout, when the runner is executed from:
      pulpino-klessydra/sw/apps/klessydra_tests/klessydra_tcu_tests/tools

    the actual make directory is:
      ../../build

    Relative to repo root, that is:
      pulpino-klessydra/sw/apps/klessydra_tests/build
    """
    for candidate in MAKE_CWD_CANDIDATES:
        full = as_abs(repo_root, candidate)
        if (full / "Makefile").exists():
            return candidate

    # Fallback: return the preferred path so the final error message is useful.
    return MAKE_CWD_CANDIDATES[0]



def print_banner(title: str) -> None:
    print()
    print("=" * 80)
    print(title)
    print("=" * 80)


def find_repo_root(start: Path) -> Path:
    current = start.resolve()
    while True:
        if all((current / marker).exists() for marker in REPO_MARKERS):
            return current
        if current.parent == current:
            raise RuntimeError(
                "Could not infer repository root. Run from inside ParametricTensorCoreUnit "
                "or pass --repo-root explicitly."
            )
        current = current.parent


def as_abs(repo_root: Path, path: Path) -> Path:
    if path.is_absolute():
        return path
    return repo_root / path


def resolve_existing(repo_root: Path, candidates: Tuple[Path, ...], description: str) -> Path:
    tried: List[Path] = []
    for candidate in candidates:
        full = as_abs(repo_root, candidate)
        tried.append(full)
        if full.exists():
            return full
    tried_text = "\n".join("  - {}".format(p) for p in tried)
    raise FileNotFoundError("Could not find {}. Tried:\n{}".format(description, tried_text))


def run_command(command: List[str], cwd: Path, description: str, dry_run: bool = False) -> None:
    print_banner(description)
    print("Working directory: {}".format(cwd))
    print("Command:")
    print("  " + " ".join(command))

    if dry_run:
        print("Dry run enabled: command not executed.")
        return

    result = subprocess.run(command, cwd=str(cwd))
    if result.returncode != 0:
        raise RuntimeError(
            "Command failed with return code {}: {}".format(result.returncode, " ".join(command))
        )


def run_generator(repo_root: Path, cfg: FormatConfig, dry_run: bool) -> None:
    generator = as_abs(repo_root, cfg.generator_script)
    if not generator.exists():
        raise FileNotFoundError("Experiment generator not found: {}".format(generator))

    run_command(
        [sys.executable, str(generator)],
        cwd=repo_root,
        description="Step 1 - Generate {} experiment".format(cfg.name.upper()),
        dry_run=dry_run,
    )

    experiment = as_abs(repo_root, cfg.experiment_file)
    if not dry_run and not experiment.exists():
        raise FileNotFoundError("Expected experiment file was not generated: {}".format(experiment))


def run_patcher(repo_root: Path, cfg: FormatConfig, backup: bool, dry_run: bool) -> None:
    patcher = resolve_existing(repo_root, cfg.patcher_script_names, "Klessydra FP16 patcher")

    command = [
        sys.executable,
        str(patcher),
        "--experiment-file",
        str(as_abs(repo_root, cfg.experiment_file)),
        "--c-file",
        str(as_abs(repo_root, cfg.c_file)),
        "--golden-out",
        str(as_abs(repo_root, cfg.golden_out)),
    ]

    if backup:
        command.append("--backup")

    run_command(
        command,
        cwd=repo_root,
        description="Step 2 - Patch Klessydra C benchmark for {}".format(cfg.name.upper()),
        dry_run=dry_run,
    )


def run_simulation(repo_root: Path, cfg: FormatConfig, make_cwd: Path, dry_run: bool) -> None:
    full_make_cwd = as_abs(repo_root, make_cwd)

    if not full_make_cwd.exists():
        raise FileNotFoundError("Make working directory does not exist: {}".format(full_make_cwd))

    run_command(
        ["make", cfg.make_target],
        cwd=full_make_cwd,
        description="Step 3 - Run Klessydra simulation target {}".format(cfg.make_target),
        dry_run=dry_run,
    )


def find_comparator(repo_root: Path) -> Path:
    candidates = (
        Path("tools/compare_d_matrix.py"),
        Path("tools/klessydra/compare_d_matrix.py"),
        Path(
            "FlexGripPlus/Open-GPGPU-FlexGrip-/applications/MAC_using_TCU/"
            "tools/compare_flexgrip_d_matrix.py"
        ),
    )
    return resolve_existing(repo_root, candidates, "matrix comparator")


def try_run_extractor(repo_root: Path, cfg: FormatConfig, dry_run: bool) -> bool:
    extractor_candidates = (
        Path("tools/klessydra/extract_klessydra_d_matrix.py"),
        Path(
            "pulpino-klessydra/sw/apps/klessydra_tests/"
            "klessydra_tcu_tests/tools/extract_klessydra_d_matrix.py"
        ),
    )

    extractor = resolve_existing(repo_root, extractor_candidates, "Klessydra D extractor")
    input_slm = as_abs(repo_root, cfg.final_slm_file)
    output_matrix = as_abs(repo_root, cfg.hw_matrix_file)

    if not dry_run and not input_slm.exists():
        raise FileNotFoundError("Expected final touched words SLM file not found: {}".format(input_slm))

    command = [
        sys.executable,
        str(extractor),
        "--format",
        cfg.name,
        "--input",
        str(input_slm),
        "--output",
        str(output_matrix),
    ]

    run_command(
        command,
        cwd=repo_root,
        description="Step 4 - Extract Klessydra D matrix from final_touched_words.slm",
        dry_run=dry_run,
    )

    return True

def run_validation(
    repo_root: Path,
    cfg: FormatConfig,
    hw_file: Optional[Path],
    dry_run: bool,
) -> bool:
    if hw_file is None:
        hw_matrix = as_abs(repo_root, cfg.hw_matrix_file)
    else:
        hw_matrix = as_abs(repo_root, hw_file)

    if not hw_matrix.exists():
        print_banner("Step 5 - Validate D matrix")
        print("Validation skipped because no hardware D matrix file exists yet.")
        print("Expected/default hardware matrix: {}".format(hw_matrix))
        print()
        print("This is expected for runner v0.7 unless you provide:")
        print("  --hw-file path/to/hw_D_matrix_extracted.txt")
        print("or implement:")
        print("  tools/klessydra/extract_klessydra_d_matrix.py")
        return False

    comparator = find_comparator(repo_root)

    run_command(
        [
            sys.executable,
            str(comparator),
            "--format",
            cfg.compare_format,
            "--golden-file",
            str(as_abs(repo_root, cfg.experiment_file)),
            "--hw-file",
            str(hw_matrix),
            "--output-report",
            str(as_abs(repo_root, cfg.validation_report)),
            "--output-csv",
            str(as_abs(repo_root, cfg.validation_csv)),
            "--golden-label",
            "#FULL_D_16x16_one_shot_reference encoded",
        ],
        cwd=repo_root,
        description="Step 5 - Validate D matrix",
        dry_run=dry_run,
    )

    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Klessydra TCU experiment automation.")
    parser.add_argument("--format", required=True, choices=sorted(FORMAT_CONFIGS.keys()))
    parser.add_argument("--repo-root", type=Path, default=None)
    parser.add_argument(
        "--make-cwd",
        type=Path,
        default=None,
        help=(
            "Directory from which make <target> should be executed. "
            "Default: auto-detect Klessydra tests build directory."
        ),
    )

    parser.add_argument("--skip-generate", action="store_true")
    parser.add_argument("--skip-patch", action="store_true")
    parser.add_argument("--skip-sim", action="store_true")
    parser.add_argument("--skip-extract", action="store_true")
    parser.add_argument("--skip-validate", action="store_true")

    parser.add_argument(
        "--backup",
        action="store_true",
        help="Ask the patcher to create a .bak copy of the C file before patching.",
    )
    parser.add_argument(
        "--hw-file",
        type=Path,
        default=None,
        help="Optional already-extracted hardware D matrix file. Enables validation without extractor.",
    )
    parser.add_argument("--dry-run", action="store_true")

    args = parser.parse_args()

    repo_root = args.repo_root.resolve() if args.repo_root else find_repo_root(Path.cwd())
    cfg = FORMAT_CONFIGS[args.format]
    make_cwd = args.make_cwd if args.make_cwd is not None else auto_detect_make_cwd(repo_root)

    print_banner("Klessydra TCU experiment runner v0.7")
    print("Repository root: {}".format(repo_root))
    print("Format:          {}".format(cfg.name))
    print("C benchmark:     {}".format(as_abs(repo_root, cfg.c_file)))
    print("Make target:     {}".format(cfg.make_target))
    print("Make directory:  {}".format(as_abs(repo_root, make_cwd)))

    if not args.skip_generate:
        run_generator(repo_root, cfg, dry_run=args.dry_run)
    else:
        print_banner("Step 1 - Generate experiment")
        print("Skipped by user.")

    if not args.skip_patch:
        run_patcher(repo_root, cfg, backup=args.backup, dry_run=args.dry_run)
    else:
        print_banner("Step 2 - Patch C benchmark")
        print("Skipped by user.")

    if not args.skip_sim:
        run_simulation(repo_root, cfg, make_cwd=make_cwd, dry_run=args.dry_run)
    else:
        print_banner("Step 3 - Run simulation")
        print("Skipped by user.")

    extracted = False
    if not args.skip_extract:
        extracted = try_run_extractor(repo_root, cfg, dry_run=args.dry_run)
    else:
        print_banner("Step 4 - Extract D matrix")
        print("Skipped by user.")

    validated = False
    if not args.skip_validate:
        validated = run_validation(repo_root, cfg, hw_file=args.hw_file, dry_run=args.dry_run)
    else:
        print_banner("Step 5 - Validate D matrix")
        print("Skipped by user.")

    print_banner("Klessydra runner v0.7 completed")
    print("Experiment file: {}".format(as_abs(repo_root, cfg.experiment_file)))
    print("Golden D file:   {}".format(as_abs(repo_root, cfg.golden_out)))
    print("Extraction done: {}".format(extracted))
    print("Validation done: {}".format(validated))

    if not validated:
        print()
        print("Note:")
        print("  The high-level flow is ready through generation, C patching, and simulation.")
        print("  Full validation requires the non-invasive Klessydra D extraction backend.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
