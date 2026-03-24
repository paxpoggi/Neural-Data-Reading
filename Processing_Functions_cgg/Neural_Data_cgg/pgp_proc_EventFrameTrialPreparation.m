function [Output, Area_Names] = pgp_proc_EventFrameTrialPreparation(varargin)
%PGP_PROC_EVENTFRAMETRIALPREPARATION
% Minimal fast preprocessing: generate ONLY
%   - Event_Information: Event_Codes_Each_*.mat, Event_Codes_Concatenated_*.mat
%   - Frame_Information: Frame_Data_*.mat
%   - Trial_Information: Trial_Definition_*.mat, Trial_Definition_Table_*.mat
%   - Time_Information: per-trial time vectors (fsample + trial-relative time)
%
% Skips gaze. Skips if outputs already exist.
%
% Dependencies (expected to exist in your codebase):
%   CheckVararginPairs, PARAMETERS_cgg_proc_NeuralDataPreparation
%   euUtil_getExperimentFolders, euUSE_readAllUSEEvents, euUSE_readAllEphysEvents
%   euUSE_removeLargeTimeOffset, euFT_addEventTimestamps
%   euUSE_alignTwoDevices, euAlign_addTimesToAllTables, euAlign_addTimesToTable
%   euUSE_readRawFrameData
%   euAlign_copyMissingEventTables, euFT_addTTLEventsAsCodes
%   euUSE_segmentTrialsByCodes, euFT_defineTrialsUsingCodes
%   cgg_procIdentifyBadTrialNumbers
%
% Outputs:
%   Output, Area_Names kept for compatibility with driver; both empty here.

Output = [];
Area_Names = {};

isfunction = exist('varargin','var');

%% Directories / inputs
if isfunction
    inputfolder = CheckVararginPairs('inputfolder', '', varargin{:});
    outdatadir  = CheckVararginPairs('outdatadir',  '', varargin{:});
else
    inputfolder = '';
    outdatadir  = '';
end

if isempty(inputfolder)
    error('pgp_proc_EventFrameTrialPreparation:MissingInput', ...
        'Must provide ''inputfolder''.');
end
if isempty(outdatadir)
    error('pgp_proc_EventFrameTrialPreparation:MissingOutput', ...
        'Must provide ''outdatadir''.');
end

[inputfolder_dir, SessionName, ~] = fileparts(inputfolder);
[~, ExperimentName, ~] = fileparts(inputfolder_dir);

%% Parameters (only what we need)
cfg = PARAMETERS_cgg_proc_NeuralDataPreparation('SessionName', SessionName);
trial_align_evcode = cfg.trial_align_evcode;
padtime           = cfg.padtime;

%% Output folders
outdatadir_Experiment   = [outdatadir, filesep, ExperimentName];
outdatadir_SessionName  = [outdatadir_Experiment, filesep, SessionName];

outdatadir_EventInformation = [outdatadir_SessionName, filesep, 'Event_Information'];
outdatadir_FrameInformation = [outdatadir_SessionName, filesep, 'Frame_Information'];
outdatadir_TrialInformation = [outdatadir_SessionName, filesep, 'Trial_Information'];
outdatadir_TimeInformation  = [outdatadir_SessionName, filesep, 'Time_Information'];

if ~exist(outdatadir_Experiment, 'dir'),   mkdir(outdatadir_Experiment); end
if ~exist(outdatadir_SessionName, 'dir'),  mkdir(outdatadir_SessionName); end
if ~exist(outdatadir_EventInformation,'dir'), mkdir(outdatadir_EventInformation); end
if ~exist(outdatadir_FrameInformation,'dir'), mkdir(outdatadir_FrameInformation); end
if ~exist(outdatadir_TrialInformation,'dir'), mkdir(outdatadir_TrialInformation); end
if ~exist(outdatadir_TimeInformation,'dir'),  mkdir(outdatadir_TimeInformation); end

%% Output file names
outdatafile_FrameInformation = sprintf([outdatadir_FrameInformation filesep ...
    'Frame_Data_%s.mat'], SessionName);

outdatafile_EventInformation_Each = sprintf([outdatadir_EventInformation filesep ...
    'Event_Codes_Each_%s.mat'], SessionName);

