function cfg = PARAMETERS_cgg_procFullTrialPreparation_v2(Epoch)


% This script includes the Parameters for cgg_procFullTrialPreparation_v2.
% The parameters are explained and default values are included.

%%
TrialDuration_Minimum=10;
Count_Sel_Trial=30;

probe_area='ACC_001';
Activity_Type='MUA';
Smooth_Factor=50;
SmoothType='gaussian'; % None
want_all_Probes=true;
PassBand = NaN; % [10,36]

Increment_Time=25; %Value in ms

switch Epoch
    case 'Epoch_1'
        Frame_Event_Selection_Data = {'SelectObject','SelectObject'};
        Frame_Event_Selection_Location_Data = {'START','END'};
        Frame_Event_Selection_Baseline = {'Blink','BaselineNoFix'};
        Frame_Event_Selection_Location_Baseline = {'START','END'};
    case 'Epoch_2'
        Frame_Event_Selection_Data = {'Fixation','Fixation'};
        Frame_Event_Selection_Location_Data = {'START','END'};
        Frame_Event_Selection_Baseline = {'Blink','BaselineNoFix'};
        Frame_Event_Selection_Location_Baseline = {'START','END'};
    case 'Epoch_3'
        Frame_Event_Selection_Data = {'ChoiceToFB','Reward'};
        Frame_Event_Selection_Location_Data = {'START','END'};
        Frame_Event_Selection_Baseline = {'Blink','BaselineNoFix'};
        Frame_Event_Selection_Location_Baseline = {'START','END'};
    case 'Decision'
        Frame_Event_Selection_Data = 'SelectObject';
        Frame_Event_Selection_Location_Data = 'END';
        Frame_Event_Selection_Baseline = 'Blink';
        Frame_Event_Selection_Location_Baseline = 'START';
    otherwise
        Frame_Event_Selection_Data = 'SelectObject';
        Frame_Event_Selection_Location_Data = 'END';
        Frame_Event_Selection_Baseline = 'Blink';
        Frame_Event_Selection_Location_Baseline = 'START';
end

Window_Before_Data = 1.5;
Window_After_Data = 1.5;

Window_Before_Baseline = 0;
Window_After_Baseline = 0.5;
%% PreProcessing Parameters
cfg_PreProcessing = PARAMETERS_cgg_proc_NeuralDataPreparation('SessionName','none');
switch Activity_Type
    case 'MUA'
        SamplingFrequency = cfg_PreProcessing.rect_samprate;
    case 'LFP'
        SamplingFrequency = cfg_PreProcessing.lfp_samprate;
    case 'ZZZZ'
        SamplingFrequency = cfg_PreProcessing.ZZZ;
    otherwise
        SamplingFrequency = cfg_PreProcessing.rect_samprate;
end


%% Regression Parameters

GainValue=3;
LossValue=-3;

Regression_SP=25;
Significance_Value=0.05;
Minimum_Length=50;

%%

Probe_Order={'ACC_001','ACC_002','PFC_001','PFC_002','CD_001','CD_002'};
FeatureValues_Names={'Shape','Pattern','Color','Texture','Arms'};
Regression_Names = reordercats(categorical(FeatureValues_Names),FeatureValues_Names);
Regression_Names = {'Intercept','Rewarded','Learned', 'Attention 2', 'Attention 3', 'Gain', 'Loss', 'Previous'};
Regression_Names = reordercats(categorical(Regression_Names),Regression_Names);
%%

w = whos;
for a = 1:length(w) 
cfg.(w(a).name) = eval(w(a).name); 
end


end

%
% This is the end of the file.
