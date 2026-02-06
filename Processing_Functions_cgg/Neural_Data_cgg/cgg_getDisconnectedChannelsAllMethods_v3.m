function [Connected_Channels, Disconnected_Channels, is_previously_rereferenced, Debugging_Info, goodRef] = ...
    cgg_getDisconnectedChannelsAllMethods_v3(Count_Sel_Trial, varargin)
%CGG_GETDISCONNECTEDCHANNELSALLMETHODS_V3 Orchestrator for all disconnected channel detection methods
%
%   [Connected, Disconnected, is_reref, Debug, goodRef] = ...
%       cgg_getDisconnectedChannelsAllMethods_v3(Count_Sel_Trial, ...)
%
%   This function orchestrates all three methods of disconnected channel detection:
%   - Method i: Wideband threshold detection
%   - Method ii: Clustering-based detection
%   - Method iii: Z-score screening (optional)
%
%   Parameters:
%       Count_Sel_Trial - Number of trials to sample for analysis
%       Required name-value pairs:
%           'inputfolder'     - Input data folder path
%           'outdatadir'      - Output data folder path
%           'Activity_Type'   - Type of activity data (e.g., 'WideBand')
%           'probe_area'      - Probe area name (e.g., 'ACC_001')
%           'clustering_file_name' - Path to Clustering_Results.mat file
%           'outdatadir_WideBand'  - Path to wideband trial files directory
%       Optional name-value pairs:
%           'SessionName'      - Session name for session-specific bad channel seeds
%           'compute_zscore'   - Whether to compute Z-score screening (default: true)
%           'use_zscore'       - Whether to apply Z-score results to channel lists (default: true)
%                                 If compute_zscore=false, use_zscore is ignored
%                                 If compute_zscore=true and use_zscore=false, computes but doesn't apply
%           'zscore_threshold' - Z-score threshold (default: 7)
%           'fraction_threshold' - Fraction threshold (default: 0.01)
%           'nSampleTrials'    - Number of trials to sample for Z-score (default: 10)
%
%   Returns:
%       Connected_Channels        - Final connected channels after all methods
%       Disconnected_Channels     - Final disconnected channels after all methods
%       is_previously_rereferenced - Boolean flag
%       Debugging_Info            - Complete Debugging_Info with all three methods
%       goodRef                   - Good reference channel labels for rereferencing

fprintf('=== Starting Disconnected Channel Detection (All Methods) ===\n');

% Parse required parameters
probe_area = CheckVararginPairs('probe_area', '', varargin{:});
Activity_Type = CheckVararginPairs('Activity_Type', '', varargin{:});
clustering_file_name = CheckVararginPairs('clustering_file_name', '', varargin{:});
outdatadir_WideBand = CheckVararginPairs('outdatadir_WideBand', '', varargin{:});
SessionName = CheckVararginPairs('SessionName', '', varargin{:});

% Parse optional parameters
compute_zscore = CheckVararginPairs('compute_zscore', true, varargin{:});
use_zscore = CheckVararginPairs('use_zscore', true, varargin{:});
zscore_threshold = CheckVararginPairs('zscore_threshold', 7, varargin{:});
fraction_threshold = CheckVararginPairs('fraction_threshold', 0.01, varargin{:});
nSampleTrials = CheckVararginPairs('nSampleTrials', 10, varargin{:});

% If compute_zscore is false, use_zscore is ignored
if ~compute_zscore
    use_zscore = false;
end

% Log parameters
fprintf('.. Parameters:\n');
fprintf('   Probe Area: %s\n', probe_area);
fprintf('   Activity Type: %s\n', Activity_Type);
fprintf('   Trials to sample: %d\n', Count_Sel_Trial);
fprintf('   Compute Z-score (Method iii): %s\n', mat2str(compute_zscore));
fprintf('   Apply Z-score results: %s\n', mat2str(use_zscore));

% Step 1: Call Methods i & ii (Wideband Threshold + Clustering)
fprintf('\n.. Applying Methods i & ii: Wideband Threshold + Clustering...\n');
[Connected_Channels, Disconnected_Channels, is_previously_rereferenced, Debugging_Info] = ...
    cgg_getDisconnectedChannelsFromDirectories_v2(Count_Sel_Trial, varargin{:});