outdatafile_EventInformation_Concatenated = sprintf([outdatadir_EventInformation filesep ...
    'Event_Codes_Concatenated_%s.mat'], SessionName);

outdatafile_TrialInformation = sprintf([outdatadir_TrialInformation filesep ...
    'Trial_Definition_%s.mat'], SessionName);

outdatafile_TrialInformation_Table = sprintf([outdatadir_TrialInformation filesep ...
    'Trial_Definition_Table_%s.mat'], SessionName);


%% Skip if everything exists
need_frame = ~exist(outdatafile_FrameInformation,'file');
need_each  = ~exist(outdatafile_EventInformation_Each,'file');
need_cat   = ~exist(outdatafile_EventInformation_Concatenated,'file');
need_trl   = ~exist(outdatafile_TrialInformation,'file') || ~exist(outdatafile_TrialInformation_Table,'file');
timeDir = fullfile(outdatadir_TimeInformation, 'Spike');
if ~exist(timeDir,'dir')
    need_time = true;
else
    timeFiles = dir(fullfile(timeDir, 'Spike_Trial_*_Time.mat'));
    need_time = isempty(timeFiles);
end
if ~need_frame && ~need_each && ~need_cat && ~need_trl && ~need_time
    fprintf('pgp_proc_EventFrameTrialPreparation: all outputs exist for %s. Skipping.\n', SessionName);
    return;
end

%% TTL / code channel configs (same as your big script)
recbitsignals_openephys = struct();
recbitsignals_intan     = struct();
stimbitsignals          = struct('rwdB', 'Din_002');

reccodesignals_openephys = struct( ...
    'signameraw','rawcodes','signamecooked','cookedcodes', ...
    'channame','DigWordsA_000','bitshift',8);

reccodesignals_intan = struct( ...
    'signameraw','rawcodes','signamecooked','cookedcodes', ...
    'channame','Din_*','bitshift',9);

stimcodesignals = struct( ...
    'signameraw','rawcodes','signamecooked','cookedcodes', ...
    'channame','Din_*','bitshift',9);

trial_metadata_events = struct('trialnum','TrialNumber','trialindex','TrialIndex');

%% Start FieldTrip (needed for ft_read_header + trial def)
evalc('ft_defaults');
ft_notice('off'); ft_info('off'); ft_warning('off');
warning('off');
nlFT_setMemChans(6);

%% Locate folders
[folders_openephys, folders_intanrec, folders_intanstim, folders_unity] = ...
    euUtil_getExperimentFolders(inputfolder);

have_openephys = ~isempty(folders_openephys);
if have_openephys
    folder_record = '';
    for k = 1:numel(folders_openephys)
        test_ttl = fullfile(folders_openephys{k}, ...
            'events','Intan_Rec._Controller-100.0','TTL_1','timestamps.npy');
        if exist(test_ttl,'file')
            info = dir(test_ttl);
            if info.bytes > 1000   % non-empty TTL file
                folder_record = folders_openephys{k};
                break
            end
        end
    end
    if isempty(folder_record)
        error('No OpenEphys recording folder with non-empty TTL events found.');
    end
else
    folder_record = folders_intanrec{1};
end

have_stim = false;
if ~isempty(folders_intanstim)
    folder_stim = folders_intanstim{1};
    have_stim = true;
end

folder_game = folders_unity{1};

%% Headers
rechdr = ft_read_header(folder_record, 'headerformat', 'nlFT_readHeader');
if have_stim
    stimhdr = ft_read_header(folder_stim, 'headerformat', 'nlFT_readHeader');
end

%% If we need any of frame/events/trials/time, we must (re)build alignment
% (If trialcodes_concat already exists and frame exists, you *could* shortcut,
% but keeping it simple/robust.)

disp('-- Reading USE + ephys events (minimal pipeline).');

[boxevents, gameevents, evcodedefs] = euUSE_readAllUSEEvents(folder_game);

recbitsignals = recbitsignals_openephys;
reccodesignals = reccodesignals_openephys;
if ~have_openephys
    recbitsignals = recbitsignals_intan;
    reccodesignals = reccodesignals_intan;
end

[~, recevents] = euUSE_readAllEphysEvents( ...
    folder_record, recbitsignals, reccodesignals, evcodedefs );

