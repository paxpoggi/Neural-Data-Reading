function pgp_procProcessingBehaviorOnly(varargin)
%PGP_PROC_BEHAVIORSEGMENTATIONONLY
% Behavior-only postprocessing:
%   - Ensure session-level behavior files exist in Trial_Information:
%       TrialDATA_session_<Session>.mat
%       BlockDATA_session_<Session>.mat
%       TrialVariables_<Session>.mat
%   - Compute cue/epoch-aligned time segments via cgg_getTimeSegments_v2
%     using *existing PARAMETERS* (PARAMETERS_cgg_procFullTrialPreparation_v2).
%   - Save only segmentation outputs (no neural processing).
%
% Uses current PARAMETERS (no overrides):
%   Epoch defaults to 'Decision' (but you can pass Epoch if you want).
%   Activity_Type is whatever PARAMETERS returns (cfg_param.Activity_Type).
%
% Required name-value:
%   'inputfolder' (session folder)
%   'outdatadir'  (top processed output dir)
%
% Optional name-value:
%   'Epoch'          (default 'Decision')
%   'monkey_name'    (default 'Frey')
%   'ExperimentName' (default 'IDED_DBC_AH_AN')
%
% Output file (new):
%   Trial_Information/TimeSegments_<Epoch>_<ActivityType>.mat
%     contains Start/End indices, sampling freq, parameter stamps, and trial numbers if available.
%
% Dependencies:
%   CheckVararginPairs
%   cgg_generateNeuralDataFoldersTopLevel
%   cgg_generateNeuralDataFoldersTopLevel_v2
%   cgg_generateEpochFolders (optional, only if you want epoch folder stamp)
%   PARAMETERS_cgg_procFullTrialPreparation_v2
%   cgg_getTrialVariables now pgp_getTrialVariables
%   cgg_getTimeSegments_v2

%% Parse inputs
inputfolder     = CheckVararginPairs('inputfolder', '', varargin{:});
outdatadir      = CheckVararginPairs('outdatadir',  '', varargin{:});
Epoch           = CheckVararginPairs('Epoch', 'Decision', varargin{:});
monkey_name     = CheckVararginPairs('monkey_name', 'Frey', varargin{:});
ExperimentName  = CheckVararginPairs('ExperimentName','IDED_DBC_AH_AN', varargin{:});

if isempty(inputfolder), error('Missing inputfolder'); end
if isempty(outdatadir),  error('Missing outdatadir');  end

%% Resolve folders (match original pipeline)
cfg     = cgg_generateNeuralDataFoldersTopLevel('inputfolder', inputfolder, 'outdatadir', outdatadir);
cfg_v2  = cgg_generateNeuralDataFoldersTopLevel_v2('inputfolder', inputfolder, 'outdatadir', outdatadir);
cfg_ep  = cgg_generateEpochFolders(Epoch,'inputfolder',inputfolder,'outdatadir',outdatadir);

SessionName = cfg.SessionName;

sessInfoDir   = cfg_v2.outdatadir.Experiment.Session.Trial_Information.path;
if ~exist(sessInfoDir,'dir'), mkdir(sessInfoDir); end

sessTrialPath = fullfile(sessInfoDir, ['TrialDATA_session_'  SessionName '.mat']);
sessBlockPath = fullfile(sessInfoDir, ['BlockDATA_session_'  SessionName '.mat']);
trialVarsPath = fullfile(sessInfoDir, ['TrialVariables_'     SessionName '.mat']);

%% PARAMETERS (do not override)
cfg_param = PARAMETERS_cgg_procFullTrialPreparation_v2(Epoch);
Activity_Type = cfg_param.Activity_Type;
Probe_Order   = cfg_param.Probe_Order;
want_all_Probes = cfg_param.want_all_Probes;
probe_area    = cfg_param.probe_area;

%% Ensure behavior files exist
if ~(exist(sessTrialPath,'file')==2 && exist(sessBlockPath,'file')==2 && exist(trialVarsPath,'file')==2)
    pgp_getTrialVariables('inputfolder', inputfolder, ...
                         'outdatadir',  outdatadir, ...
                         'monkey_name', monkey_name, ...
                         'ExperimentName', ExperimentName);
end
S3 = load(trialVarsPath);  trialVariables = S3.trialVariables;
assert(isstruct(trialVariables) && ~isempty(trialVariables), 'trialVariables not loaded.');
assert(isfield(trialVariables,'TrialNumber'), 'trialVariables missing TrialNumber.');

