# Open Questions

---

## Q1: Should `Activity_Type` for Time_Information files be `'MUA'` or `'Spike'`?

**Date raised:** 2026-05-22  
**Status:** Resolved for now (set to `'MUA'`) — but worth revisiting

---

### Background

The pipeline produces per-trial time vectors stored under:
```
processed_data/Data_Neural/{Experiment}/{Session}/Time_Information/{Activity_Type}/{Activity_Type}_Trial_N_Time.mat
```

Example for session `Fr_Probe_02_22-05-02_004_01`:
```
Time_Information/MUA/MUA_Trial_6_Time.mat
Time_Information/MUA/MUA_Trial_7_Time.mat
...
```

Each file contains a time axis like `[-1.5, -1.499, ..., +1.5]` seconds relative to the alignment event (e.g., decision moment). These are NOT neural signals — they are just the time grid that will be used later when extracting neural activity per trial.

---

### The Conflict

`Activity_Type` is set in `PARAMETERS_cgg_procFullTrialPreparation_v2.m`:
```matlab
Activity_Type = 'MUA';
```

This parameter flows into:
- **Step 2** (`pgp_procProcessingBehaviorOnly`) → calls `cgg_getTimeSegments_v2` with `Activity_Type = 'MUA'` → looks for `Time_Information/MUA/MUA_Trial_N_Time.mat`
- **All figure scripts** (`FIGURE_cgg_DecisionAlignedPlots*.m`, `FIGURE_cggChannelTrialMeansandSTD*.m`, etc.) → look for processed neural signal files `MUA_Trial_N.mat`

But **Step 1** (`pgp_proc_EventFrameTrialPreparation.m`) was hardcoded to write `'Spike'`:
```matlab
Activity_Type = 'Spike';  % match the old naming convention
```
→ wrote to `Time_Information/Spike/Spike_Trial_N_Time.mat`

This caused Step 2 to crash: `Unable to find file ... Time_Information/MUA/MUA_Trial_6_Time.mat`.

---

### What `Activity_Type` Actually Controls

1. **Folder/file naming for time vectors** (`Time_Information/{type}/`) — the immediate issue
2. **SamplingFrequency** used when processing raw neural signals:
   ```matlab
   case 'MUA'
       SamplingFrequency = cfg_PreProcessing.rect_samprate;  % e.g., 1000 Hz (rectified/smoothed)
   case 'LFP'
       SamplingFrequency = cfg_PreProcessing.lfp_samprate;   % e.g., 1000 Hz (low-pass)
   case 'Spike'
       % no explicit case — falls through to 'otherwise' → rect_samprate
   ```
3. **Folder/file naming for processed neural signal files**: `{Area}/{type}/MUA_Trial_N.mat` — these are the actual extracted waveforms used by figure scripts. `continuous.dat` was NOT uploaded to ACCRE so these files are never produced in this pipeline run.

---

### What Was Changed

In `pgp_proc_EventFrameTrialPreparation.m`:
- Skip check changed from `Time_Information/Spike/` → `Time_Information/MUA/`
- Writing changed from `Activity_Type = 'Spike'` → `Activity_Type = 'MUA'`

---

### The Deeper Question

Is `'Spike'` actually the semantically correct label here?

- The time vectors in `Time_Information/` are **not** MUA signals. They're just time grids used to define trial windows. They're the same regardless of whether you later apply them to MUA, LFP, or spike counts.
- The original `'Spike'` naming in Step 1 may have been intentional: "these time windows are for spike alignment, not for MUA processing."
- BUT: `'MUA'` is what the entire rest of the codebase expects. Changing the parameter to `'Spike'` would break all figure scripts which hardcode `Activity_Type = 'MUA'`.

**Possible future fix:** Make Step 1 write time files under both `MUA/` and `Spike/` subdirectories (or make the subfolder name configurable), so the same time grid is available to both the behavioral pipeline (which uses 'MUA') and any spike-specific pipeline.

---

### Files Involved

| File | Role |
|------|------|
| `Processing_Functions_cgg/Neural_Data_cgg/pgp_proc_EventFrameTrialPreparation.m` | Step 1 — writes time files; `Activity_Type` hardcoded here |
| `Processing_Functions_cgg/Parameters/PARAMETERS_cgg_procFullTrialPreparation_v2.m` | Sets `Activity_Type = 'MUA'` globally |
| `Processing_Functions_cgg/Neural_Data_cgg/pgp_procProcessingBehaviorOnly.m` | Step 2 — reads time files using `Activity_Type` from parameters |
| `Processing_Functions_cgg/Neural_Data_cgg/cgg_getTimeSegments_v2.m` | Loads the per-trial time `.mat` files |
| `Processing_Functions_cgg/Figures/FIGURE_cgg_DecisionAlignedPlots*.m` | Figure scripts — expect `MUA_Trial_N.mat` neural signal files |