if have_stim
    [~, stimevents] = euUSE_readAllEphysEvents( ...
        folder_stim, stimbitsignals, stimcodesignals, evcodedefs );
end

%% Clean up Unity timestamps offset
[unityreftime, gameevents] = euUSE_removeLargeTimeOffset(gameevents, 'unityTime');
[unityreftime, boxevents]  = euUSE_removeLargeTimeOffset(boxevents,  'unityTime', unityreftime);

%% Add recorder timestamps to ephys event tables
recevents = euFT_addEventTimestamps(recevents, rechdr.Fs, 'sample', 'recTime');
if have_stim
    stimevents = euFT_addEventTimestamps(stimevents, stimhdr.Fs, 'sample', 'stimTime');
end

%% Align devices (recTime is the master)
alignconfig = struct();
alignconfig.coarsewindows = 1000;

disp('.. Aligning SynchBox -> recorder.');
eventtables = { recevents.rawcodes, boxevents.rawcodes };
[~, times_recorder_synchbox] = euUSE_alignTwoDevices( ...
    eventtables, 'recTime', 'synchBoxTime', alignconfig );

boxevents = euAlign_addTimesToAllTables( ...
    boxevents, 'synchBoxTime', 'recTime', times_recorder_synchbox );

disp('.. Aligning USE -> recorder.');
eventtables = { recevents.cookedcodes, gameevents.cookedcodes };
[~, times_recorder_game] = euUSE_alignTwoDevices( ...
    eventtables, 'recTime', 'unityTime', alignconfig );

gameevents = euAlign_addTimesToAllTables( ...
    gameevents, 'unityTime', 'recTime', times_recorder_game );

if have_stim
    disp('.. Aligning stimulator -> recorder.');
    eventtables = { recevents.cookedcodes, stimevents.cookedcodes };
    [~, times_recorder_stimulator] = euUSE_alignTwoDevices( ...
        eventtables, 'recTime', 'stimTime', alignconfig );

    stimevents = euAlign_addTimesToAllTables( ...
        stimevents, 'stimTime', 'recTime', times_recorder_stimulator );

    boxevents = euAlign_addTimesToAllTables( ...
        boxevents, 'recTime', 'stimTime', times_recorder_stimulator );
end

%% Frame data (skip gaze entirely)
disp('-- Reading USE frame data.');
gameframedata = euUSE_readRawFrameData(folder_game);

gameframedata.eyeTime   = gameframedata.EyetrackerTimeSeconds;
gameframedata.unityTime = gameframedata.SystemTimeSeconds - unityreftime;

% Add recorder timestamps to frame data
disp('.. Propagating recorder timestamps to frame data table.');
gameframedata = euAlign_addTimesToTable(gameframedata, ...
    'unityTime', 'recTime', times_recorder_game);

%% Clean up / fill missing events from SynchBox
disp('-- Checking for missing recorder events.');
recevents = euAlign_copyMissingEventTables( ...
    boxevents, recevents, 'recTime', rechdr.Fs );

if have_stim
    disp('-- Checking for missing stimulator events.');
    stimevents = euAlign_copyMissingEventTables( ...
        boxevents, stimevents, 'stimTime', stimhdr.Fs );
end

%% Add TTL pulses into code stream (same as big script)
disp('-- Copying TTL events into event code streams.');

if isfield(recevents, 'cookedcodes')
    if isfield(recevents, 'rwdA')
        recevents.cookedcodes = euFT_addTTLEventsAsCodes( ...
            recevents.cookedcodes, recevents.rwdA, ...
            'recTime', 'codeLabel', 'TTLRwdA' );
    end
    if isfield(recevents, 'rwdB')
        recevents.cookedcodes = euFT_addTTLEventsAsCodes( ...
            recevents.cookedcodes, recevents.rwdB, ...
            'recTime', 'codeLabel', 'TTLRwdB' );
    end
end

if have_stim && isfield(stimevents, 'cookedcodes')
    if isfield(stimevents, 'rwdA')
        stimevents.cookedcodes = euFT_addTTLEventsAsCodes( ...
            stimevents.cookedcodes, stimevents.rwdA, ...
            'stimTime', 'codeLabel', 'TTLRwdA' );
    end
    if isfield(stimevents, 'rwdB')
        stimevents.cookedcodes = euFT_addTTLEventsAsCodes( ...
            stimevents.cookedcodes, stimevents.rwdB, ...
            'stimTime', 'codeLabel', 'TTLRwdB' );
    end
