function SizeIssue = pgp_saveTrialEpochs(Input,Probe_Area,trialVariables,Epoch,Probe_Order,cfg,cfg_param)
% Save per-trial epoched data to shared trial files (3rd dim = probe).
% Broadcast-safe: stage Trials once to node-local -v7.3 and hand out matfile handles.

%% Basic/session info
NumProbes = length(Probe_Order);
this_ProbeNumber = find(strcmp(Probe_Order, Probe_Area), 1);
assert(~isempty(this_ProbeNumber) && this_ProbeNumber>=1 && this_ProbeNumber<=NumProbes, ...
  'Probe_Area "%s" not found in Probe_Order (len=%d).', Probe_Area, NumProbes);

IsProbeProcessed = cgg_checkProbeProcessed(Probe_Area,cfg); %#ok<NASGU>

DataDir       = cfg.outdatadir.Experiment.Session.Epoched_Data.Epoch.Data.path;
TargetDir     = cfg.outdatadir.Experiment.Session.Epoched_Data.Epoch.Target.path;
ProcessingDir = cfg.outdatadir.Experiment.Session.Epoched_Data.Epoch.Processing.path;

Data_SaveName                = '%s_Data_%06d.mat';               % shared per trial
Target_SaveName              = 'Target_Information.mat';
ProbeProcessing_SaveName     = 'Probe_Processing_Information.mat';
ParameterProcessing_SaveName = 'Parameters_Processing.yaml';
SessionProcessing_SaveName   = 'Session_Processing_Information.mat'; %#ok<NASGU>

Data_SaveNameFull            = fullfile(DataDir, Data_SaveName);
Target_SaveNameFull          = fullfile(TargetDir, Target_SaveName);
ProbeProcessing_SaveNameFull = fullfile(ProcessingDir, ProbeProcessing_SaveName);
ParameterProcessing_SaveNameFull = fullfile(ProcessingDir, ParameterProcessing_SaveName);

%% Determine number of trials
bigTrials     = Input(2).Trials;                        % cell or 3D numeric
isCellTrials  = iscell(bigTrials);
if isCellTrials
    NumData = numel(bigTrials);
elseif isnumeric(bigTrials)
    [~,~,NumData] = size(bigTrials);
else
    warning('DataType:unrecognized','Input Data is an unrecognized class'); 
    NumData = 0;
end

TrialNumbers = Input(2).TrialNumber(:).';               % length == NumData
[~,ChosenTrial] = unique(TrialNumbers,'last');
TrialChosen = false(1, NumData); TrialChosen(ChosenTrial) = true; TrialChosen = num2cell(TrialChosen);

Disconnected_Channels    = Input(3).Connected_Channels;
NotSignificant_Channels  = Input(3).Significant_Channels;

%% Optional common bad channels (file may not exist)
[cfg_Session] = DATA_cggAllSessionInformationConfiguration;
ResultsDir = cfg_Session(1).outdatadir;
[cfg_Common] = cgg_generateSessionAggregationFolders('TargetDir',ResultsDir,'Folder','Variables','SubFolder','Connected');
ClusteringDir = cfg_Common.TargetDir.Aggregate_Data.Folder.SubFolder.path;
CommonPathNameExt = fullfile(ClusteringDir, 'CommonBadChannels.mat');

CommonDisconnectedChannels = [];
if exist(CommonPathNameExt, 'file')
    info = whos('-file', CommonPathNameExt);
    if any(strcmp({info.name}, 'CommonDisconnectedChannels'))
        m_CommonClustering = matfile(CommonPathNameExt, "Writable", false);
        CommonDisconnectedChannels = m_CommonClustering.CommonDisconnectedChannels;
    else
        warning('CommonBadChannels:missingVar','File exists but variable "CommonDisconnectedChannels" not found: %s. Using none.', CommonPathNameExt);
    end
