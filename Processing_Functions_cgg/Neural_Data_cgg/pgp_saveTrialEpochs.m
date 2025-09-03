function SizeIssue = pgp_saveTrialEpochs(Input,Probe_Area,trialVariables,Epoch,Probe_Order,cfg,cfg_param)
%PGP_SAVETRIALEPOCHS Save per-trial epoched data with optional channel masks
% Uses MATFILE pattern so parfor workers don't broadcast Trials.

%% Basic/session info
NumProbes = length(Probe_Order);
this_ProbeNumber = find(strcmp(Probe_Order, Probe_Area), 1);
assert(~isempty(this_ProbeNumber) && this_ProbeNumber>=1 && this_ProbeNumber<=NumProbes, ...
  'Probe_Area "%s" not found in Probe_Order (len=%d).', Probe_Area, NumProbes);

IsProbeProcessed = cgg_checkProbeProcessed(Probe_Area,cfg); %#ok<NASGU>

DataDir       = cfg.outdatadir.Experiment.Session.Epoched_Data.Epoch.Data.path;
TargetDir     = cfg.outdatadir.Experiment.Session.Epoched_Data.Epoch.Target.path;
ProcessingDir = cfg.outdatadir.Experiment.Session.Epoched_Data.Epoch.Processing.path;

Data_SaveName                = '%s_Data_%06d.mat';
Target_SaveName              = 'Target_Information.mat';
ProbeProcessing_SaveName     = 'Probe_Processing_Information.mat';
ParameterProcessing_SaveName = 'Parameters_Processing.yaml';
SessionProcessing_SaveName   = 'Session_Processing_Information.mat'; %#ok<NASGU>

Data_SaveNameFull            = [DataDir filesep Data_SaveName];
Target_SaveNameFull          = [TargetDir filesep Target_SaveName];
ProbeProcessing_SaveNameFull = [ProcessingDir filesep ProbeProcessing_SaveName];
ParameterProcessing_SaveNameFull = [ProcessingDir filesep ParameterProcessing_SaveName];

%% Determine number of trials (NumData)
isDataCell    = iscell(Input(2).Trials);
isDataNumeric = isnumeric(Input(2).Trials);
if isDataCell
    NumData = length(Input(2).Trials);
elseif isDataNumeric
    [~,~,NumData] = size(Input(2).Trials);
else
    warning('DataType:unrecognized','Input Data is an unrecognized class'); 
    NumData = 0;
end

TrialNumbers = Input(2).TrialNumber;   % length == NumData
[~,ChosenTrial] = unique(TrialNumbers,'last');

TrialChosen = false(1, NumData);
TrialChosen(ChosenTrial) = true;
TrialChosen = num2cell(TrialChosen);

Disconnected_Channels    = Input(3).Connected_Channels;     % vector
NotSignificant_Channels  = Input(3).Significant_Channels;   % vector

%% Optional common bad channels (file may not exist)
[cfg_Session] = DATA_cggAllSessionInformationConfiguration;
ResultsDir = cfg_Session(1).outdatadir;

[cfg_Common] = cgg_generateSessionAggregationFolders('TargetDir',ResultsDir, ...
                                                     'Folder','Variables', ...
                                                     'SubFolder','Connected');
ClusteringDir = cfg_Common.TargetDir.Aggregate_Data.Folder.SubFolder.path;
CommonPathNameExt = [ClusteringDir filesep 'CommonBadChannels.mat'];

CommonDisconnectedChannels = [];
if exist(CommonPathNameExt, 'file')
    info = whos('-file', CommonPathNameExt);
    if any(strcmp({info.name}, 'CommonDisconnectedChannels'))
        m_CommonClustering = matfile(CommonPathNameExt, "Writable", false);
        CommonDisconnectedChannels = m_CommonClustering.CommonDisconnectedChannels;
    else
        warning('CommonBadChannels:missingVar', ...
            'File exists but variable "CommonDisconnectedChannels" not found: %s. Using none.', CommonPathNameExt);
    end
else
    warning('CommonBadChannels:notFound', ...
        'Common bad-channel file not found: %s. Using none.', CommonPathNameExt);
end

assert(isvector(CommonDisconnectedChannels) || isempty(CommonDisconnectedChannels), ...
    'CommonDisconnectedChannels must be a vector or empty.');
assert(isvector(Disconnected_Channels),     'Disconnected_Channels must be a vector.');
assert(isvector(NotSignificant_Channels),   'NotSignificant_Channels must be a vector.');

%% ===== MATFILE STAGING (avoid parfor broadcast) =====
bigTrials     = Input(2).Trials;                % cell or 3D numeric
tmpTrialsPath = fullfile(ProcessingDir, 'Trials_tmp.mat');

if iscell(bigTrials)
    Trials_cell = bigTrials;
    if ~isrow(Trials_cell), Trials_cell = Trials_cell.'; end  % normalize to row vector
    save(tmpTrialsPath, 'Trials_cell', '-v7.3');             % HDF5-backed partial load
    Trials_m = matfile(tmpTrialsPath, 'Writable', false);
    isCellTrials = true;
else
    Trials = bigTrials; %#ok<NASGU>
    save(tmpTrialsPath, 'Trials', '-v7.3');
    Trials_m = matfile(tmpTrialsPath, 'Writable', false);
    isCellTrials = false;
end

% prevent giant broadcast of trials to workers
Input(2).Trials = [];

% also avoid broadcasting full struct; just the vector is fine:
TrialNumbers_vec = [trialVariables.TrialNumber];

