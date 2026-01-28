function [Connected_Channels,Disconnected_Channels,is_previously_rereferenced,Debugging_Info] = cgg_getDisconnectedChannels_v3(Trial_Numbers,Count_Sel_Trial,fullfilename,varargin)
%CGG_GETDISCONNECTEDCHANNELS_V3 Identify disconnected/bad channels using clustering
%
%   [Connected, Disconnected, is_reref, Debug] = cgg_getDisconnectedChannels_v3(
%       Trial_Numbers, Count_Sel_Trial, fullfilename, 'SessionName', S, 'probe_area', P)
%
%   This function identifies disconnected channels by clustering channel
%   data and finding channels that cluster with known bad channels.
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

    [ recdata_lfp, ~, ~ ] = ...
        euFT_getDerivedSignals( this_recdata, lfp_maxfreq, ...
        lfp_samprate, spike_minfreq, rect_bandfreqs, rect_lowpassfreq, ...
        rect_samprate, false);

% InData{tidx}=recdata_lfp.trial{1};
InData_WB{tidx}=this_recdata.trial{1};
InData_LFP{tidx}=this_recdata.trial{1}; % TODO: <-- BUG: Should use recdata_lfp

end

is_previously_rereferenced=any(is_previously_rereferenced);

InData_WB=cell2mat(InData_WB);
InData_LFP=cell2mat(InData_LFP);
[NumChannels,~]=size(InData_WB);

InData={InData_LFP,InData_WB};

%%
cfg_disconnected = PARAMETERS_cgg_getDisconnectedChannels('NumChannels',NumChannels,'SessionName',SessionName,'probe_area',probe_area);

Start_Group=cfg_disconnected.Start_Group;
End_Group=cfg_disconnected.End_Group;
NumReplicates=cfg_disconnected.NumReplicates;
InDistance={cfg_disconnected.InDistance,cfg_disconnected.InDistance};
NumIterations=cfg_disconnected.NumIterations;
Disconnected_Channels_GT=cfg_disconnected.Disconnected_Channels_GT;
Disconnected_Threshold=cfg_disconnected.Disconnected_Threshold;
%%
[Connected_Channels,Disconnected_Channels,Debugging_Info] = ...
    cgg_getDisconnectedChannelsIteration_v2(InData,NumReplicates,...
    InDistance,Start_Group,End_Group,Disconnected_Channels_GT,...
    Disconnected_Threshold,NumIterations);

end

