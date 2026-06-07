% kaa_exportSpikeCountsToCSV.m
%
% Exports SpikeCounts_Stable.mat to per-probe long-format CSV files:
%
%   {session_name}_prb{N}_DATA.csv  — DATA alignment window
%   {session_name}_prb{N}_BASE.csv  — BASELINE window
%
% Each CSV has one row per (trial × time-bin):
%   Unit_0001 ... Unit_K   Time_ms   Trial_Number
%
% Unit numbering restarts from 1 for each probe.
% Values under Unit columns: 0, 1, or NaN (NaN = unit outside stable window).
%
% Probe-to-brain-area mapping (set in the pipeline, not enforced here):
%   prb1, prb2  -> ACC
%   prb3, prb4  -> PFC
%   prb5, prb6  -> Caudate
%
% Set session_name and spike_counts_dir below, then run.

%% ---- Configure here ----
session_name     = 'Fr_Probe_03_22-07-13_002_01';
spike_counts_dir = '/data/womelsdorf_lab/kazezew/Old_Dataset_Related/processed_data';

%% ---- Load ----
pattern = fullfile(spike_counts_dir, '**', [session_name '*SpikeCounts_Stable.mat']);
flist   = dir(pattern);
assert(~isempty(flist), 'No SpikeCounts_Stable.mat found for session: %s', session_name);

fpath = fullfile(flist(1).folder, flist(1).name);
fprintf('Loading: %s\n', fpath);
S = load(fpath, 'X', 'X_base', 'Meta', 'TrialId');

X       = S.X;
X_base  = S.X_base;
TrialId = S.TrialId(:);   % [nTrials x 1]
nT      = numel(X);

fprintf('Loaded: %d trials\n', nT);

%% ---- Read probe info from Meta.UnitInfo ----
probe_idx_arr = double(S.Meta.UnitInfo.probe_idx(:));   % [nUnits x 1]
unique_probes = unique(probe_idx_arr);
fprintf('Found %d probe(s): %s\n', numel(unique_probes), mat2str(unique_probes(:)'));

%% ---- Time vectors ----
t_ms_data = double(S.Meta.t_ms);
t_ms_base = double(S.Meta.t_ms_base);

%% ---- Output directory (same folder as the .mat) ----
out_dir = flist(1).folder;

%% ---- Export one CSV per probe ----
for pidx = 1:numel(unique_probes)
    this_prb  = unique_probes(pidx);
    unit_mask = (probe_idx_arr == this_prb);   % logical [nUnits x 1]
    nU_this   = sum(unit_mask);

    fprintf('\n--- probe %d: %d unit(s) ---\n', this_prb, nU_this);

    % Unit column names restart at 1 for each probe
    unit_names = arrayfun(@(u) sprintf('Unit_%04d', u), 1:nU_this, 'UniformOutput', false);
    col_names  = [unit_names, {'Time_ms', 'Trial_Number'}];

    % Extract this probe's rows from each trial cell
    X_probe      = cellfun(@(m) m(unit_mask, :), X(:, 1),      'UniformOutput', false);
    X_base_probe = cellfun(@(m) m(unit_mask, :), X_base(:, 1), 'UniformOutput', false);

    % DATA window
    out_name = sprintf('%s_prb%d_DATA.csv', session_name, this_prb);
    out_path = fullfile(out_dir, out_name);
    T_data = flatten_to_table(X_probe, t_ms_data, TrialId, col_names, nU_this);
    fprintf('Writing DATA  prb%d: %s\n', this_prb, out_path);
    writetable(T_data, out_path);

    % BASELINE window
    out_name_b = sprintf('%s_prb%d_BASE.csv', session_name, this_prb);
    out_path_b = fullfile(out_dir, out_name_b);
    T_base = flatten_to_table(X_base_probe, t_ms_base, TrialId, col_names, nU_this);
    fprintf('Writing BASE  prb%d: %s\n', this_prb, out_path_b);
    writetable(T_base, out_path_b);
end

fprintf('\nDone.\n');

%% ---- Local function ----

function T = flatten_to_table(cells, t_ms_vec, trial_ids, col_names, nU)
    nT = numel(cells);
    nB = numel(t_ms_vec);

    Xmat  = double(cat(3, cells{:}));                          % [nU x nB x nT]
    % permute [2 3 1] -> [nB x nT x nU]; reshape col-major -> trial-major rows:
    % row order: (t=1,b=1),(t=1,b=2),...,(t=1,bN),(t=2,b=1),...
    Xflat = reshape(permute(Xmat, [2 3 1]), nT*nB, nU);       % [nT*nB x nU]

    time_col  = repmat(double(t_ms_vec(:)), nT, 1);            % [nT*nB x 1]
    % double() cast: TrialId from HDF5 is int64; int64 in [] silently converts
    % NaN->0, erasing stability masks. Explicit cast keeps NaN intact.
    trial_col = double(repelem(trial_ids(:), nB));             % [nT*nB x 1]

    T = array2table([Xflat, time_col, trial_col], 'VariableNames', col_names);
end