end

%% Segment into trials (event codes)
disp('-- Segmenting data into trials (codes).');
[trialcodes_each, trialcodes_concat] = euUSE_segmentTrialsByCodes( ...
    recevents.cookedcodes, 'codeLabel', 'codeData', false );

if have_stim
    trialcodes_concat = euAlign_addTimesToTable(trialcodes_concat, ...
        'recTime', 'stimTime', times_recorder_stimulator );
end

%% Save frame + event outputs (skip if exist)
if need_frame
    save(outdatafile_FrameInformation, 'gameframedata');
end
if need_each
    save(outdatafile_EventInformation_Each, 'trialcodes_each');
end
if need_cat
    save(outdatafile_EventInformation_Concatenated, 'trialcodes_concat');
end

%% Define trials (rectrialdefs)
if need_trl
    [rectrialdefs, rectrialdeftable] = euFT_defineTrialsUsingCodes( ...
        trialcodes_concat, 'codeLabel', 'recTime', rechdr.Fs, ...
        padtime, padtime, 'TrlStart', 'TrlEnd', trial_align_evcode, ...
        trial_metadata_events, 'codeData' );

    TrialEndInsideRecording = rectrialdefs(:,2) < rechdr.nSamples;
    [~, BadTrials] = cgg_procIdentifyBadTrialNumbers(rectrialdefs);
    GoodTrials = ~BadTrials;

    TrialValid = TrialEndInsideRecording & GoodTrials;
    rectrialdefs = rectrialdefs(TrialValid,:);
    rectrialdeftable = rectrialdeftable(TrialValid,:);

    save(outdatafile_TrialInformation, 'rectrialdefs');
    save(outdatafile_TrialInformation_Table, 'rectrialdeftable');
else
    % load for time info generation if needed
    if need_time
        tmp = load(outdatafile_TrialInformation);
        rectrialdefs = tmp.rectrialdefs;
    end
end

%% Time_Information (MATCH old cgg_procTrialTimeCourses)
% Old pipeline writes:
%   Time_Information/<ActivityType>/<TrialFileBaseName>_Time.mat
% containing ONLY:
%   this_trial_time
%
% Where this_trial_time == FieldTripStruct.time{1}.
% We can reconstruct that from rectrialdefs:
%   begSamp = rectrialdefs(:,1)
%   endSamp = rectrialdefs(:,2)
%   offsetSamp = rectrialdefs(:,3)   % FieldTrip offset (samples)
%
% time = (offsetSamp : offsetSamp + (N-1)) / Fs

if need_time
    Activity_Type = 'Spike';  % match the old naming convention
    outdatadir_TimeInformation_Type = fullfile(outdatadir_TimeInformation, Activity_Type);
    if ~exist(outdatadir_TimeInformation_Type, 'dir')
        mkdir(outdatadir_TimeInformation_Type);
    end

    Fs = rechdr.Fs;
    nTrials = size(rectrialdefs,1);

    trialCounter = rectrialdefs(:,8);  % used in filenames elsewhere
    begSamp      = rectrialdefs(:,1);
    endSamp      = rectrialdefs(:,2);
    offsetSamp   = rectrialdefs(:,3);  % IMPORTANT: determines time axis start

    nSamp = double(endSamp - begSamp + 1);

    for tidx = 1:nTrials
        this_trial_index = trialCounter(tidx);
        thisN            = nSamp(tidx);
        thisOff          = double(offsetSamp(tidx));

        % Reconstruct FieldTrip time{1}:
        % starts at offset (often -padtime*Fs), increments by 1/Fs
        this_trial_time = (thisOff : thisOff + (thisN-1)) ./ Fs; %#ok<NASGU>

        out_timefile = fullfile(outdatadir_TimeInformation_Type, ...
            sprintf('%s_Trial_%d_Time.mat', Activity_Type, this_trial_index));

        if ~exist(out_timefile, 'file')
            save(out_timefile, 'this_trial_time');
        end
    end

end

fprintf('pgp_proc_EventFrameTrialPreparation: done for %s.\n', SessionName);

end
