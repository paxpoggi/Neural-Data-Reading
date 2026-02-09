function [Connected_Channels,Disconnected_Channels,is_previously_rereferenced,Debugging_Info] = cgg_getDisconnectedChannels_v3(Trial_Numbers,Count_Sel_Trial,fullfilename,varargin)
%CGG_GETDISCONNECTEDCHANNELS_V3 Identify disconnected/bad channels using clustering
%
%   [Connected, Disconnected, is_reref, Debug] = cgg_getDisconnectedChannels_v3(
%       Trial_Numbers, Count_Sel_Trial, fullfilename, 'SessionName', S, 'probe_area', P)
%
%   This function identifies disconnected channels by clustering channel
%   data and finding channels that cluster with known bad channels.
%   Channels with absolute wideband values exceeding a threshold are
%   automatically detected and added to the seed channel list.
%
%   Parameters:
%       Trial_Numbers   - Array of available trial numbers
%       Count_Sel_Trial - Number of trials to sample for analysis
%       fullfilename    - Format string for trial file paths (e.g., 'path/Trial_%d.mat')
%       SessionName     - (Optional) Session name for session-specific bad channel seeds
%       probe_area      - (Optional) Probe area name (e.g., 'ACC_001') for area-specific seeds

% Parse optional parameters
SessionName = CheckVararginPairs('SessionName', '', varargin{:});
probe_area = CheckVararginPairs('probe_area', '', varargin{:});

NumTrials=length(Trial_Numbers);

%%

cfg=PARAMETERS_cgg_proc_NeuralDataPreparation('SessionName','none');

lfp_maxfreq=cfg.lfp_maxfreq;
lfp_samprate=cfg.lfp_samprate;
spike_minfreq=cfg.spike_minfreq;
rect_bandfreqs=cfg.rect_bandfreqs;
rect_lowpassfreq=cfg.rect_lowpassfreq;
rect_samprate=cfg.rect_samprate;

% Wrapping this to suppress the annoying banner.
ft_defaults;
        
% Suppress spammy Field Trip notifications.
ft_notice('off');
ft_info('off');
ft_warning('off');

% Suppress Matlab warnings (the NPy library generates these).
oldwarnstate = warning('off');

% Limit the number of channels LoopUtil will load into memory at a time.
% 30 ksps double-precision data takes up about 1 GB per channel-hour.
nlFT_setMemChans(8);
%%
if Count_Sel_Trial>NumTrials
    Count_Sel_Trial=NumTrials;
end

Trial_Permutation=randperm(NumTrials);
Trial_Numbers_Permute=Trial_Numbers(Trial_Permutation);
Sel_Trial=Trial_Numbers_Permute(1:Count_Sel_Trial);
Sel_Trial=sort(Sel_Trial);

InData_WB=cell(1,Count_Sel_Trial);
InData_LFP=cell(1,Count_Sel_Trial);
is_previously_rereferenced=zeros(1,Count_Sel_Trial);
parfor tidx=1:length(Sel_Trial)
    this_tidx=Sel_Trial(tidx);
    
this_recdata=load(sprintf(fullfilename,this_tidx));
this_recdata_Field_Names=fieldnames(this_recdata);
this_recdata=this_recdata.(this_recdata_Field_Names{1});

is_previously_rereferenced(tidx)=cgg_checkFTRereference(this_recdata);

    % [ recdata_lfp, ~, ~ ] = ...
    %     euFT_getDerivedSignals( this_recdata, lfp_maxfreq, ...
    %     lfp_samprate, spike_minfreq, rect_bandfreqs, rect_lowpassfreq, ...
    %     rect_samprate, false);

% InData{tidx}=recdata_lfp.trial{1};
InData_WB{tidx}=this_recdata.trial{1};
InData_LFP{tidx}=this_recdata.trial{1}; 

end

is_previously_rereferenced=any(is_previously_rereferenced);

% Get number of channels from first trial
[NumChannels,~]=size(InData_WB{1});

%%
cfg_disconnected = PARAMETERS_cgg_getDisconnectedChannels('NumChannels',NumChannels,'SessionName',SessionName,'probe_area',probe_area);

Start_Group=cfg_disconnected.Start_Group;
End_Group=cfg_disconnected.End_Group;
NumReplicates=cfg_disconnected.NumReplicates;
InDistance={cfg_disconnected.InDistance,cfg_disconnected.InDistance};
NumIterations=cfg_disconnected.NumIterations;
Disconnected_Channels_GT=cfg_disconnected.Disconnected_Channels_GT;
Disconnected_Threshold=cfg_disconnected.Disconnected_Threshold;
Wideband_Threshold=cfg_disconnected.Wideband_Threshold;
Wideband_Threshold_Trial_Percentage=cfg_disconnected.Wideband_Threshold_Trial_Percentage;

% Store original seed channels before adding threshold-based channels
Disconnected_Channels_GT_Original = Disconnected_Channels_GT;