else
    warning('CommonBadChannels:notFound','Common bad-channel file not found: %s. Using none.', CommonPathNameExt);
end

assert(isvector(CommonDisconnectedChannels) || isempty(CommonDisconnectedChannels), 'CommonDisconnectedChannels must be a vector or empty.');
assert(isvector(Disconnected_Channels),     'Disconnected_Channels must be a vector.');
assert(isvector(NotSignificant_Channels),   'NotSignificant_Channels must be a vector.');

%% ===== MATFILE STAGING to avoid broadcast =====
jid = getenv('SLURM_JOB_ID'); if isempty(jid), jid = char(java.util.UUID.randomUUID); end
scratch = getenv('SLURM_TMPDIR'); if isempty(scratch), scratch = tempdir; end
tmpTrialsPath = fullfile(scratch, sprintf('Trials_tmp_%s_%s_%s.mat', jid, Epoch, Probe_Area));


if isCellTrials
    Trials_cell = bigTrials; %#ok<NASGU>

    % normalize to 1 x NumData so workers can do (1,didx) indexing
    Trials_cell = Trials_cell(:).'; %#ok<NASGU>
    NumData = numel(Trials_cell);

    save(tmpTrialsPath, 'Trials_cell', '-v7.3');
else
    Trials = bigTrials; %#ok<NASGU>
    [~,~,NumData] = size(Trials);
    save(tmpTrialsPath, 'Trials', '-v7.3');
end


% free client RAM & prevent parfor broadcast
Input(2).Trials = [];
bigTrials = [];

% mapping vector only
TrialNumbers_vec = [trialVariables.TrialNumber];

% per-worker file handle
TrialsConst = parallel.pool.Constant(@() matfile(tmpTrialsPath,'Writable',false));


%% Environment tweaks
setenv('HDF5_USE_FILE_LOCKING','FALSE');
maxNumCompThreads(1);
setenv('OMP_NUM_THREADS','1');
setenv('MKL_NUM_THREADS','1');

%% Progress (throttled)
q = parallel.pool.DataQueue; afterEach(q, @nUpdateWaitbar);
All_Iterations = NumData; Iteration_Count = 0;
formatSpec = '*** Current Epoch Saving Progress is: %.2f%%%%\n';
Current_Message = sprintf(formatSpec, 0); fprintf(Current_Message);
PROGRESS_EVERY = max(1, floor(NumData/50));   % ~50 updates

%% Run
Target_IDX   = NaN(1, NumData);
SizeIssueFlg = false(1, NumData);
NumProbes_local = NumProbes;

parfor didx = 1:NumData
    Tm = TrialsConst.Value;

    % load one trial (file-backed)
  
    if isCellTrials
        c1 = Tm.Trials_cell(1, didx);   % 1x1 cell from matfile
        this_Data = c1{1};              % numeric [C x S]
    else
        this_Data = Tm.Trials(:,:,didx);
    end


    this_Data_SaveName = sprintf(Data_SaveNameFull, Epoch, didx);

    % masks
    maxCh = size(this_Data,1);
    dc  = Disconnected_Channels(Disconnected_Channels>=1 & Disconnected_Channels<=maxCh);
    ns  = NotSignificant_Channels(NotSignificant_Channels>=1 & NotSignificant_Channels<=maxCh);
    cbc = CommonDisconnectedChannels(CommonDisconnectedChannels>=1 & CommonDisconnectedChannels<=maxCh);

    if ~isempty(dc),  this_Data(dc,:)  = NaN; end
    if ~isempty(ns),  this_Data(ns,:)  = NaN; end
    if ~isempty(cbc), this_Data(cbc,:) = [];  end

    [nCh, nS] = size(this_Data); nP = NumProbes_local;

    % map trial number → target index
    this_TrialNumber = TrialNumbers(didx);
    idx = find(TrialNumbers_vec == this_TrialNumber, 1, 'last');
    if isempty(idx)
        warning('pgp_saveTrialEpochs:TrialNotFound','TrialNumber %d not found; Target_IDX(%d)=NaN', this_TrialNumber, didx);
        Target_IDX(didx) = NaN;
    else
        Target_IDX(didx) = idx;
    end

    % header check + write with retry
    ok = false;
    for attempt = 1:6
        try
            if exist(this_Data_SaveName,'file')
                mf = open_matfile_retry(this_Data_SaveName,false,6,0.25);
                try
                    [nc, nsmp, np] = size(mf,'Data');
                    if ~isequal([nc nsmp np],[nCh nS nP])
                        SizeIssueFlg(didx) = true;
                    end
                catch
                    SizeIssueFlg(didx) = true;
                end
            end
            write_or_update_slice(this_Data_SaveName,'Data',this_ProbeNumber,this_Data,nCh,nS,nP);
            ok = true; break
        catch
            pause(0.2 + 0.1*attempt);
        end
    end
    if ~ok
        error('pgp_saveTrialEpochs:trialWriteFail','Gave up on trial %d → %s', didx, this_Data_SaveName);
    end

    if mod(didx, PROGRESS_EVERY)==0 || didx==NumData
        send(q, didx);
    end
