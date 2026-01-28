function cgg_procFullTrialPreparation_v3(varargin)
%cgg_procFullTrialPreparation_v2 Summary of this function goes here
%   Detailed explanation goes here

%% Parameters
monkey_name = CheckVararginPairs('monkey_name', 'Frey', varargin{:});

ExperimentName = CheckVararginPairs('ExperimentName','IDED_DBC_AH_AN', varargin{:});

Epoch = CheckVararginPairs('Epoch', 'Decision', varargin{:});

flatten_only = CheckVararginPairs('detrend_flatten_only', false, varargin{:});

do_zscore = CheckVararginPairs('do_zscore', true, varargin{:});

cfg_param = PARAMETERS_cgg_procFullTrialPreparation_v2(Epoch);

TrialDuration_Minimum=cfg_param.TrialDuration_Minimum;
probe_area=cfg_param.probe_area;
want_all_Probes=cfg_param.want_all_Probes;

% Get Activity_Type from parameters - supports 'MUA', 'LFP', or 'both'
Activity_Types_Input = cfg_param.Activity_Type;

% Handle 'both' option - convert to cell array for looping
if ischar(Activity_Types_Input) && strcmpi(Activity_Types_Input, 'both')
    Activity_Types_to_Process = {'MUA', 'LFP'};
elseif iscell(Activity_Types_Input)
    Activity_Types_to_Process = Activity_Types_Input;
else
    Activity_Types_to_Process = {Activity_Types_Input};
end

Frame_Event_Selection_Data=cfg_param.Frame_Event_Selection_Data;
Frame_Event_Selection_Location_Data=cfg_param.Frame_Event_Selection_Location_Data;
Window_Before_Data=cfg_param.Window_Before_Data;
Window_After_Data=cfg_param.Window_After_Data;

Frame_Event_Selection_Baseline=cfg_param.Frame_Event_Selection_Baseline;
Frame_Event_Selection_Location_Baseline=cfg_param.Frame_Event_Selection_Location_Baseline;
Window_Before_Baseline=cfg_param.Window_Before_Baseline;
Window_After_Baseline=cfg_param.Window_After_Baseline;

Epoch=cfg_param.Epoch;

GainValue=cfg_param.GainValue;
LossValue=cfg_param.LossValue;
Minimum_Length=cfg_param.Minimum_Length;
Significance_Value=cfg_param.Significance_Value;
Regression_SP=cfg_param.Regression_SP;

Probe_Order=cfg_param.Probe_Order;


%% Get input/output folders

isfunction=exist('varargin','var');

% Get the directories needed depending on whether this is called as a
% function or as a script for testing
if isfunction
[cfg] = cgg_generateNeuralDataFoldersTopLevel(varargin{:});
elseif (exist('inputfolder','var'))&&(exist('outdatadir','var'))
[cfg] = cgg_generateNeuralDataFoldersTopLevel('inputfolder',...
    inputfolder,'outdatadir',outdatadir);
elseif (exist('inputfolder','var'))&&~(exist('outdatadir','var'))
[cfg] = cgg_generateNeuralDataFoldersTopLevel('inputfolder',inputfolder);
elseif ~(exist('inputfolder','var'))&&(exist('outdatadir','var'))
[cfg] = cgg_generateNeuralDataFoldersTopLevel('outdatadir',outdatadir);
else
[cfg] = cgg_generateNeuralDataFoldersTopLevel;
end

inputfolder=cfg.inputfolder;
outdatadir=cfg.outdatadir;
% Note: cfg_epoch is now generated inside the Activity_Type loop to support separate output folders

% ---- Load (or create) session-level behavior once ----
[cfg_v2] = cgg_generateNeuralDataFoldersTopLevel_v2('inputfolder',inputfolder,'outdatadir',outdatadir);


sessInfoDir   = cfg_v2.outdatadir.Experiment.Session.Trial_Information.path;
sessTrialPath = fullfile(sessInfoDir, ['TrialDATA_session_'  cfg.SessionName '.mat']);
sessBlockPath = fullfile(sessInfoDir, ['BlockDATA_session_'  cfg.SessionName '.mat']);
trialVarsPath = fullfile(sessInfoDir, ['TrialVariables_'      cfg.SessionName '.mat']);

TrialDATA_session = [];
BlockDATA_session = [];
trialVariables    = [];

% If any of the 3 session files are missing, create them once
if ~(exist(sessTrialPath,'file') && exist(sessBlockPath,'file') && exist(trialVarsPath,'file'))
    % This call returns trialVariables and (as a side-effect) saves all three files
    trialVariables = cgg_getTrialVariables( ...
        'inputfolder', inputfolder, ...
        'outdatadir',  outdatadir, ...
        'monkey_name', monkey_name, ...
        'ExperimentName', ExperimentName);