%% Progress setup
q = parallel.pool.DataQueue;
afterEach(q, @nUpdateWaitbar);

All_Iterations = NumData;
Iteration_Count = 0;
formatSpec = '*** Current Epoch Saving Progress is: %.2f%%%%\n';
Current_Message = sprintf(formatSpec, 0);
fprintf(Current_Message);

%% Run (parallel) and write per-trial files without broadcasting
Target_IDX   = NaN(1, NumData);
SizeIssueFlg = false(1, NumData);   % gather SizeIssue from workers
NumProbes_local = NumProbes;        % capture for parfor

parfor didx = 1:NumData
    this_TrialNumber = TrialNumbers(didx);

    % -- load a single trial --
    if isCellTrials
        c1 = Trials_m.Trials_cell(1, didx);  % 1x1 cell
        this_Data = c1{1};                   % numeric [C x S]
    else
        this_Data = Trials_m.Trials(:,:,didx);  % numeric [C x S]
    end

    this_Data_SaveName = sprintf(Data_SaveNameFull, Epoch, didx);

    % -- clamp masks to valid rows --
    maxCh = size(this_Data,1);
    dc  = Disconnected_Channels(Disconnected_Channels>=1 & Disconnected_Channels<=maxCh);
    ns  = NotSignificant_Channels(NotSignificant_Channels>=1 & NotSignificant_Channels<=maxCh);
    cbc = CommonDisconnectedChannels(CommonDisconnectedChannels>=1 & CommonDisconnectedChannels<=maxCh);

    % -- apply masks (NaN first, then remove rows) --
    if ~isempty(dc),  this_Data(dc,:)  = NaN; end
    if ~isempty(ns),  this_Data(ns,:)  = NaN; end
    if ~isempty(cbc), this_Data(cbc,:) = [];  end

    [this_NumChannels, this_NumSamples] = size(this_Data);

    % fast lookup (vector, not full struct)
    idx = find(TrialNumbers_vec == this_TrialNumber, 1, 'last');
    if isempty(idx)
        warning('pgp_saveTrialEpochs:TrialNotFound', ...
            'TrialNumber %d not found in trialVariables; setting Target_IDX(%d)=NaN', this_TrialNumber, didx);
        Target_IDX(didx) = NaN;
    else
        Target_IDX(didx) = idx;
    end

    % -- ensure file exists with correct shape --
    if ~(exist(this_Data_SaveName,'file')) || ~(exist(ProbeProcessing_SaveNameFull,'file'))
        m = matfile(this_Data_SaveName, 'Writable', true);
        m.Data = NaN(this_NumChannels, this_NumSamples, NumProbes_local, 'like', this_Data);
    else
        m = matfile(this_Data_SaveName, 'Writable', true);
        [nc, nsmp, np] = size(m.Data); %#ok<NASGU>
        if nc~=this_NumChannels || nsmp~=this_NumSamples || np~=NumProbes_local
            warning('DataNumbers:incorrectsize', ...
                ['Saved epoch (%d %d %d) != current (%d %d %d) for area %s. ' ...
                 'Rewriting to all NaN and marking SizeIssue.'], ...
                 nc, nsmp, np, this_NumChannels, this_NumSamples, NumProbes_local, Probe_Area);
            m.Data = NaN(this_NumChannels, this_NumSamples, NumProbes_local, 'like', this_Data);
            SizeIssueFlg(didx) = true;
        end
    end

    % -- write this probe's slice --
    % this_ProbeNumber already asserted valid and <= NumProbes_local
    m.Data(:, :, this_ProbeNumber) = this_Data;

    send(q, didx);
end

SizeIssue = any(SizeIssueFlg);

%% Save the Target Information for Decoding
good = ~isnan(Target_IDX);
if ~all(good)
    warning('pgp_saveTrialEpochs:MissingTarget', ...
        'Some trials missing trialVariables mapping (%d of %d). Dropping them from Target.', sum(~good), numel(good));
end
Target = trialVariables(Target_IDX(good));
[Target.TrialChosen] = TrialChosen{good};

if ~(exist(Target_SaveNameFull,'file'))
    m_Target = matfile(Target_SaveNameFull,'Writable',true);
    m_Target.Target = Target;
end

%% Save the Probe Processing Information
if exist(ProbeProcessing_SaveNameFull,'file')
    m_Probe = matfile(ProbeProcessing_SaveNameFull,'Writable',true);
    ProbeProcessing = m_Probe.ProbeProcessing;
else
    ProbeProcessing = struct();
    for pidx = 1:NumProbes
        ProbeProcessing.(Probe_Order{pidx}) = false;
    end
end
ProbeProcessing.(Probe_Area) = true;

if SizeIssue
    for pidx = 1:NumProbes
        ProbeProcessing.(Probe_Order{pidx}) = false;
    end
end
m_Probe = matfile(ProbeProcessing_SaveNameFull,'Writable',true);
m_Probe.ProbeProcessing = ProbeProcessing;

%% Save Session Processing Parameters
WriteYaml(ParameterProcessing_SaveNameFull, cfg_param);

%% ---- nested progress function ----
    function nUpdateWaitbar(~)
        Iteration_Count = Iteration_Count + 1;
        Current_Progress = Iteration_Count/All_Iterations*100;
        Delete_Message = repmat(sprintf('\b'),1,length(Current_Message)-1);
        Current_Message = sprintf(formatSpec, Current_Progress);
        fprintf([Delete_Message,Current_Message]);
    end
end
