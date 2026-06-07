#!/usr/bin/env python3
"""
pgp_spikeTrialAlignment_v5_stability.py  (DATA + BASELINE)  -- SALIGN-ONLY VERSION

Batch-align Kilosort spikes to TWO alignment events (Data + Baseline),
bin into 1ms (or user-defined) counts, concatenate all probes, and save
ONE MATLAB v7.3 .mat file per session containing:

  TrialId   : [nTrials x 1] int64
  X         : {nTrials x 1} cell array; X{t}      = [nUnits x nBins_data] float32
  X_base    : {nTrials x 1} cell array; X_base{t} = [nUnits x nBins_base] float32
  Meta      : struct with t_ms, t_ms_base, params, and UnitInfo

Trials are defined as the intersection of DATA and BASE Salign trial IDs.

Required per session under processed_session_root:
  Event_Information/recTime_offset_<session>.mat              (c)
  Frame_Information/<align_mat>.mat                           (Salign struct array)
  Frame_Information/<baseline_align_mat>.mat                  (Salign struct array)

Required per probe under sorted_root:
  <session>_prbX/KS4_OUTPUT/spike_times.npy
  <session>_prbX/KS4_OUTPUT/spike_clusters.npy
  <session>_prbX/KS4_OUTPUT/autoSortMetrics/clusterMetrics/cluster_metrics_with_labels.csv
    OR (fallback)
  <session>_prbX/KS4_OUTPUT/autoSortMetrics/clusterStability/cluster_stability.xlsx

If cluster_metrics_with_labels.csv is missing, good cluster IDs are read from
cluster_stability.xlsx (quality column) instead of skipping the probe.
If both are missing, that probe is skipped.

If cluster_stability.xlsx is missing, the session fails by default unless
--allow_missing_stability is used. With that flag, all kept units are treated
as stable for the full recording (no NaN masking applied).

The stability masking NaNs out any neuron-trial row where the trial window
falls outside that neuron's stable period (as defined by start_s/end_s in
cluster_stability.xlsx). NaN masking uses the full trial window extent:
a trial is masked if [align_samp/Fs - win_before_s, align_samp/Fs + win_after_s]
is not fully contained in [start_s, end_s].

JSON per session should include:
  session, processed_session_root, sorted_root, align_mat, baseline_align_mat
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

import numpy as np
import pandas as pd
from scipy.io import loadmat


# ----------------------------- helpers -----------------------------

def load_offset_c(offset_mat: Path) -> float:
    d = loadmat(offset_mat.as_posix(), struct_as_record=False, squeeze_me=True)
    if "c" not in d:
        raise KeyError(f"'c' not found in {offset_mat}. Keys: {list(d.keys())}")
    return float(d["c"])


def read_good_clusters(metrics_csv: Path, qualities=(4, 5)) -> np.ndarray:
    """
    Returns unique good cluster IDs (int64) from a CSV file.
    Raises if CSV exists but is malformed.
    """
    try:
        df = pd.read_csv(metrics_csv)
    except Exception:
        raw = metrics_csv.read_text().splitlines()
        raw2 = [re.sub(r'^"(.*)"$', r"\1", line) for line in raw]
        tmp = metrics_csv.with_name(metrics_csv.stem + "_CLEAN_tmp.csv")
        tmp.write_text("\n".join(raw2))
        df = pd.read_csv(tmp)
        try:
            tmp.unlink()
        except Exception:
            pass

    if "quality" not in df.columns or "cluster_id" not in df.columns:
        raise KeyError(f"metrics CSV missing required columns. Have: {list(df.columns)}")

    good = df.loc[df["quality"].isin(list(qualities)), "cluster_id"].to_numpy()
    return np.unique(good.astype(np.int64))


def find_cluster_stability_xlsx(ks_dir: Path) -> Optional[Path]:
    """
    Expected location:
      KS4_OUTPUT/autoSortMetrics/clusterStability/cluster_stability.xlsx

    Falls back to the first *.xlsx in that folder.
    """
    stab_dir = ks_dir / "autoSortMetrics" / "clusterStability"
    preferred = stab_dir / "cluster_stability.xlsx"
    if preferred.exists():
        return preferred

    if stab_dir.exists():
        hits = sorted(stab_dir.glob("*.xlsx"))
        if hits:
            return hits[0]

    return None


def read_cluster_stability(stability_xlsx: Path, qualities=(4, 5)) -> pd.DataFrame:
    """
    Returns one row per good cluster_id with columns:
      cluster_id, quality, start_s, end_s, has_gaps, uncertain, auto_has_gaps

    If multiple stability rows exist for the same cluster, uses the
    intersection of all reported stable intervals:
      start_s = max(start_s)
      end_s   = min(end_s)

    Row order does not define unit row order in X; that comes from
    good_cids_used in build_counts_for_probe.
    """
    df = pd.read_excel(stability_xlsx)

    required = {"cluster_id", "quality", "start_s", "end_s"}
    missing = required - set(df.columns)
    if missing:
        raise KeyError(
            f"{stability_xlsx} missing required columns: {sorted(missing)}. "
            f"Have: {list(df.columns)}"
        )

    df = df.loc[df["quality"].isin(list(qualities)), :].copy()
    if df.empty:
        return pd.DataFrame(
            columns=["cluster_id", "quality", "start_s", "end_s", "has_gaps", "uncertain", "auto_has_gaps"]
        )

    df["cluster_id"] = df["cluster_id"].astype(np.int64)
    df["quality"] = df["quality"].astype(np.int32)
    df["start_s"] = pd.to_numeric(df["start_s"], errors="coerce")
    df["end_s"] = pd.to_numeric(df["end_s"], errors="coerce")

    for col in ["has_gaps", "uncertain", "auto_has_gaps"]:
        if col not in df.columns:
            df[col] = 0
        df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0).astype(np.int32)

    grouped = (
        df.groupby("cluster_id", as_index=False)
          .agg(
              quality=("quality", "max"),
              start_s=("start_s", "max"),
              end_s=("end_s", "min"),
              has_gaps=("has_gaps", "max"),
              uncertain=("uncertain", "max"),
              auto_has_gaps=("auto_has_gaps", "max"),
          )
          .sort_values("cluster_id")
          .reset_index(drop=True)
    )

    bad_interval = grouped["start_s"].isna() | grouped["end_s"].isna() | (grouped["end_s"] <= grouped["start_s"])
    if bad_interval.any():
        bad_ids = grouped.loc[bad_interval, "cluster_id"].astype(int).tolist()
        raise ValueError(f"{stability_xlsx} has invalid stability intervals for clusters: {bad_ids[:20]}")

    return grouped


def stability_df_to_dict(stability_df: pd.DataFrame) -> Dict[int, Tuple[float, float]]:
    """Convert stability DataFrame to cluster_id -> (start_s, end_s)."""
    out: Dict[int, Tuple[float, float]] = {}
    for row in stability_df.itertuples(index=False):
        out[int(row.cluster_id)] = (float(row.start_s), float(row.end_s))
    return out


def apply_stability_nan_mask(
    counts_cell: np.ndarray,
    trial_ids: np.ndarray,
    align_samp_by_trial: Dict[int, int],
    Fs: float,
    win_before_s: float,
    win_after_s: float,
    good_cids_used: np.ndarray,
    stability_by_cid: Dict[int, Tuple[float, float]],
    label: str,
) -> Tuple[int, int, int, np.ndarray, np.ndarray, np.ndarray]:
    """
    Sets counts_cell[trial, 0][unit_row, :] = NaN when the trial window
    falls outside the unit's stable interval.

    A trial is masked if [align_samp/Fs - win_before_s, align_samp/Fs + win_after_s]
    is not fully contained in [start_s, end_s].

    Returns:
      n_nan_rows            : number of neuron-trial rows set to NaN
      total_kept            : number of neuron-trial rows kept
      total_possible        : total neuron-trial rows tested
      unit_has_stability    : [nUnits] bool, whether each unit had a stability row
      unit_stability_start  : [nUnits] float, start_s for each unit
      unit_stability_end    : [nUnits] float, end_s for each unit
    """
    n_trials = len(trial_ids)
    n_units = len(good_cids_used)
    total_possible = n_trials * n_units

    unit_has_stability = np.zeros(n_units, dtype=bool)
    unit_stability_start = np.full(n_units, np.nan, dtype=np.float64)
    unit_stability_end = np.full(n_units, np.nan, dtype=np.float64)

    trial_start_s = np.asarray(
        [(float(align_samp_by_trial[int(t)]) / Fs) - win_before_s for t in trial_ids],
        dtype=np.float64,
    )
    trial_end_s = np.asarray(
        [(float(align_samp_by_trial[int(t)]) / Fs) + win_after_s for t in trial_ids],
        dtype=np.float64,
    )

    print(
        f"{label}: trial window range = "
        f"{np.nanmin(trial_start_s):.2f} to {np.nanmax(trial_end_s):.2f} sec",
        flush=True,
    )

    n_nan_rows = 0
    total_kept = 0

    for u, cid in enumerate(good_cids_used.tolist()):
        cid = int(cid)

        if cid not in stability_by_cid:
            bad_trials = np.ones(n_trials, dtype=bool)
            start_s = np.nan
            end_s = np.nan
            has_stability = False
        else:
            start_s, end_s = stability_by_cid[cid]
            bad_trials = (trial_start_s < start_s) | (trial_end_s > end_s)
            has_stability = True

        unit_has_stability[u] = has_stability
        unit_stability_start[u] = start_s
        unit_stability_end[u] = end_s

        n_bad = int(np.sum(bad_trials))
        n_kept = int(n_trials - n_bad)

        n_nan_rows += n_bad
        total_kept += n_kept

        print(
            f"{label}: cluster {cid} stable {start_s:.2f}-{end_s:.2f} sec, "
            f"kept {n_kept}/{n_trials} trials",
            flush=True,
        )

        for ti in np.flatnonzero(bad_trials):
            counts_cell[ti, 0][u, :] = np.nan

    return (
        n_nan_rows,
        total_kept,
        total_possible,
        unit_has_stability,
        unit_stability_start,
        unit_stability_end,
    )


def load_valid_trial_ids(
    processed_session_root: Path,
    session: str,
    trial_duration_max: float = 10.0,
) -> Optional[Set[int]]:
    """
    Load TrialVariables_{session}.mat and return valid (non-aborted, not too long) trial IDs.

    Mirrors the MUA pipeline criterion from cgg_getSeparateTrialsByCriteria_v2 /
    cgg_getTrialCriteriaBaseline:
        AbortCode == 0  AND  TrialTime < trial_duration_max

    The TrialVariables file is a MATLAB v7.3 HDF5 file where each field is stored
    as an array of object references that must be dereferenced individually.

    Returns None if the file is absent or unreadable (caller warns and uses all trials).
    """
    tv_path = processed_session_root / "Trial_Information" / f"TrialVariables_{session}.mat"
    if not tv_path.exists():
        print(
            f"[warn] TrialVariables not found at {tv_path}; "
            "skipping aborted-trial filter.",
            flush=True,
        )
        return None

    try:
        import h5py

        with h5py.File(tv_path.as_posix(), "r") as f:
            if "trialVariables" not in f:
                print(
                    f"[warn] 'trialVariables' key missing in {tv_path}; "
                    "skipping aborted-trial filter.",
                    flush=True,
                )
                return None

            tv = f["trialVariables"]

            def _deref(col: str) -> np.ndarray:
                """Dereference a column of HDF5 object references → 1-D float array."""
                return np.array([f[r][()].flat[0] for r in tv[col][:].flatten()])

            abort_vals = _deref("AbortCode").astype(float)
            ttime_vals = _deref("TrialTime").astype(float)
            tnum_vals  = _deref("TrialNumber").astype(int)

    except Exception as exc:
        print(
            f"[warn] Failed to read TrialVariables from {tv_path} ({exc}); "
            "skipping aborted-trial filter.",
            flush=True,
        )
        return None

    valid_mask = (abort_vals == 0) & (ttime_vals < trial_duration_max)
    valid_ids: Set[int] = {int(t) for t in tnum_vals[valid_mask]}

    n_total   = len(abort_vals)
    n_valid   = len(valid_ids)
    n_removed = n_total - n_valid
    print(
        f"[info] TrialVariables: {n_total} total, {n_valid} valid "
        f"(AbortCode==0 & TrialTime<{trial_duration_max}s), {n_removed} excluded",
        flush=True,
    )
    return valid_ids


def load_ks_spikes(ks_dir: Path) -> Tuple[np.ndarray, np.ndarray]:
    st = np.load(ks_dir / "spike_times.npy").astype(np.int64).reshape(-1)
    sc = np.load(ks_dir / "spike_clusters.npy").astype(np.int64).reshape(-1)
    if st.shape[0] != sc.shape[0]:
        raise ValueError("spike_times and spike_clusters length mismatch")
    if np.any(np.diff(st) < 0):
        order = np.argsort(st, kind="mergesort")
        st, sc = st[order], sc[order]
    return st, sc


def find_probe_ks_dirs(sorted_root: Path, session: str) -> List[Path]:
    patt = re.compile(re.escape(session) + r"_prb\d+$")
    out: List[Path] = []
    for p in sorted_root.iterdir():
        if p.is_dir() and patt.match(p.name):
            ks = p / "KS4_OUTPUT"
            if ks.is_dir():
                out.append(ks)
    out.sort(key=lambda x: x.parent.name)
    if not out:
        raise FileNotFoundError(f"No KS4_OUTPUT dirs under {sorted_root} for session {session}")
    return out


def load_align_struct(align_mat: Path, Fs: float, c: float) -> Tuple[Dict[int, int], str]:
    """
    align_mat contains Salign: struct array with fields:
      - trialCounter (or TrialCounter / TrialIndex / TrialNumber)
      - recTime (sec)

    Returns: dict trial_id -> alignSamp (int sample index), and the field name used for trial id.
    """
    d = loadmat(align_mat.as_posix(), struct_as_record=False, squeeze_me=True)
    if "Salign" not in d:
        raise KeyError(f"Salign not found in {align_mat}. Keys: {list(d.keys())}")
    Salign = d["Salign"]

    if hasattr(Salign, "_fieldnames"):
        Slist = [Salign]
    else:
        Slist = list(np.ravel(Salign))

    if not Slist:
        raise ValueError(f"Salign is empty in {align_mat}")

    fns = Slist[0]._fieldnames
    trial_field = None
    for cand in ["trialCounter", "TrialCounter", "TrialIndex", "trialIndex", "TrialNumber", "trialNumber"]:
        if cand in fns:
            trial_field = cand
            break
    if trial_field is None:
        raise KeyError(f"Could not find trial id field in Salign. Fields: {fns}")

    if "recTime" not in fns:
        raise KeyError(f"recTime not found in Salign. Fields: {fns}")

    out: Dict[int, int] = {}
    for s in Slist:
        tid = int(getattr(s, trial_field))
        rt = float(getattr(s, "recTime"))
        samp = int(np.round((rt - c) * Fs))
        out[tid] = samp

    return out, trial_field


def build_counts_for_probe(
    st: np.ndarray,
    sc: np.ndarray,
    good_cids: np.ndarray,
    trial_ids: np.ndarray,
    align_samp_by_trial: Dict[int, int],
    Fs: float,
    win_before_s: float,
    win_after_s: float,
    bin_ms: float,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    Returns:
      counts_cell: (nTrials, 1) object cell, each [nGoodUnits x nBins] float32
      t_ms:        [1 x nBins] int32 row vector
      good_cids_used: [nGoodUnits] int64 in stable order (rows of X)
    """
    keep = np.isin(sc, good_cids)
    st = st[keep]
    sc = sc[keep]
    if np.any(np.diff(st) < 0):
        order = np.argsort(st, kind="mergesort")
        st, sc = st[order], sc[order]

    good_cids_used = np.unique(good_cids.astype(np.int64))
    cid_to_row = {int(cid): i for i, cid in enumerate(good_cids_used.tolist())}
    rows = np.fromiter((cid_to_row[int(c)] for c in sc), dtype=np.int32, count=sc.shape[0])
    nU = len(good_cids_used)

    bin_samp = int(round(Fs * (bin_ms / 1000.0)))
    if bin_samp <= 0:
        raise ValueError("bin_samp computed <= 0; check Fs/bin_ms")

    nBins = int(round((win_before_s + win_after_s) * 1000 / bin_ms))
    t_ms = np.arange(
        -int(round(win_before_s * 1000)),
        int(round(win_after_s * 1000)),
        int(round(bin_ms)),
    ).astype(np.int32)
    if len(t_ms) != nBins:
        raise RuntimeError("t_ms length mismatch; check rounding/bin_ms")

    pre_samp = int(round(win_before_s * Fs))
    post_samp = int(round(win_after_s * Fs))

    counts_cell = np.empty((len(trial_ids), 1), dtype=object)

    for i, tn in enumerate(trial_ids.tolist()):
        tn = int(tn)
        if tn not in align_samp_by_trial:
            raise KeyError(f"Trial {tn} missing from Salign mapping.")

        sel = int(align_samp_by_trial[tn])
        w0 = sel - pre_samp
        w1 = sel + post_samp  # [w0, w1)

        i0 = int(np.searchsorted(st, w0, "left"))
        i1 = int(np.searchsorted(st, w1, "left"))
        st_w = st[i0:i1]
        r_w = rows[i0:i1]

        X = np.zeros((nU, nBins), dtype=np.float32)
        if st_w.size > 0:
            b = ((st_w - w0) // bin_samp).astype(np.int64)
            ok = (b >= 0) & (b < nBins)
            if np.any(ok):
                np.add.at(X, (r_w[ok], b[ok]), 1)

        counts_cell[i, 0] = X

    return counts_cell, t_ms.reshape(1, -1), good_cids_used


def _assert_align_map_complete(trial_ids: np.ndarray, align_map: Dict[int, int], label: str) -> None:
    missing = [int(t) for t in trial_ids if int(t) not in align_map]
    if missing:
        raise RuntimeError(f"{len(missing)} trials missing from {label} Salign (examples: {missing[:10]})")


# ----------------------------- session runner -----------------------------

def process_one_session(
    session: str,
    processed_session_root: Path,
    sorted_root: Path,
    align_mat_path: Path,
    baseline_align_mat_path: Path,
    out_subdir: str,
    Fs: float,
    bin_ms: float,
    win_before: float,
    win_after: float,
    win_before_base: float,
    win_after_base: float,
    qualities: Tuple[int, ...],
    allow_missing_stability: bool,
    trial_duration_max: float = 10.0,
) -> Path:
    offset_mat = processed_session_root / "Event_Information" / f"recTime_offset_{session}.mat"
    align_mat = align_mat_path
    base_align_mat = baseline_align_mat_path

    if not offset_mat.exists():
        raise FileNotFoundError(offset_mat)
    if not align_mat.exists():
        raise FileNotFoundError(align_mat)
    if not base_align_mat.exists():
        raise FileNotFoundError(base_align_mat)

    print(f"\n=== session {session} ===", flush=True)
    print(f"[info] processed_root: {processed_session_root}", flush=True)
    print(f"[info] sorted_root:    {sorted_root}", flush=True)
    print(f"[info] align_mat:      {align_mat}", flush=True)
    print(f"[info] base_align_mat: {base_align_mat}", flush=True)

    c = load_offset_c(offset_mat)
    print(f"[info] loaded offset c = {c:.9f} sec", flush=True)

    align_samp_by_trial, trial_field = load_align_struct(align_mat, Fs=Fs, c=c)
    base_samp_by_trial, base_trial_field = load_align_struct(base_align_mat, Fs=Fs, c=c)
    print(f"[info] loaded DATA Salign: {len(align_samp_by_trial)} trials (trial field: {trial_field})", flush=True)
    print(f"[info] loaded BASE Salign: {len(base_samp_by_trial)} trials (trial field: {base_trial_field})", flush=True)

    # SALIGN-ONLY trials: DATA ∩ BASE
    data_ok = set(int(k) for k in align_samp_by_trial.keys())
    base_ok = set(int(k) for k in base_samp_by_trial.keys())
    keep = sorted(data_ok & base_ok)
    trial_ids = np.asarray(keep, dtype=np.int64)

    print("\n--- overlap counts (SALIGN-ONLY) ---", flush=True)
    print(f"  DATA trials: {len(data_ok)}", flush=True)
    print(f"  BASE trials: {len(base_ok)}", flush=True)
    print(f"  DATA ∩ BASE: {trial_ids.size}", flush=True)

    if trial_ids.size == 0:
        raise RuntimeError("[FAIL] No trials remain after intersecting DATA and BASE Salign.")

    # Filter aborted / too-long trials using TrialVariables (mirrors MUA pipeline).
    valid_ids = load_valid_trial_ids(processed_session_root, session, trial_duration_max)
    if valid_ids is not None:
        before = trial_ids.size
        trial_ids = trial_ids[np.isin(trial_ids, np.array(sorted(valid_ids), dtype=np.int64))]
        print(
            f"[info] After aborted-trial filter: {before} -> {trial_ids.size} trials "
            f"(removed {before - trial_ids.size})",
            flush=True,
        )
        if trial_ids.size == 0:
            raise RuntimeError(
                "[FAIL] No trials remain after aborted-trial filtering. "
                "Check TrialVariables or --trial_duration_max."
            )

    _assert_align_map_complete(trial_ids, align_samp_by_trial, "DATA")
    _assert_align_map_complete(trial_ids, base_samp_by_trial, "BASE")

    ks_dirs = find_probe_ks_dirs(sorted_root, session)
    print(f"[info] found {len(ks_dirs)} probe KS dirs", flush=True)

    X_session: Optional[np.ndarray] = None
    X_base_session: Optional[np.ndarray] = None
    t_ms_ref: Optional[np.ndarray] = None
    t_ms_base_ref: Optional[np.ndarray] = None

    unit_probe_name: List[str] = []
    unit_probe_idx: List[int] = []
    unit_cluster_id: List[int] = []
    unit_has_stability: List[bool] = []
    unit_stability_start_s: List[float] = []
    unit_stability_end_s: List[float] = []

    n_probes_used = 0

    for p_idx, ks_dir in enumerate(ks_dirs, start=1):
        probe_name = ks_dir.parent.name
        print(f"[probe] {probe_name}", flush=True)

        metrics_csv = ks_dir / "autoSortMetrics" / "clusterMetrics" / "cluster_metrics_with_labels.csv"
        stability_xlsx = find_cluster_stability_xlsx(ks_dir)

        # Get good cluster IDs: prefer CSV, fall back to xlsx quality column.
        _stability_df_preread: Optional[pd.DataFrame] = None
        if metrics_csv.exists():
            good_cids = read_good_clusters(metrics_csv, qualities=qualities)
            print(f"  good clusters: {len(good_cids)} (from CSV)", flush=True)
        else:
            if stability_xlsx is None:
                print(
                    f"  [warn] missing cluster_metrics_with_labels.csv and cluster_stability.xlsx "
                    f"-> skipping probe: {metrics_csv}",
                    flush=True,
                )
                continue
            print(
                f"  [info] cluster_metrics_with_labels.csv not found, "
                f"falling back to cluster_stability.xlsx for cluster IDs",
                flush=True,
            )
            # Read stability now and reuse below to avoid reading the xlsx twice.
            _stability_df_preread = read_cluster_stability(stability_xlsx, qualities=qualities)
            good_cids = np.unique(_stability_df_preread["cluster_id"].to_numpy().astype(np.int64))
            print(f"  good clusters: {len(good_cids)} (from xlsx fallback)", flush=True)

        if good_cids.size == 0:
            print("  [warn] no good clusters -> skipping probe", flush=True)
            continue

        # Get stability windows for NaN masking.
        if stability_xlsx is None:
            msg = f"  [warn] missing cluster stability file for {probe_name}"
            if allow_missing_stability:
                print(msg + " -> treating all kept units as stable for the full recording", flush=True)
                stability_df = pd.DataFrame({
                    "cluster_id": good_cids.astype(np.int64),
                    "quality": np.zeros(good_cids.size, dtype=np.int32),
                    "start_s": np.zeros(good_cids.size, dtype=np.float64),
                    "end_s": np.full(good_cids.size, np.inf, dtype=np.float64),
                    "has_gaps": np.zeros(good_cids.size, dtype=np.int32),
                    "uncertain": np.zeros(good_cids.size, dtype=np.int32),
                    "auto_has_gaps": np.zeros(good_cids.size, dtype=np.int32),
                })
            else:
                raise FileNotFoundError(
                    f"{msg}. Expected {ks_dir / 'autoSortMetrics' / 'clusterStability' / 'cluster_stability.xlsx'}"
                )
        elif _stability_df_preread is not None:
            # Already read when falling back for cluster IDs — reuse it.
            stability_df = _stability_df_preread
            print(f"  stability rows: {len(stability_df)} ({stability_xlsx})", flush=True)
        else:
            stability_df = read_cluster_stability(stability_xlsx, qualities=qualities)
            print(f"  stability rows: {len(stability_df)} ({stability_xlsx})", flush=True)

        stability_by_cid = stability_df_to_dict(stability_df)
        missing_stability = sorted(set(int(c) for c in good_cids.tolist()) - set(stability_by_cid.keys()))
        if missing_stability:
            print(
                f"  [warn] {len(missing_stability)} good clusters have no stability row; "
                f"they will be NaN for all trials. Examples: {missing_stability[:10]}",
                flush=True,
            )

        st, sc = load_ks_spikes(ks_dir)

        # DATA counts
        counts_cell, t_ms, good_cids_used = build_counts_for_probe(
            st=st,
            sc=sc,
            good_cids=good_cids,
            trial_ids=trial_ids,
            align_samp_by_trial=align_samp_by_trial,
            Fs=Fs,
            win_before_s=win_before,
            win_after_s=win_after,
            bin_ms=bin_ms,
        )

        # BASELINE counts
        counts_cell_base, t_ms_base, good_cids_used_base = build_counts_for_probe(
            st=st,
            sc=sc,
            good_cids=good_cids,
            trial_ids=trial_ids,
            align_samp_by_trial=base_samp_by_trial,
            Fs=Fs,
            win_before_s=win_before_base,
            win_after_s=win_after_base,
            bin_ms=bin_ms,
        )

        if not np.array_equal(good_cids_used, good_cids_used_base):
            raise RuntimeError(
                f"[{session} | {probe_name}] unit ordering mismatch between DATA and BASE. "
                "This should not happen; check good_cids handling."
            )

        # Apply stability NaN masking.
        (
            n_nan_rows_data,
            total_kept_data,
            total_possible_data,
            unit_has_stability_data,
            unit_stability_start_data,
            unit_stability_end_data,
        ) = apply_stability_nan_mask(
            counts_cell,
            trial_ids=trial_ids,
            align_samp_by_trial=align_samp_by_trial,
            Fs=Fs,
            win_before_s=win_before,
            win_after_s=win_after,
            good_cids_used=good_cids_used,
            stability_by_cid=stability_by_cid,
            label=f"{session} | {probe_name} | DATA",
        )

        (
            n_nan_rows_base,
            total_kept_base,
            total_possible_base,
            unit_has_stability_base,
            unit_stability_start_base,
            unit_stability_end_base,
        ) = apply_stability_nan_mask(
            counts_cell_base,
            trial_ids=trial_ids,
            align_samp_by_trial=base_samp_by_trial,
            Fs=Fs,
            win_before_s=win_before_base,
            win_after_s=win_after_base,
            good_cids_used=good_cids_used_base,
            stability_by_cid=stability_by_cid,
            label=f"{session} | {probe_name} | BASE",
        )

        if not np.array_equal(unit_has_stability_data, unit_has_stability_base):
            raise RuntimeError(f"[{session} | {probe_name}] DATA/BASE stability has-entry mismatch.")
        if not np.allclose(unit_stability_start_data, unit_stability_start_base, equal_nan=True):
            raise RuntimeError(f"[{session} | {probe_name}] DATA/BASE stability start_s mismatch.")
        if not np.allclose(unit_stability_end_data, unit_stability_end_base, equal_nan=True):
            raise RuntimeError(f"[{session} | {probe_name}] DATA/BASE stability end_s mismatch.")

        print(
            f"  stability masking: "
            f"DATA kept {total_kept_data}/{total_possible_data} neuron-trial rows "
            f"(NaN={n_nan_rows_data}); "
            f"BASE kept {total_kept_base}/{total_possible_base} neuron-trial rows "
            f"(NaN={n_nan_rows_base})",
            flush=True,
        )

        if X_session is None:
            X_session = counts_cell
            X_base_session = counts_cell_base
            t_ms_ref = t_ms
            t_ms_base_ref = t_ms_base
        else:
            assert X_base_session is not None and t_ms_ref is not None and t_ms_base_ref is not None
            if not np.array_equal(t_ms_ref, t_ms):
                raise RuntimeError("Time axis mismatch across probes (DATA).")
            if not np.array_equal(t_ms_base_ref, t_ms_base):
                raise RuntimeError("Time axis mismatch across probes (BASELINE).")

            for i in range(X_session.shape[0]):
                X_session[i, 0] = np.vstack([X_session[i, 0], counts_cell[i, 0]])
                X_base_session[i, 0] = np.vstack([X_base_session[i, 0], counts_cell_base[i, 0]])

        for row, cid in enumerate(good_cids_used.tolist()):
            unit_probe_name.append(probe_name)
            unit_probe_idx.append(p_idx)
            unit_cluster_id.append(int(cid))
            unit_has_stability.append(bool(unit_has_stability_data[row]))
            unit_stability_start_s.append(float(unit_stability_start_data[row]))
            unit_stability_end_s.append(float(unit_stability_end_data[row]))

        n_probes_used += 1

    if X_session is None or X_base_session is None:
        raise RuntimeError(f"[FAIL] session {session}: no probes processed (all missing metrics or no good clusters).")

    assert t_ms_ref is not None and t_ms_base_ref is not None

    nTrials = int(len(trial_ids))
    nBins_data = int(t_ms_ref.shape[1])
    nBins_base = int(t_ms_base_ref.shape[1])
    nUnits_total = int(X_session[0, 0].shape[0])

    unit_id_global = np.arange(1, nUnits_total + 1, dtype=np.int64)
    Meta = {
        "session": session,
        "Fs": float(Fs),
        "bin_ms": float(bin_ms),

        "win_before_s": float(win_before),
        "win_after_s": float(win_after),
        "t_ms": t_ms_ref.astype(np.int32),

        "win_before_base_s": float(win_before_base),
        "win_after_base_s": float(win_after_base),
        "t_ms_base": t_ms_base_ref.astype(np.int32),

        "AlignInfo": {
            "align_mat": str(align_mat),
            "trial_field": str(trial_field),
            "offset_c": float(c),
        },
        "AlignInfoBaseline": {
            "align_mat": str(base_align_mat),
            "trial_field": str(base_trial_field),
            "offset_c": float(c),
        },

        "UnitInfo": {
            "unit_id": unit_id_global.reshape(-1, 1),
            "probe_name": np.array(unit_probe_name, dtype=object).reshape(-1, 1),
            "probe_idx": np.array(unit_probe_idx, dtype=np.int32).reshape(-1, 1),
            "cluster_id": np.array(unit_cluster_id, dtype=np.int32).reshape(-1, 1),
            "has_stability": np.array(unit_has_stability, dtype=bool).reshape(-1, 1),
            "stability_start_s": np.array(unit_stability_start_s, dtype=np.float64).reshape(-1, 1),
            "stability_end_s": np.array(unit_stability_end_s, dtype=np.float64).reshape(-1, 1),
        },

        "ProbesUsed": int(n_probes_used),
    }

    outdir = processed_session_root / out_subdir
    outdir.mkdir(parents=True, exist_ok=True)
    out_path = outdir / f"{session}__{align_mat.stem}__SpikeCounts_Stable.mat"

    TrialId = trial_ids.reshape(-1, 1).astype(np.int64)

    bytes_per_trial = X_session[0, 0].nbytes + X_base_session[0, 0].nbytes
    est_total = bytes_per_trial * nTrials
    print(f"[info] approx uncompressed payload (X+X_base only) ~ {est_total/1e9:.2f} GB", flush=True)

    mdict = {"TrialId": TrialId, "X": X_session, "X_base": X_base_session, "Meta": Meta}

    import hdf5storage
    hdf5storage.savemat(
        out_path.as_posix(),
        mdict,
        format="7.3",
        store_python_metadata=False,
        matlab_compatible=True,
    )

    print(f"[saved] {out_path}", flush=True)
    print(
        f"[info] trials={nTrials} units_total={nUnits_total} "
        f"bins_data={nBins_data} bins_base={nBins_base}",
        flush=True,
    )

    return out_path


# ----------------------------- cfg json -----------------------------

def load_cfg_json(cfg_json_path: str):
    cfg_json_path = Path(cfg_json_path)
    with cfg_json_path.open("r") as f:
        payload = json.load(f)

    if isinstance(payload, list):
        sessions = payload
    elif isinstance(payload, dict) and "sessions" in payload and isinstance(payload["sessions"], list):
        sessions = payload["sessions"]
    else:
        raise ValueError(
            "cfg_json must be either a JSON list of session objects OR a JSON dict with key 'sessions' containing a list."
        )

    return sessions


# ----------------------------- main -----------------------------

def main():
    ap = argparse.ArgumentParser(
        description="Batch spike trial alignment with stability masking (DATA + BASELINE, SALIGN-only).",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog="""
Example runs:

1) Recommended stability-masked output, no overwrite:
   python pgp_spikeTrialAlignment_v5_stability.py \\
     --cfg_json /path/to/session_config.json \\
     --out_subdir SpikeAligned_stabilityMasked

2) Reprocess even if the *_SpikeCounts_Stable.mat output already exists:
   python pgp_spikeTrialAlignment_v5_stability.py \\
     --cfg_json /path/to/session_config.json \\
     --out_subdir SpikeAligned_stabilityMasked \\
     --no_skip_existing

3) Use custom alignment mat names:
   python pgp_spikeTrialAlignment_v5_stability.py \\
     --cfg_json /path/to/session_config.json \\
     --align_mat_name AlignEvent_SelectObject_END_SESSION.mat \\
     --baseline_align_mat_name AlignEvent_Blink_START_SESSION.mat \\
     --out_subdir SpikeAligned_stabilityMasked

4) Allow missing cluster_stability.xlsx files:
   python pgp_spikeTrialAlignment_v5_stability.py \\
     --cfg_json /path/to/session_config.json \\
     --out_subdir SpikeAligned_stabilityMasked \\
     --allow_missing_stability
""",
    )

    ap.add_argument("--cfg_json", required=True,
                    help="JSON payload with either a list of sessions OR a dict with key 'sessions'")

    ap.add_argument("--align_mat_name", default="",
                    help="Optional override: use <processed_session_root>/Frame_Information/<align_mat_name> instead of JSON align_mat")

    ap.add_argument("--baseline_align_mat_name", default="",
                    help="Optional override: use <processed_session_root>/Frame_Information/<baseline_align_mat_name> instead of JSON baseline_align_mat")

    ap.add_argument("--out_subdir", default="SpikeAligned",
                    help="Subfolder under processed_session_root to save outputs")

    ap.add_argument("--Fs", type=float, default=30000.0,
                    help="Sampling rate in Hz")
    ap.add_argument("--bin_ms", type=float, default=1.0,
                    help="Spike count bin width in ms")

    ap.add_argument("--win_before", type=float, default=1.5,
                    help="Seconds before DATA alignment event")
    ap.add_argument("--win_after", type=float, default=1.5,
                    help="Seconds after DATA alignment event")

    ap.add_argument("--win_before_base", type=float, default=0.15,
                    help="Seconds before BASELINE alignment event")
    ap.add_argument("--win_after_base", type=float, default=0.4,
                    help="Seconds after BASELINE alignment event")

    ap.add_argument("--qualities", default="4,5",
                    help="Comma-separated cluster quality labels to keep (e.g. 4,5)")

    ap.add_argument("--allow_missing_stability", action="store_true",
                    help="If set, missing cluster_stability.xlsx files are allowed and all kept units are treated as stable.")

    ap.add_argument("--trial_duration_max", type=float, default=10.0,
                    help="Maximum trial duration in seconds (default 10.0). Trials with "
                         "TrialTime >= this value are excluded, matching the MUA pipeline "
                         "cgg_getTrialCriteriaBaseline criterion. Requires TrialVariables_<session>.mat "
                         "to exist under processed_session_root/Trial_Information/.")

    ap.add_argument("--no_skip_existing", action="store_true",
                    help="Process even if output .mat already exists")

    args = ap.parse_args()

    cfg_json = Path(args.cfg_json)
    sessions = load_cfg_json(cfg_json)

    Fs = float(args.Fs)
    bin_ms = float(args.bin_ms)
    win_before = float(args.win_before)
    win_after = float(args.win_after)
    win_before_base = float(args.win_before_base)
    win_after_base = float(args.win_after_base)
    qualities = tuple(int(x) for x in args.qualities.split(",") if x.strip())

    print(f"[info] loaded {len(sessions)} sessions from {cfg_json}", flush=True)
    print(f"[info] DATA win:     [-{win_before:.3f}, +{win_after:.3f}] s", flush=True)
    print(f"[info] BASELINE win: [-{win_before_base:.3f}, +{win_after_base:.3f}] s", flush=True)
    print(f"[info] qualities: {qualities}", flush=True)

    skip_existing = not args.no_skip_existing

    for s in sessions:
        session = str(s["session"])
        processed_session_root = Path(s["processed_session_root"])
        sorted_root = Path(s["sorted_root"])

        if args.align_mat_name:
            align_mat = processed_session_root / "Frame_Information" / args.align_mat_name
        else:
            align_mat = Path(s.get("align_mat", "")) if "align_mat" in s else None

        if align_mat is None or str(align_mat) == "" or (not align_mat.exists()):
            raise FileNotFoundError(
                f"[{session}] align_mat not found. "
                f"JSON align_mat='{s.get('align_mat','')}', override='{args.align_mat_name}'."
            )

        if args.baseline_align_mat_name:
            baseline_align_mat = processed_session_root / "Frame_Information" / args.baseline_align_mat_name
        else:
            baseline_align_mat = Path(s.get("baseline_align_mat", "")) if "baseline_align_mat" in s else None

        if baseline_align_mat is None or str(baseline_align_mat) == "" or (not baseline_align_mat.exists()):
            raise FileNotFoundError(
                f"[{session}] baseline_align_mat not found. "
                f"JSON baseline_align_mat='{s.get('baseline_align_mat','')}', override='{args.baseline_align_mat_name}'."
            )

        expected_out = (
            processed_session_root / str(args.out_subdir) /
            f"{session}__{align_mat.stem}__SpikeCounts_Stable.mat"
        )
        if skip_existing and expected_out.exists():
            print(f"[skip] {session} already processed -> {expected_out}", flush=True)
            continue

        process_one_session(
            session=session,
            processed_session_root=processed_session_root,
            sorted_root=sorted_root,
            align_mat_path=align_mat,
            baseline_align_mat_path=baseline_align_mat,
            out_subdir=str(args.out_subdir),
            Fs=Fs,
            bin_ms=bin_ms,
            win_before=win_before,
            win_after=win_after,
            win_before_base=win_before_base,
            win_after_base=win_after_base,
            qualities=qualities,
            allow_missing_stability=bool(args.allow_missing_stability),
            trial_duration_max=float(args.trial_duration_max),
        )

    print("\n[done] all sessions processed.", flush=True)


if __name__ == "__main__":
    main()