end

% Now load all three from disk (robust even if they already existed)
S1 = load(sessTrialPath);   TrialDATA_session  = S1.TrialDATA;
S2 = load(sessBlockPath);   BlockDATA_session  = S2.BlockDATA;
S3 = load(trialVarsPath);   trialVariables     = S3.trialVariables;

assert(exist(sessTrialPath,'file')==2 && exist(sessBlockPath,'file')==2 && exist(trialVarsPath,'file')==2, ...
    'Missing session files:\n%s\n%s\n%s', sessTrialPath, sessBlockPath, trialVarsPath);

assert(exist('trialVariables','var')==1 && isstruct(trialVariables), 'trialVariables not loaded as struct');
assert(isfield(trialVariables,'TrialNumber'), ...
    'trialVariables missing TrialNumber. Fields are: %s', strjoin(fieldnames(trialVariables),', '));


Session_Start_Message=sprintf('*** Starting Processing Session: %s',cfg.SessionName);
Session_End_Message=sprintf('*** Finished Processing Session: %s',cfg.SessionName);
disp(Session_Start_Message);

%% Loop through Activity Types (MUA, LFP, or both)
for activity_type_idx = 1:length(Activity_Types_to_Process)
    Activity_Type = Activity_Types_to_Process{activity_type_idx};
    fprintf('\n=== Processing Activity Type: %s ===\n', Activity_Type);

    % Load activity-type-specific parameters from PARAMETERS
    cfg_param_activity = PARAMETERS_cgg_procFullTrialPreparation_v2(Epoch, Activity_Type);
    Smooth_Factor = cfg_param_activity.Smooth_Factor;
    SmoothType = cfg_param_activity.SmoothType;
    PassBand = cfg_param_activity.PassBand;

    % Generate epoch folders with Activity_Type for separate output paths
    [cfg_epoch] = cgg_generateEpochFolders(Epoch, 'inputfolder', inputfolder, ...
        'outdatadir', outdatadir, 'Activity_Type', Activity_Type);

%%
IsSessionProcessed=cgg_checkEpochSessionProcessed(cfg_epoch);
if ~IsSessionProcessed
SessionIssue=false;
%%
if want_all_Probes
Area_Names = cgg_getProbeAreas(cfg.outdatadir_SessionName);
% Output=cell(length(Area_Names),1);
else
Area_Names={probe_area};
end

%% Get the time point indices for the trials
[Start_IDX_Data,End_IDX_Data,SF_Data] = cgg_getTimeSegments_v2(...
    'inputfolder',inputfolder,'outdatadir',outdatadir,...
    'Activity_Type',Activity_Type,...
    'Frame_Event_Selection',Frame_Event_Selection_Data,...
    'Frame_Event_Selection_Location',Frame_Event_Selection_Location_Data,...
    'Frame_Event_Window_Before',Window_Before_Data,...
    'Frame_Event_Window_After',Window_After_Data);

[Start_IDX_Base,End_IDX_Base,~] = cgg_getTimeSegments_v2(...
    'inputfolder',inputfolder,'outdatadir',outdatadir,...
    'Activity_Type',Activity_Type,...
    'Frame_Event_Selection',Frame_Event_Selection_Baseline,...
    'Frame_Event_Selection_Location',Frame_Event_Selection_Location_Baseline,...
    'Frame_Event_Window_Before',Window_Before_Baseline,...
    'Frame_Event_Window_After',Window_After_Baseline);

% ---- Session-level trial variables (compute once, reuse per probe) from above ----

TrialVariableTrialNumber = [trialVariables(:).TrialNumber];

%% Sanity checks (add here, before segmentation/criteria)
assert(~isempty(trialVariables) && isstruct(trialVariables), ...
    'trialVariables not loaded properly');
assert(isfield(trialVariables,'TrialNumber'), ...
    'trialVariables missing TrialNumber. Fields are: %s', strjoin(fieldnames(trialVariables),', '));
assert(numel(TrialVariableTrialNumber) == numel(trialVariables), ...
    'Mismatch between TrialVariableTrialNumber and trialVariables length');

%% Iterate through all Areas

for aidx=1:length(Area_Names)
this_probe_area=Area_Names{aidx};
    
%% Get input/output folders for Specified Area

[cfg_directories] = cgg_generateNeuralDataFolders_v2(this_probe_area,'inputfolder',inputfolder,'outdatadir',outdatadir);

[cfg_regression] = cgg_generateRegressionFolders(this_probe_area,'inputfolder',inputfolder,'outdatadir',outdatadir);
cfg_directories.outdatadir.Experiment.Session.Regression=cfg_regression.outdatadir.Experiment.Session.Regression;

