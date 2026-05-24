#!/usr/bin/env python3
"""
reorganize_sorted_data.py

Copies KS4 sorted data from /Volumes/NN_Ephys1 into a new flat structure:
  /Volumes/NN_Ephys1/FLToken_Sorted/sorted/continuous_{session}/{session}_prb{N}/KS4_OUTPUT/

Only copies:
  - spike_times.npy
  - spike_clusters.npy
  - autoSortMetrics/ folder (if present)

Original files are NOT modified.
"""

import shutil
from pathlib import Path

SOURCE_ROOT = Path("/Volumes/NN_Ephys1")
DEST_ROOT   = SOURCE_ROOT / "FLToken_Sorted" / "sorted"

SKIP_DIRS = {"FLToken_Sorted", "$RECYCLE.BIN", "System Volume Information", "scripts"}

COPY_FILES = {"spike_times.npy", "spike_clusters.npy"}
COPY_DIR   = "autoSortMetrics"


def copy_ks4_output(src_ks4: Path, dest_ks4: Path) -> None:
    dest_ks4.mkdir(parents=True, exist_ok=True)

    for fname in COPY_FILES:
        src_file = src_ks4 / fname
        if src_file.exists():
            shutil.copy2(src_file, dest_ks4 / fname)
            print(f"    copied {fname}")
        else:
            print(f"    [skip] {fname} not found")

    src_dir = src_ks4 / COPY_DIR
    if src_dir.exists():
        dest_dir = dest_ks4 / COPY_DIR
        if dest_dir.exists():
            shutil.rmtree(dest_dir)
        shutil.copytree(src_dir, dest_dir)
        print(f"    copied {COPY_DIR}/")
    else:
        print(f"    [skip] {COPY_DIR}/ not found")


def main():
    if not SOURCE_ROOT.exists():
        raise RuntimeError(f"Drive not found: {SOURCE_ROOT}")

    DEST_ROOT.mkdir(parents=True, exist_ok=True)
    print(f"Destination root: {DEST_ROOT}\n")

    for experiment_dir in sorted(SOURCE_ROOT.iterdir()):
        if not experiment_dir.is_dir() or experiment_dir.name in SKIP_DIRS or experiment_dir.name.startswith("."):
            continue

        for session_dir in sorted(experiment_dir.iterdir()):
            if not session_dir.is_dir():
                continue

            session_name = session_dir.name
            sorted_data  = session_dir / "sorted_data"

            if not sorted_data.is_dir():
                continue

            print(f"Session: {session_name}")

            for probe_dir in sorted(sorted_data.iterdir()):
                if not probe_dir.is_dir():
                    continue

                src_ks4 = probe_dir / "KS4_OUTPUT"
                if not src_ks4.is_dir():
                    continue

                probe_folder_name = probe_dir.name   # e.g. Fr_Probe_02_22-05-02_004_01_prb1
                dest_ks4 = (
                    DEST_ROOT
                    / f"continuous_{session_name}"
                    / probe_folder_name
                    / "KS4_OUTPUT"
                )

                print(f"  {probe_folder_name}")
                copy_ks4_output(src_ks4, dest_ks4)

    print("\nDone.")


if __name__ == "__main__":
    main()
