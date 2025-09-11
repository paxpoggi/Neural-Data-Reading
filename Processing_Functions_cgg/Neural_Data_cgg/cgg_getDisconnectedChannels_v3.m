function [Connected_Channels,Disconnected_Channels,is_previously_rereferenced,Debugging_Info] = cgg_getDisconnectedChannels_v3(Trial_Numbers,Count_Sel_Trial,fullfilename)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

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
InData_LFP{tidx}=this_recdata.trial{1};

end

is_previously_rereferenced=any(is_previously_rereferenced);

InData_WB=cell2mat(InData_WB);
InData_LFP=cell2mat(InData_LFP);
[NumChannels,~]=size(InData_WB);

InData={InData_LFP,InData_WB};

%%
cfg_disconnected = PARAMETERS_cgg_getDisconnectedChannels('NumChannels',NumChannels);

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