% [cfg_epoch] = cgg_generateEpochFolders(Epoch,'inputfolder',inputfolder,'outdatadir',outdatadir);
cfg_directories.outdatadir.Experiment.Session.Epoched_Data.Epoch=cfg_epoch.outdatadir.Experiment.Session.Epoched_Data.Epoch;

%% Check if this probe has already been processed

IsProbeProcessed = cgg_checkProbeProcessed(this_probe_area,...
    cfg_directories);

%% Only process if not already processed
if ~IsProbeProcessed

% === Stamp Area and (optionally) save per-probe behavior ===
area_code = area_code_from_name(this_probe_area);

TrialDATA_probe = TrialDATA_session;
BlockDATA_probe = BlockDATA_session;

nTr = numel(TrialDATA_probe.Block);
nBl = numel(BlockDATA_probe.BlockNum);

TrialDATA_probe.Area = repmat(area_code, nTr, 1);
BlockDATA_probe.Area = repmat(area_code, nBl, 1);

% try
%     perProbeDir = cfg_directories.outdatadir.Experiment.Session.Trial_Information.path;
%     if ~exist(perProbeDir, 'dir'); mkdir(perProbeDir); end
%     save(fullfile(perProbeDir, ['TrialDATA_' this_probe_area '.mat']), 'TrialDATA_probe', '-v7.3');
%     save(fullfile(perProbeDir, ['BlockDATA_' this_probe_area '.mat']), 'BlockDATA_probe', '-v7.3');
% catch ME
%     warning(ME.identifier, 'Could not save per-probe Trial/Block data for %s: %s', ...
%             this_probe_area, ME.message);
% end

Start_Message=sprintf('*** Start of Processing of %s',this_probe_area);
disp(Start_Message);

%% Get the full file name
fullfilename = cgg_generateActivityFullFileName('inputfolder',inputfolder,'outdatadir',outdatadir,...
    'Activity_Type',Activity_Type,'probe_area',this_probe_area);

%% Identify the Disconnected Channels

[Connected_Channels,Disconnected_Channels,is_any_previously_rereferenced] = cgg_loadChannelClusteringFromDirectories(cfg_directories);

%% Get the segmented data and smooth it

SamplingFrequency=mode(SF_Data);

[Segmented_Data,TrialNumbers_Data,~] = cgg_getAllTrialDataFromTimeSegments_v2(Start_IDX_Data,End_IDX_Data,fullfilename,Smooth_Factor,'inputfolder',inputfolder,...
    'outdatadir',outdatadir,'SmoothType',SmoothType,'PassBand',PassBand,'SamplingFrequency',SamplingFrequency);

[Segmented_Baseline,TrialNumbers_Baseline,~] = cgg_getAllTrialDataFromTimeSegments_v2(Start_IDX_Base,End_IDX_Base,fullfilename,Smooth_Factor,'inputfolder',inputfolder,...
    'outdatadir',outdatadir,'SmoothType',SmoothType,'PassBand',PassBand,'SamplingFrequency',SamplingFrequency);

%% Detrend the data according to the baseline period
% added in option to not subtract y intercept and only flatten
[Detrend_Data,Detrend_Baseline] = cgg_procDetrendFromBaseline(Segmented_Data,Segmented_Baseline,TrialNumbers_Data,TrialNumbers_Baseline,flatten_only);

% %% Get the trial variables (this has been adjusted to before the probe
% loop so that it is only computed once, probe area is added during loop)
% 
% [trialVariables] = cgg_getTrialVariables('inputfolder',inputfolder,'outdatadir',outdatadir,'monkey_name',monkey_name);
% TrialVariableTrialNumber=[trialVariables(:).TrialNumber];

%% Select the data that is not aborted or too long


[TrialCondition,MatchValue] = cgg_getTrialCriteriaBaseline(trialVariables,'TrialDuration_Minimum',TrialDuration_Minimum);

[MatchData,~,~,MatchTrialNumber_Data] = cgg_getSeparateTrialsByCriteria_v2(TrialCondition,MatchValue,TrialVariableTrialNumber,Detrend_Data,TrialNumbers_Data);
[MatchBaseline,~,~,MatchTrialNumber_Baseline] = cgg_getSeparateTrialsByCriteria_v2(TrialCondition,MatchValue,TrialVariableTrialNumber,Detrend_Baseline,TrialNumbers_Baseline);

FullBaseline=MatchBaseline;
MatchTrialNumber_FullBaseline=MatchTrialNumber_Baseline;