% Detect channels with absolute wideband values exceeding threshold
% Check if threshold is exceeded in at least X% of sampled trials
required_trials = ceil(Wideband_Threshold_Trial_Percentage * length(InData_WB));
fprintf('.. Checking for channels with absolute wideband > %d in at least %.0f%% (%d/%d) of sampled trial(s)...\n', ...
    Wideband_Threshold, Wideband_Threshold_Trial_Percentage * 100, required_trials, length(InData_WB));

% Count how many trials exceed threshold for each channel
trials_exceeding_per_channel = zeros(NumChannels, 1);
max_abs_per_channel_per_trial = zeros(NumChannels, length(InData_WB));  % Store max per trial for debugging

for tidx = 1:length(InData_WB)
    % Get max absolute value per channel for this trial
    max_abs_this_trial = max(abs(InData_WB{tidx}), [], 2);  % [NumChannels x 1]
    max_abs_per_channel_per_trial(:, tidx) = max_abs_this_trial;
    
    % Count trials where this channel exceeds threshold
    trials_exceeding_per_channel = trials_exceeding_per_channel + (max_abs_this_trial > Wideband_Threshold);
end

% Find channels that exceeded threshold in at least required_trials
threshold_channels = find(trials_exceeding_per_channel >= required_trials)';

% Concatenate data for PCA/clustering (needed for downstream processing)
InData_WB=cell2mat(InData_WB);
InData_LFP=cell2mat(InData_LFP);
InData={InData_LFP,InData_WB};

if ~isempty(threshold_channels)
    fprintf('.. Found %d channel(s) exceeding threshold in >= %d/%d trials: [%s]\n', ...
        numel(threshold_channels), required_trials, length(InData_WB), num2str(threshold_channels));
    
    % Get trial counts and max values for these channels (for reporting)
    trial_counts_for_bad_channels = trials_exceeding_per_channel(threshold_channels);
    max_abs_across_all_trials = max(max_abs_per_channel_per_trial(threshold_channels, :), [], 2);
    
    fprintf('.. Trial counts (exceeded threshold): [%s]\n', ...
        num2str(trial_counts_for_bad_channels));
    fprintf('.. Max absolute values across all trials: [%s]\n', ...
        num2str(max_abs_across_all_trials));
    
    % Combine threshold-based channels with seed channels
    Disconnected_Channels_GT = unique([Disconnected_Channels_GT(:); threshold_channels(:)])';
    
    num_added = numel(setdiff(Disconnected_Channels_GT, Disconnected_Channels_GT_Original));
    if num_added > 0
        fprintf('.. Added %d channel(s) from threshold detection to seed list\n', num_added);
    end
else
    fprintf('.. No channels exceeded wideband threshold in >= %d/%d trials\n', required_trials, length(InData_WB));
end

fprintf('.. Combined seed channels (parameters + threshold): [%s]\n', ...
    num2str(Disconnected_Channels_GT));

% Store Method i (Wideband Threshold) results in Debugging_Info
Debugging_Info_Method_i = struct();
Debugging_Info_Method_i.Channels = threshold_channels;
if ~isempty(threshold_channels)
    % Store max absolute values across all trials for each bad channel
    Debugging_Info_Method_i.MaxAbsoluteValues = max(max_abs_per_channel_per_trial(threshold_channels, :), [], 2);
    % Store max per trial for detailed analysis
    Debugging_Info_Method_i.MaxAbsoluteValuesPerTrial = max_abs_per_channel_per_trial(threshold_channels, :);
    % Store trial counts (how many trials exceeded threshold) for each bad channel
    Debugging_Info_Method_i.Trials_Exceeding_Per_Channel = trials_exceeding_per_channel(threshold_channels);
else
    Debugging_Info_Method_i.MaxAbsoluteValues = [];
    Debugging_Info_Method_i.MaxAbsoluteValuesPerTrial = [];
    Debugging_Info_Method_i.Trials_Exceeding_Per_Channel = [];
end
Debugging_Info_Method_i.Threshold = Wideband_Threshold;
Debugging_Info_Method_i.Wideband_Threshold_Trial_Percentage = Wideband_Threshold_Trial_Percentage;
Debugging_Info_Method_i.Required_Trials_Threshold = required_trials;
Debugging_Info_Method_i.NumTrialsChecked = length(InData_WB);
Debugging_Info_Method_i.OriginalSeeds = Disconnected_Channels_GT_Original;
Debugging_Info_Method_i.CombinedSeeds = Disconnected_Channels_GT;

%%
[Connected_Channels,Disconnected_Channels,Debugging_Info] = ...
    cgg_getDisconnectedChannelsIteration_v2(InData,NumReplicates,...
    InDistance,Start_Group,End_Group,Disconnected_Channels_GT,...
    Disconnected_Threshold,NumIterations);

% Add Method i results to Debugging_Info
Debugging_Info.Method_i_WidebandThreshold = Debugging_Info_Method_i;

end

