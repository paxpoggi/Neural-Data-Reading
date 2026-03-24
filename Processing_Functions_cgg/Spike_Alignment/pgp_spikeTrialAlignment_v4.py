#!/usr/bin/env python3
"""
pgp_spikeTrialAlignment_v3.py  (DATA + BASELINE)  -- SALIGN-ONLY VERSION

Batch-align Kilosort spikes to TWO alignment events (Data + Baseline),
bin into 1ms (or user-defined) counts, concatenate all probes, and save
ONE .mat file per session containing:

  TrialId   : [nTrials x 1] int64
  X         : {nTrials x 1} cell array; X{t}      = [nUnits x nBins_data] int16
  X_base    : {nTrials x 1} cell array; X_base{t} = [nUnits x nBins_base] int16
  Meta      : struct with t_ms, t_ms_base, params, and UnitInfo

SALIGN-ONLY: We DO NOT use rectrialdefs / Trial_Definition files.
Trials are defined as the intersection of DATA and BASE Salign trial IDs.

Required per session under processed_session_root:
  Event_Information/recTime_offset_<session>.mat              (c)
  Frame_Information/<align_mat>.mat                           (Salign struct array)
  Frame_Information/<baseline_align_mat>.mat                  (Salign struct array)

Required per probe under sorted_root:
  <session>_prbX/KS4_OUTPUT/spike_times.npy
  <session>_prbX/KS4_OUTPUT/spike_clusters.npy
  <session>_prbX/KS4_OUTPUT/autoSortMetrics/clusterMetrics/cluster_metrics_with_labels.csv

If a probe is missing cluster_metrics_with_labels.csv, that probe is skipped.

JSON per session should include:
  session, processed_session_root, sorted_root, align_mat, baseline_align_mat
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional

import numpy as np
import pandas as pd
from scipy.io import loadmat, savemat
from scipy.io.matlab import MatWriteError


# ----------------------------- helpers -----------------------------

def load_offset_c(offset_mat: Path) -> float:
    d = loadmat(offset_mat.as_posix(), struct_as_record=False, squeeze_me=True)
    if "c" not in d:
        raise KeyError(f"'c' not found in {offset_mat}. Keys: {list(d.keys())}")
    return float(d["c"])


def read_good_clusters(metrics_csv: Path, qualities=(4, 5)) -> np.ndarray:
    """
    Returns unique good cluster IDs (int64). Raises if CSV exists but is malformed.
    """
    # handle annoying quoting issues robustly
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

    # normalize to list of mat_struct
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
      counts_cell: (nTrials, 1) object cell, each [nGoodUnits x nBins] int16
      t_ms:        [1 x nBins] int32 row vector
      good_cids_used: [nGoodUnits] int64 in stable order (rows of X)
    """
    # filter to good clusters
    keep = np.isin(sc, good_cids)
    st = st[keep]
    sc = sc[keep]
    if np.any(np.diff(st) < 0):
        order = np.argsort(st, kind="mergesort")
        st, sc = st[order], sc[order]

    # stable row ordering of units
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
        int(round(bin_ms))
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
        w1 = sel + post_samp  # [w0,w1)

        i0 = int(np.searchsorted(st, w0, "left"))
        i1 = int(np.searchsorted(st, w1, "left"))
        st_w = st[i0:i1]
        r_w = rows[i0:i1]

        X = np.zeros((nU, nBins), dtype=np.int16)
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
) -> Path:
    # paths
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

    _assert_align_map_complete(trial_ids, align_samp_by_trial, "DATA")
    _assert_align_map_complete(trial_ids, base_samp_by_trial, "BASE")

    # process probes
    ks_dirs = find_probe_ks_dirs(sorted_root, session)
    print(f"[info] found {len(ks_dirs)} probe KS dirs", flush=True)

    X_session: Optional[np.ndarray] = None       # (nTrials,1) cell of [nUnits_total x nBins_data]
    X_base_session: Optional[np.ndarray] = None  # (nTrials,1) cell of [nUnits_total x nBins_base]
    t_ms_ref: Optional[np.ndarray] = None
    t_ms_base_ref: Optional[np.ndarray] = None

    unit_probe_name: List[str] = []
    unit_probe_idx: List[int] = []
    unit_cluster_id: List[int] = []

    n_probes_used = 0

    for p_idx, ks_dir in enumerate(ks_dirs, start=1):
        probe_name = ks_dir.parent.name
        print(f"[probe] {probe_name}", flush=True)

        metrics_csv = ks_dir / "autoSortMetrics" / "clusterMetrics" / "cluster_metrics_with_labels.csv"
        if not metrics_csv.exists():
            print(f"  [warn] missing cluster metrics -> skipping probe: {metrics_csv}", flush=True)
            continue

        good_cids = read_good_clusters(metrics_csv, qualities=qualities)
        print(f"  good clusters: {len(good_cids)}", flush=True)

        if good_cids.size == 0:
            print("  [warn] no good clusters -> skipping probe", flush=True)
            continue

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

        # Ensure identical per-probe unit ordering between data and baseline
        if not np.array_equal(good_cids_used, good_cids_used_base):
            raise RuntimeError(
                f"[{session} | {probe_name}] unit ordering mismatch between DATA and BASE. "
                "This should not happen; check good_cids handling."
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

        # record unit mapping
        for cid in good_cids_used.tolist():
            unit_probe_name.append(probe_name)
            unit_probe_idx.append(p_idx)
            unit_cluster_id.append(int(cid))

        n_probes_used += 1

    if X_session is None or X_base_session is None:
        raise RuntimeError(f"[FAIL] session {session}: no probes processed (all missing metrics or no good clusters).")

    assert t_ms_ref is not None and t_ms_base_ref is not None

    nTrials = int(len(trial_ids))
    nBins_data = int(t_ms_ref.shape[1])
    nBins_base = int(t_ms_base_ref.shape[1])
    nUnits_total = int(X_session[0, 0].shape[0])

    # Meta struct
    unit_id_global = np.arange(1, nUnits_total + 1, dtype=np.int64)  # 1-indexed for MATLAB friendliness
    Meta = {
        "session": session,
        "Fs": float(Fs),
        "bin_ms": float(bin_ms),

        "win_before_s": float(win_before),
        "win_after_s": float(win_after),
        "t_ms": t_ms_ref.astype(np.int32),  # [1 x nBins_data]

        "win_before_base_s": float(win_before_base),
        "win_after_base_s": float(win_after_base),
        "t_ms_base": t_ms_base_ref.astype(np.int32),  # [1 x nBins_base]

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
        },

        "ProbesUsed": int(n_probes_used),
    }

    # save .mat per session
    outdir = processed_session_root / out_subdir
    outdir.mkdir(parents=True, exist_ok=True)
    out_path = outdir / f"{session}__{align_mat.stem}__SpikeCounts.mat"

    TrialId = trial_ids.reshape(-1, 1).astype(np.int64)

    bytes_per_trial = X_session[0, 0].nbytes + X_base_session[0, 0].nbytes
    est_total = bytes_per_trial * nTrials
    print(f"[info] approx payload (X+X_base only) ~ {est_total/1e9:.2f} GB", flush=True)

    mdict = {"TrialId": TrialId, "X": X_session, "X_base": X_base_session, "Meta": Meta}

    # MATLAB v5 gets sketchy well below your 5.68 GB case; just go v7.3 if big.
    V5_MAX_GB = 1.8  # conservative safety margin
    use_v73 = (est_total / 1e9) > V5_MAX_GB

    if use_v73:
        import hdf5storage
        hdf5storage.savemat(
            out_path.as_posix(),
            mdict,
            format="7.3",
            store_python_metadata=False,
            matlab_compatible=True,
        )
    else:
        try:
            savemat(out_path.as_posix(), mdict, do_compression=True)
        except MatWriteError:
            import hdf5storage
            hdf5storage.savemat(
                out_path.as_posix(),
                mdict,
                format="7.3",
                store_python_metadata=False,
                matlab_compatible=True,
            )

    print(f"[saved] {out_path}", flush=True)
    print(f"[info] trials={nTrials} units_total={nUnits_total} bins_data={nBins_data} bins_base={nBins_base}", flush=True)

    return out_path