fprintf('.. Methods i & ii complete. Connected: %d, Disconnected: %d\n', ...
    numel(Connected_Channels), numel(Disconnected_Channels));

% Step 2: Compute and optionally apply Method iii (Z-score screening)
if compute_zscore
    fprintf('\n.. Computing Method iii: Z-score screening...\n');
    
    % Call Z-score method (always computes and saves to Debugging_Info)
    [badZIdx, Debugging_Info, refLabelsGood] = cgg_getDisconnectedChannelsZScore_v3(...
        Connected_Channels, outdatadir_WideBand, clustering_file_name, Debugging_Info, ...
        'zscore_threshold', zscore_threshold, ...
        'fraction_threshold', fraction_threshold, ...
        'nSampleTrials', nSampleTrials);
    
    fprintf('.. Method iii computed. Detected %d bad channel(s): [%s]\n', ...
        numel(badZIdx), num2str(badZIdx));
    
    % Apply results to channel lists only if use_zscore is true
    if use_zscore
        fprintf('.. Applying Z-score results to channel lists...\n');
        
        % Update Connected/Disconnected lists
        Disconnected_Channels = unique([Disconnected_Channels(:); badZIdx(:)]);
        Connected_Channels = setdiff(Connected_Channels(:), badZIdx(:), 'stable');
        
        fprintf('.. Method iii applied. Updated Connected: %d, Disconnected: %d\n', ...
            numel(Connected_Channels), numel(Disconnected_Channels));
        fprintf('.. Z-score removed %d additional channel(s)\n', numel(badZIdx));
        
        % Recompute "good" ref set but restricted to current Connected (safety)
        % Load labels from first wideband trial file
        wbFiles = dir(fullfile(outdatadir_WideBand, 'WideBand_Trial_*.mat'));
        if ~isempty(wbFiles)
            S0 = load(fullfile(outdatadir_WideBand, wbFiles(1).name), 'this_recdata_wideband');
            labels = S0.this_recdata_wideband.label;
            procLabels = labels(Connected_Channels);
            goodRef = intersect(refLabelsGood, procLabels, 'stable');
        else
            goodRef = Connected_Channels;  % Fallback
        end
    else
        fprintf('.. Z-score results computed but NOT applied to channel lists (use_zscore=false)\n');
        fprintf('.. Results saved in Debugging_Info.Method_iii_ZScore\n');
        
        % Load labels for goodRef (without Z-score filtering, since we didn't apply it)
        wbFiles = dir(fullfile(outdatadir_WideBand, 'WideBand_Trial_*.mat'));
        if ~isempty(wbFiles)
            S0 = load(fullfile(outdatadir_WideBand, wbFiles(1).name), 'this_recdata_wideband');
            labels = S0.this_recdata_wideband.label;
            goodRef = labels(Connected_Channels);
        else
            goodRef = Connected_Channels;  % Fallback
        end
    end
else
    fprintf('\n.. Method iii (Z-score) skipped (compute_zscore=false)\n');
    
    % Load labels for goodRef (without Z-score filtering)
    wbFiles = dir(fullfile(outdatadir_WideBand, 'WideBand_Trial_*.mat'));
    if ~isempty(wbFiles)
        S0 = load(fullfile(outdatadir_WideBand, wbFiles(1).name), 'this_recdata_wideband');
        labels = S0.this_recdata_wideband.label;
        goodRef = labels(Connected_Channels);
    else
        goodRef = Connected_Channels;  % Fallback
    end
end

% Step 3: Save updated results to Clustering_Results.mat
fprintf('\n.. Saving results to Clustering_Results.mat...\n');
m_Cluster = matfile(clustering_file_name, 'Writable', true);
m_Cluster.Connected_Channels = Connected_Channels;
m_Cluster.Disconnected_Channels = Disconnected_Channels;
m_Cluster.is_any_previously_rereferenced = is_previously_rereferenced;
m_Cluster.Debugging_Info = Debugging_Info;

% Step 4: End logging - Final summary
fprintf('\n=== Disconnected Channel Detection Complete ===\n');
fprintf('Final counts - Connected: %d, Disconnected: %d\n', ...
    numel(Connected_Channels), numel(Disconnected_Channels));
if ~isempty(Disconnected_Channels)
    fprintf('Disconnected channels: [%s]\n', num2str(Disconnected_Channels));
else
    fprintf('Disconnected channels: []\n');
end

end