%% Compute time segments (same calls as original)
[Start_IDX_Data, End_IDX_Data, SF_Data] = cgg_getTimeSegments_v2( ...
    'inputfolder', inputfolder, ...
    'outdatadir',  outdatadir, ...
    'Activity_Type', Activity_Type, ...
    'Frame_Event_Selection', cfg_param.Frame_Event_Selection_Data, ...
    'Frame_Event_Selection_Location', cfg_param.Frame_Event_Selection_Location_Data, ...
    'Frame_Event_Window_Before', cfg_param.Window_Before_Data, ...
    'Frame_Event_Window_After',  cfg_param.Window_After_Data);

[Start_IDX_Base, End_IDX_Base, SF_Base] = cgg_getTimeSegments_v2( ...
    'inputfolder', inputfolder, ...
    'outdatadir',  outdatadir, ...
    'Activity_Type', Activity_Type, ...
    'Frame_Event_Selection', cfg_param.Frame_Event_Selection_Baseline, ...
    'Frame_Event_Selection_Location', cfg_param.Frame_Event_Selection_Location_Baseline, ...
    'Frame_Event_Window_Before', cfg_param.Window_Before_Baseline, ...
    'Frame_Event_Window_After',  cfg_param.Window_After_Baseline);

%% Figure out which probes to stamp (match v3)
% Robust: don't depend on existing probe folders
if want_all_Probes
    Area_Names = Probe_Order;          % from PARAMETERS
else
    Area_Names = {probe_area};
end

assert(~isempty(Area_Names), 'Area_Names empty → nothing to write.');
fprintf('want_all_Probes=%d, numel(Area_Names)=%d\n', want_all_Probes, numel(Area_Names));

%% Build trial list for writing placeholder epoch files
% Use trial numbers from rectrialdefs if present; otherwise trialVariables.
fprintf('sessInfoDir = %s\n', sessInfoDir);
fprintf('trialVarsPath exists = %d\n', exist(trialVarsPath,'file')==2);
fprintf('n trialVariables = %d\n', numel(trialVariables));

% where are rectrialdefs?
trlPath = fullfile(cfg.outdatadir_SessionName,'Trial_Information', ...
                   ['Trial_Definition_' SessionName '.mat']);
fprintf('trlPath = %s\n', trlPath);
fprintf('trlPath exists = %d\n', exist(trlPath,'file')==2);

% compute trialNums the same way you currently do
trialNums = [];
if exist(trlPath,'file')==2
    tmp = load(trlPath);
    if isfield(tmp,'rectrialdefs') && size(tmp.rectrialdefs,2) >= 8
        trialNums = tmp.rectrialdefs(:,8);
    end
end
if isempty(trialNums)
    trialNums = [trialVariables.TrialNumber]';
end
trialNums = trialNums(:);
NumData   = numel(trialNums);

fprintf('NumData (trials to save) = %d\n', NumData);
assert(NumData>0, 'NumData is 0: no trials found → nothing will be written.');





%% Write segments into the *standard* Processing folder

%% Save TimeSegments once (session-level, not probe-level)

epochRoot = cfg_ep.outdatadir.Experiment.Session.Epoched_Data.Epoch.path;
DataDir   = fullfile(epochRoot,'Data');
if ~exist(DataDir,'dir'), mkdir(DataDir); end

segFile = fullfile(DataDir, sprintf('TimeSegments_%s_%s.mat', Epoch, Activity_Type));

if exist(segFile,'file') ~= 2
    SegParams = struct('Epoch',Epoch,'Activity_Type',Activity_Type);
    save(segFile, ...
        'Start_IDX_Data','End_IDX_Data','SF_Data', ...
        'Start_IDX_Base','End_IDX_Base','SF_Base', ...
        'SegParams','SessionName','inputfolder','outdatadir', ...
        '-v7.3');
end

% --- pick one probe just to build cfg_directories paths (session-level write) ---
repProbe = Area_Names{1};  % e.g., 'ACC_001'
cfg_directories = cgg_generateNeuralDataFolders_v2(repProbe, ...
    'inputfolder', inputfolder, 'outdatadir', outdatadir);
cfg_directories.outdatadir.Experiment.Session.Epoched_Data.Epoch = ...
    cfg_ep.outdatadir.Experiment.Session.Epoched_Data.Epoch;
    

% inside your probe loop after cfg_directories is built:
pgp_saveTrialEpochs_BehaviorOnly(trialVariables, Epoch, Probe_Order, cfg_directories, cfg_param);

    
    
fprintf('pgp_proc_BehaviorSegmentationOnly: wrote Epoched_Data scaffold + segments for %s (%s)\n', SessionName, Epoch);
end