# ----------------------------- cfg json -----------------------------

def load_cfg_json(cfg_json_path: str):
    cfg_json_path = Path(cfg_json_path)
    with cfg_json_path.open("r") as f:
        payload = json.load(f)

    # Accept either:
    #   (A) raw list: [ {session...}, ... ]
    #   (B) wrapped dict: { "sessions": [ ... ], ... }
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
    ap = argparse.ArgumentParser(description="Batch spike trial alignment (DATA + BASELINE) -> one .mat per session (SALIGN-only).")

    ap.add_argument("--cfg_json", required=True,
                    help="JSON payload with either a list of sessions OR a dict with key 'sessions'")

    ap.add_argument("--align_mat_name", default="",
                    help="Optional override: use <processed_session_root>/Frame_Information/<align_mat_name> instead of JSON align_mat")

    ap.add_argument("--baseline_align_mat_name", default="",
                    help="Optional override: use <processed_session_root>/Frame_Information/<baseline_align_mat_name> instead of JSON baseline_align_mat")

    ap.add_argument("--out_subdir", default="SpikeAligned",
                    help="Subfolder under processed_session_root to save outputs")

    ap.add_argument("--Fs", type=float, default=30000.0)
    ap.add_argument("--bin_ms", type=float, default=1.0)

    # DATA window
    ap.add_argument("--win_before", type=float, default=1.5)
    ap.add_argument("--win_after", type=float, default=1.5)

    # BASELINE window
    ap.add_argument("--win_before_base", type=float, default=0.15)
    ap.add_argument("--win_after_base", type=float, default=0.4)

    ap.add_argument("--qualities", default="4,5",
                    help="Comma-separated cluster quality labels to keep (e.g. 4,5)")

    # skip by default (your prior behavior)
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

    skip_existing = (not args.no_skip_existing)

    for s in sessions:
        session = str(s["session"])
        processed_session_root = Path(s["processed_session_root"])
        sorted_root = Path(s["sorted_root"])

        # DATA align mat
        if args.align_mat_name:
            align_mat = processed_session_root / "Frame_Information" / args.align_mat_name
        else:
            align_mat = Path(s.get("align_mat", "")) if "align_mat" in s else None

        if align_mat is None or str(align_mat) == "" or (not align_mat.exists()):
            raise FileNotFoundError(
                f"[{session}] align_mat not found. "
                f"JSON align_mat='{s.get('align_mat','')}', override='{args.align_mat_name}'."
            )

        # BASELINE align mat
        if args.baseline_align_mat_name:
            baseline_align_mat = processed_session_root / "Frame_Information" / args.baseline_align_mat_name
        else:
            baseline_align_mat = Path(s.get("baseline_align_mat", "")) if "baseline_align_mat" in s else None

        if baseline_align_mat is None or str(baseline_align_mat) == "" or (not baseline_align_mat.exists()):
            raise FileNotFoundError(
                f"[{session}] baseline_align_mat not found. "
                f"JSON baseline_align_mat='{s.get('baseline_align_mat','')}', override='{args.baseline_align_mat_name}'."
            )

        expected_out = processed_session_root / str(args.out_subdir) / f"{session}__{align_mat.stem}__SpikeCounts.mat"
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
        )

    print("\n[done] all sessions processed.", flush=True)


if __name__ == "__main__":
    main()