end

SizeIssue = any(SizeIssueFlg);

%% Save Target info
good = ~isnan(Target_IDX);
if ~all(good)
    warning('pgp_saveTrialEpochs:MissingTarget','Some trials missing mapping (%d of %d). Dropping them from Target.', sum(~good), numel(good));
end
Target = trialVariables(Target_IDX(good));
[Target.TrialChosen] = TrialChosen{good};

if ~(exist(Target_SaveNameFull,'file'))
    m_Target = matfile(Target_SaveNameFull,'Writable',true);
    m_Target.Target = Target;
end

%% Save Probe Processing info
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

%% progress callback (host-side only)
    function nUpdateWaitbar(~)
        Iteration_Count = min(All_Iterations, Iteration_Count + PROGRESS_EVERY);
        Current_Progress = Iteration_Count/All_Iterations*100;
        Delete_Message = repmat(sprintf('\b'),1,length(Current_Message)-1);
        Current_Message = sprintf(formatSpec, Current_Progress);
        fprintf([Delete_Message,Current_Message]);
    end
end  % function end

% ===== local subfunctions (parfor-callable) =====
function mf = open_matfile_retry(fname, writable, ntry, pause_s)
if nargin<3, ntry=8; end
if nargin<4, pause_s=0.25; end
lastErr = '';
for k=1:ntry
    try
        mf = matfile(fname,'Writable',logical(writable));
        return
    catch ME
        lastErr = ME.message; pause(pause_s);
    end
end
error('open_matfile_retry:fail','%s (after %d tries): %s', fname, ntry, lastErr);
end

function write_or_update_slice(finalName, varName, probeIdx, X, nCh, nS, nP)
% Lock-guarded slice write: create or update Data(:,:,probeIdx).
lockDir = [finalName,'.lock'];
acquired = false;
for t = 1:40
    acquired = mkdir(lockDir);
    if acquired, break; end
    pause(0.1);
end
if ~acquired, error('write_or_update_slice:lockTimeout','Could not acquire lock for %s', finalName); end
cleanup = onCleanup(@() (exist(lockDir,'dir') && rmdir(lockDir)));

if exist(finalName,'file')
    mf = matfile(finalName,'Writable',true);
    ok = false;
    try
        sz = size(mf, varName);
        ok = isequal(sz, [nCh nS nP]);
    catch
        ok = false;
    end
    if ~ok
        mf.(varName) = NaN(nCh, nS, nP, 'like', X);
    end
    mf.(varName)(:,:,probeIdx) = X;
else
    mf = matfile(finalName,'Writable',true);
    mf.(varName) = NaN(nCh, nS, nP, 'like', X);
    mf.(varName)(:,:,probeIdx) = X;
end
end