%% Normalize the baseline and data according to the baseline period
% added in option to skip zscore normalization
[Mean_Norm_Data,Mean_Norm_Baseline,...
    STD_ERROR_Norm_Data,STD_ERROR_Norm_Baseline,...
    Norm_Data,Norm_Baseline] = ...
    cgg_procTrialNormalization_v2(MatchData,MatchBaseline,FullBaseline,MatchTrialNumber_Data,MatchTrialNumber_Baseline,MatchTrialNumber_FullBaseline,do_zscore);

if iscell(FullBaseline)
    disp('✅ Per-trial baseline (cell input) → trial-specific μ and σ used for z-scoring.');
else
    disp('⚠️ Numeric baseline (array input) → one grand μ and σ used for all trials.');
end

%% Regression

TrialNumbers=MatchTrialNumber_Data;
InData=Norm_Data;

[Significant_Channels,NotSignificant_Channels] = cgg_procChannelSelectionFromRegression(InData,trialVariables,SamplingFrequency,Regression_SP,TrialNumbers,Significance_Value,Minimum_Length,GainValue,LossValue,cfg_directories,'Connected_Channels',Connected_Channels);

%%

Output=struct();

Output(1).Name='Description of Each Field';
Output(2).Name='Data';
Output(3).Name='Baseline';

Output(1).Mean={'Mean Value of the signal source across trials.';...
    ['The value for each time point and each channel is averaged '...
    'across each trial.']};
Output(2).Mean=Mean_Norm_Data;
Output(3).Mean=Mean_Norm_Baseline;

Output(1).STD_Error={['Standard Error of the mean of the signal source '...
    'across trials.'];...
    ['The value for each time point and each channel is averaged '...
    'across each trial. Then the standard error of this mean is taken.']};
Output(2).STD_Error=STD_ERROR_Norm_Data;
Output(3).STD_Error=STD_ERROR_Norm_Baseline;

if do_zscore
    Output(1).Trials={'All the trials for the data source';...
        ['Each channel is baseline z-scored by the mean and standard '...
        'deviation that come from the FullBaseline. This FullBaseline '...
        'excludes aborted trials and trials longer than specified. The '...
        'activity of all the trials for all time points of a channel are '...
        'used to calculate the mean and standard deviations for normalizing']};
else
    Output(1).Trials={'All the trials for the data source'; ...
        ['Trials are detrended relative to baseline (trend flattened). ' ...
         'No baseline z-scoring was applied (raw units after detrend).']};
end
Output(2).Trials=Norm_Data;
Output(3).Trials=Norm_Baseline;

Output(1).TrialNumber={'The trial numbers for each trial.';...
    ['The trial number is unique for each trial whether it is aborted '...
    'or not. This value indicates which of the trials is included in '...
    'this data since there are no numbers on the Trials field. The '...
    'first trial in the Trials field could have trial number 2. This '...
    'would be the second trial in the session but the first in the '...
    'Trials field']};
Output(2).TrialNumber=MatchTrialNumber_Data;
Output(3).TrialNumber=MatchTrialNumber_Baseline;

Output(1).Connected_Channels={'Channels that are connected.';...
    ['The Channels that are in the brain and recording brain activity '...
    'instead of random noise unrelated to the brain. The first entry '...
    'represents the connected channels and the second entry '...
    'represents disconnected channels.']};
Output(2).Connected_Channels=Connected_Channels;
Output(3).Connected_Channels=Disconnected_Channels;

Output(1).Significant_Channels={'Channels that are significant.';...
    ['The Channels that show significant activity. If the model '...
    'singificantly predicts activity over no model within a specific '...
    'period then the channel is considered significantly modulated. '...
    'The predictors for the model are Rewarded, Learned, Attentional '...
    'Load, Gain, Loss, Previous. The first entry represents the '...
    'significant channels and the second entry represents not '...
    'significant channels.']};
Output(2).Significant_Channels=Significant_Channels;
Output(3).Significant_Channels=NotSignificant_Channels;

%% 
SizeIssue = pgp_saveTrialEpochs(Output,this_probe_area,trialVariables,Epoch,Probe_Order,cfg_directories,cfg_param);

if SizeIssue
    SessionIssue=true;
end

% if want_all_Probes
%     Output{aidx}=this_Output;
% else
%     Output=this_Output;
% end

End_Message=sprintf('*** End of Processing of %s',this_probe_area);

disp(End_Message);
end % End If for whether Probe has been processed

end % End Iteration through all the Probes
    
cgg_checkEpochSessionProcessed(cfg_epoch,'SessionFinished',~SessionIssue);

end % End If for whether Session has been processed

end % End Activity_Type loop

disp(Session_End_Message);
end

% helper function for area code
function code = area_code_from_name(area_name)
    a = upper(string(area_name));
    if startsWith(a,"ACC")
        code = 1;
    elseif startsWith(a,"CD")
        code = 2;
    elseif startsWith(a,"PFC")
        code = 3;
    end
end