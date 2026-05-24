#!/usr/bin/env python3
"""
reorganize_behavioral_data.py

Copies behavioral/recording data from /Volumes/NN_Ephys1 into ACCRE-ready structure:
  <DEST_ROOT>/DATA_neural/<Monkey>/<Experiment>/<Session>/

Skips:
  - continuous.dat  (raw voltage, huge, not needed)
  - sorted_data/    (already handled by reorganize_sorted_data.py)
  - hidden files/folders (starting with '.')
  - system folders ($RECYCLE.BIN, System Volume Information, scripts)

Original files are NOT modified.
"""

import shutil
from pathlib import Path

SOURCE_ROOT = Path("/Volumes/NN_Ephys1")
DEST_ROOT   = SOURCE_ROOT / "FLToken_BHV"

SKIP_EXPERIMENT_DIRS = {"FLToken_Sorted", "FLToken_BHV", "$RECYCLE.BIN",
                        "System Volume Information", "scripts"}

SKIP_SESSION_SUBDIRS = {"sorted_data"}
SKIP_FILENAMES       = {"continuous.dat"}


def copy_tree_filtered(src: Path, dst: Path) -> None:
    """Recursively copy src to dst, skipping continuous.dat files."""
    dst.mkdir(parents=True, exist_ok=True)

    for item in src.iterdir():
        if item.name.startswith("."):
            continue
        if item.name in SKIP_FILENAMES:
            print(f"      [skip file] {item.name}")
            continue

        dest_item = dst / item.name

        if item.is_dir():
            copy_tree_filtered(item, dest_item)
        else:
            shutil.copy2(item, dest_item)


def get_monkey_name(experiment_folder_name: str) -> str:
    """Derive monkey name from experiment folder: 'Frey_FLToken_Probe_02' -> 'Frey'"""
    return experiment_folder_name.split("_")[0]


def main():
    if not SOURCE_ROOT.exists():
        raise RuntimeError(f"Drive not found: {SOURCE_ROOT}")

    print(f"Destination root: {DEST_ROOT / 'DATA_neural'}\n")

    for experiment_dir in sorted(SOURCE_ROOT.iterdir()):
        if not experiment_dir.is_dir():
            continue
        if experiment_dir.name.startswith("."):
            continue
        if experiment_dir.name in SKIP_EXPERIMENT_DIRS:
            continue

        monkey_name = get_monkey_name(experiment_dir.name)
        experiment_name = experiment_dir.name

        for session_dir in sorted(experiment_dir.iterdir()):
            if not session_dir.is_dir() or session_dir.name.startswith("."):
                continue

            session_name = session_dir.name
            dest_session = (
                DEST_ROOT / "DATA_neural" / monkey_name / experiment_name / session_name
            )

            print(f"Session: {session_name}")
            print(f"  -> {dest_session}")

            for item in sorted(session_dir.iterdir()):
                if item.name.startswith("."):
                    continue
                if item.name in SKIP_SESSION_SUBDIRS:
                    print(f"  [skip dir] {item.name}/")
                    continue

                dest_item = dest_session / item.name

                if item.is_dir():
                    print(f"  copying dir: {item.name}/")
                    copy_tree_filtered(item, dest_item)
                else:
                    if item.name in SKIP_FILENAMES:
                        print(f"  [skip file] {item.name}")
                        continue
                    dest_session.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(item, dest_item)
                    print(f"  copying file: {item.name}")

    print("\nDone.")


if __name__ == "__main__":
    main()
