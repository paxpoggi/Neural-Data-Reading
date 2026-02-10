function [badZIdx, Debugging_Info, refLabelsGood] = cgg_getDisconnectedChannelsZScore_v3(...
    Connected_Channels, outdatadir_Raw, clustering_file_name, Debugging_Info, varargin)
%CGG_GETDISCONNECTEDCHANNELSZSCORE_V3 Method iii: Z-score screening for disconnected channels
%
%   [badZIdx, Debugging_Info, refLabelsGood] = cgg_getDisconnectedChannelsZScore_v3(
%       Connected_Channels, outdatadir_Raw, clustering_file_name, Debugging_Info, ...)
%
%   This function performs Z-score based screening to identify disconnected channels
%   by analyzing robust statistics across multiple trials.
%
%   Parameters:
%       Connected_Channels    - Current connected channels (from Methods i & ii)
%       outdatadir_Raw   - Path to raw trial files directory
%       clustering_file_name  - Path to Clustering_Results.mat file
%       Debugging_Info        - Existing Debugging_Info structure (will be updated)
%       Optional parameters:
%           'zscore_threshold'   - Z-score threshold (default: 7)
%           'fraction_threshold' - Fraction threshold (default: 0.01)
%           'nSampleTrials'      - Number of trials to sample (default: 10)
%
%   Returns:
%       badZIdx          - Channel indices detected as bad by Z-score
%       Debugging_Info   - Updated with Method_iii_ZScore structure
%       refLabelsGood    - Good reference channel labels for rereferencing

fprintf('.. Method iii: Starting Z-score screening for disconnected channels...\n');

% Parse optional parameters
zscore_threshold = CheckVararginPairs('zscore_threshold', 7, varargin{:});
fraction_threshold = CheckVararginPairs('fraction_threshold', 0.01, varargin{:});
nSampleTrials = CheckVararginPairs('nSampleTrials', 10, varargin{:});

% --- Build list of saved raw trial files (produced by the first parfor)
rawDir = outdatadir_Raw;
rawFiles = dir(fullfile(rawDir, 'Raw_Trial_*.mat'));
assert(~isempty(rawFiles), 'No Raw_Trial_*.mat files found in %s', rawDir);

nTot = numel(rawFiles);
nSampleTrials = min(nSampleTrials, nTot);
fprintf('.. Method iii: Sampling %d trial(s) from %d available trial(s)\n', nSampleTrials, nTot);

% --- Pick trials deterministically or randomly
rng(0);   % optional reproducibility
pick = randperm(nTot, nSampleTrials);

% --- Load the first picked trial to get labels & Connected_Channels mapping
S0 = load(fullfile(rawDir, rawFiles(pick(1)).name), 'this_recdata_raw');
labels = S0.this_recdata_raw.label;

% IMPORTANT: translate Connected_Channels (indices) -> labels AFTER remap
refLabels0 = labels(Connected_Channels);
refIdx = match_str(labels, refLabels0);

fprintf('.. Method iii: Testing %d reference channel(s) for stability\n', numel(refIdx));

% --- Concatenate candidate reference data across the chosen trials
Xcat = [];   % [nChannels x total_time_across_trials]
for ii = 1:numel(pick)
    Si = load(fullfile(rawDir, rawFiles(pick(ii)).name), 'this_recdata_raw');
    Xi = Si.this_recdata_raw.trial{1}(refIdx,:);   % each file has 1 trial
    % Optional: Xi = Xi(:,1:2:end);  % light decimation to save RAM
    Xcat = [Xcat, Xi]; %#ok<AGROW>
end

fprintf('.. Method iii: Computing robust statistics across %d time points\n', size(Xcat, 2));

% --- Robust per-channel stats across all sampled data
medc = median(Xcat, 2);
madc = mad(Xcat, 1, 2);
rZ   = (Xcat - medc) ./ max(madc, eps);

fracHi = mean(abs(rZ) > zscore_threshold, 2);      % fraction exceeding threshold
keep   = isfinite(medc) & isfinite(madc) & fracHi < fraction_threshold;

% --- Final, stable ref list (labels)
refLabelsGood = labels(refIdx(keep));

fprintf('.. Method iii: %d channel(s) passed Z-score screening (threshold: %.1f, fraction: %.3f)\n', ...
    numel(refLabelsGood), zscore_threshold, fraction_threshold);

% (Optional but wise) require a minimum ref size
if numel(refLabelsGood) < max(3, ceil(0.2*numel(refLabels0)))
    warning('Few stable ref channels survived (%d/%d). Consider local CAR or looser thresholds.', ...
            numel(refLabelsGood), numel(refLabels0));
end

% 1) Find which of the originally Connected didn't survive z-screening
origConnLabels = labels(Connected_Channels);
badZLabels     = setdiff(origConnLabels, refLabelsGood, 'stable');  % Connected \ Good

% 2) Map those labels back to indices in the current label order
badZIdx = match_str(labels, badZLabels);   % row indices into data/trial matrices

% Store Method iii (Z-score) results in Debugging_Info
Debugging_Info.Method_iii_ZScore.Channels = badZIdx;
if ~isempty(badZIdx)
    % Get z-score stats for bad channels
    % badZLabels are the labels of bad channels, need to find their positions in refIdx
    % refIdx contains indices into labels for Connected_Channels
    % Find which positions in refIdx correspond to badZLabels
    badZ_refIdx_positions = [];
    for zidx = 1:numel(badZLabels)
        % Find where this bad label appears in refIdx
        refIdx_pos = find(strcmp(labels(refIdx), badZLabels{zidx}));
        if ~isempty(refIdx_pos)
            badZ_refIdx_positions = [badZ_refIdx_positions, refIdx_pos];
        end
    end
    
    if ~isempty(badZ_refIdx_positions)
        Debugging_Info.Method_iii_ZScore.ZScores = fracHi(badZ_refIdx_positions);
        Debugging_Info.Method_iii_ZScore.MedianValues = medc(badZ_refIdx_positions);
        Debugging_Info.Method_iii_ZScore.MADValues = madc(badZ_refIdx_positions);
    else
        Debugging_Info.Method_iii_ZScore.ZScores = [];
        Debugging_Info.Method_iii_ZScore.MedianValues = [];
        Debugging_Info.Method_iii_ZScore.MADValues = [];
    end
    
    fprintf('.. Method iii: Detected %d bad channel(s): [%s]\n', ...
        numel(badZIdx), num2str(badZIdx));
else
    Debugging_Info.Method_iii_ZScore.ZScores = [];
    Debugging_Info.Method_iii_ZScore.MedianValues = [];
    Debugging_Info.Method_iii_ZScore.MADValues = [];
    fprintf('.. Method iii: No bad channels detected\n');
end
Debugging_Info.Method_iii_ZScore.Threshold = zscore_threshold;
Debugging_Info.Method_iii_ZScore.FractionThreshold = fraction_threshold;

fprintf('.. Method iii: Z-score screening complete. Detected %d bad channel(s).\n', numel(badZIdx));

end

