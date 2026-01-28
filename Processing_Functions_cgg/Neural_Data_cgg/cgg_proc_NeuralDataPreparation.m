function [inputfolder, outdatadir] = cgg_proc_NeuralDataPreparation(varargin)

% function [output] = cgg_proc_NeuralDataPreparation(input)

% General Function Description
% 
% Function Description ...

% "input" Type of input. Description of input.

% "output" Type of output. Description of output.

isfunction=exist('varargin','var');

%% Directories

% This gets the input folder from varargin. Use the name value pair of
% 'inputfolder'. If nothing is selected it will prompt you to select a
% folder.
% Select a folder that has the highest session information e.g.
% 'Fr_Probe_02_22-05-09_009_01'
if isfunction
inputfolder = CheckVararginPairs('inputfolder', '', varargin{:});
if isempty(inputfolder)
    inputfolder = uigetdir(['/Volumes/','Womelsdorf Lab','/DATA_neural'], 'Choose the input data folder');
end
else
    inputfolder = uigetdir(['/Volumes/','Womelsdorf Lab','/DATA_neural'], 'Choose the input data folder');
end
% This gets the Session name and the Experiment name
% E.G. Session -> 'Fr_Probe_02_22-05-09_009_01'
% E.G. Experiment -> 'Frey_FLToken_Probe_02'
[inputfolder_dir,SessionName,~]=fileparts(inputfolder);
[~,ExperimentName,~]=fileparts(inputfolder_dir);


% This gets the ouput folder from varargin. Use the name value pair of
% 'outdatadir'. If nothing is selected it will prompt you to select a
% folder.
% Select a folder that is where you would like to write any data. It will
% make the various subfolders that correspond to the experiment and the
% session that you have chosen in the input folder
if isfunction
outdatadir = CheckVararginPairs('outdatadir', '', varargin{:});
if isempty(outdatadir)
    outdatadir = uigetdir(['/Volumes/gerritcg''','s home/Data_Neural_gerritcg'], 'Choose the output data folder');
end
else
    outdatadir = uigetdir(['/Volumes/gerritcg''','s home/Data_Neural_gerritcg'], 'Choose the output data folder');
end

%% Parameters

% This gets the parameter values from 
% PARAMETERS_cgg_proc_NeuralDataPreparation. Open this script and read the
% descriptions to change the set values for this function.


cfg=PARAMETERS_cgg_proc_NeuralDataPreparation('SessionName',SessionName);

trial_align_evcode = cfg.trial_align_evcode;
padtime = cfg.padtime;
notch_filter_freqs = cfg.notch_filter_freqs;
notch_filter_bandwidth = cfg.notch_filter_bandwidth;
lfp_maxfreq = cfg.lfp_maxfreq;
lfp_samprate = cfg.lfp_samprate;
spike_minfreq = cfg.spike_minfreq;
rect_bandfreqs =cfg.rect_bandfreqs;
rect_lowpassfreq = cfg.rect_lowpassfreq;
rect_samprate = cfg.rect_samprate;
gaze_samprate = cfg.gaze_samprate;
probe_mapping=cfg.probe_mapping;
probe_selection=cfg.probe_selection;
probe_area=cfg.probe_area;
want_channel_remap = cfg.want_channel_remap;
want_artifact_rejection = cfg.want_artifact_rejection;
want_rereference = cfg.want_rereference;
rereference_type = cfg.rereference_type;
clustering_trial_count = cfg.clustering_trial_count;
want_LFP = cfg.want_LFP;
want_MUA = cfg.want_MUA;
want_Spike = cfg.want_Spike;
keep_wideband = cfg.keep_wideband;

keep_raw = cfg.keep_raw;
keep_notch = cfg.keep_notch;

%%
% Make the Experiment and Session output folder names.
outdatadir_Experiment=[outdatadir, filesep, ExperimentName];
outdatadir_SessionName=[outdatadir_Experiment, filesep, SessionName];

% Make the Event Information, Frame Information, and Trial Information
% output folder names.
outdatadir_EventInformation=[outdatadir_SessionName, filesep, 'Event_Information'];
outdatadir_FrameInformation=[outdatadir_SessionName, filesep, 'Frame_Information'];
outdatadir_TrialInformation=[outdatadir_SessionName, filesep, 'Trial_Information'];

% % Make the Area Analysis output folder name.
% outdatadir_Area=[outdatadir_SessionName, filesep, probe_area];
% 
% % Make the Activity output folder names within this area.
% outdatadir_Activity=[outdatadir_Area, filesep, 'Activity'];
% 
% % Make the Processed Activity output folder names
% outdatadir_WideBand=[outdatadir_Activity, filesep, 'WideBand'];
% outdatadir_LFP=[outdatadir_Activity, filesep, 'LFP'];
% outdatadir_Spike=[outdatadir_Activity, filesep, 'Spike'];
% outdatadir_MUA=[outdatadir_Activity, filesep, 'MUA'];


% Check if the Experiment and Session output folders exist and if they do
% not, create them.
if ~exist(outdatadir_Experiment, 'dir')
    mkdir(outdatadir_Experiment);
end
if ~exist(outdatadir_SessionName, 'dir')
    mkdir(outdatadir_SessionName);
end

% Check if the Event Information, Frame Information, and Trial Information
% output folders exist and if they do not, create them.
if ~exist(outdatadir_EventInformation, 'dir')
    mkdir(outdatadir_EventInformation);
end
if ~exist(outdatadir_FrameInformation, 'dir')
    mkdir(outdatadir_FrameInformation);
end
if ~exist(outdatadir_TrialInformation, 'dir')
    mkdir(outdatadir_TrialInformation);
end

% % Check if the Area output folders exist and if they do not, create them.
% if ~exist(outdatadir_Area, 'dir')
%     mkdir(outdatadir_Area);
% end
% 
% % Check if the Activity output folders exist and if they do not, create them.
% if ~exist(outdatadir_Activity, 'dir')
%     mkdir(outdatadir_Activity);
% end
% 
% % Check if the Processed Activit output folders exist and if they do not,
% % create them.
% if ~exist(outdatadir_WideBand, 'dir')
%     mkdir(outdatadir_WideBand);
% end
% if ~exist(outdatadir_LFP, 'dir')
%     mkdir(outdatadir_LFP);
% end
% if ~exist(outdatadir_Spike, 'dir')
%     mkdir(outdatadir_Spike);
% end
% if ~exist(outdatadir_MUA, 'dir')
%     mkdir(outdatadir_MUA);
% end

%% Where to look for event codes and TTL signals in the ephys data.

% These structures describe which TTL bit-lines in the recorder and
% stimulator encode which event signals for this dataset.

% FIXME - We want reward and stim TTLs to be cabled to both machines.
recbitsignals_openephys = struct();
recbitsignals_intan = struct();
stimbitsignals = struct('rwdB', 'Din_002');

% These structures describe which TTL bit-lines or word data channels
% encode event codes for the recorder and stimulator.
% Note that Open Ephys word data starts with bit 0 and Intan bit lines
% start with bit 1. So Open Ephys code words are shifted by 8 bits and
% Intan code words are shifted by 9 bits to get the same data.

reccodesignals_openephys = struct( ...
  'signameraw', 'rawcodes', 'signamecooked', 'cookedcodes', ...
  'channame', 'DigWordsA_000', 'bitshift', 8 );

reccodesignals_intan = struct( ...
  'signameraw', 'rawcodes', 'signamecooked', 'cookedcodes', ...
  'channame', 'Din_*', 'bitshift', 9 );

% FIXME - This might not actually be cabled in some datasets.
stimcodesignals = struct( ...
  'signameraw', 'rawcodes', 'signamecooked', 'cookedcodes', ...
  'channame', 'Din_*', 'bitshift', 9 );


%% How to define trials.

% NOTE - We're setting trial_align_evcode earlier in the script now.

% These are codes that carry extra metadata that we want to save; they'll
% show up in "trialinfo" after processing (and in "trl" before that).
trial_metadata_events = ...
  struct( 'trialnum', 'TrialNumber', 'trialindex', 'TrialIndex' );

%% Start Field Trip.

% Wrapping this to suppress the annoying banner.
evalc('ft_defaults');

% Suppress spammy Field Trip notifications.
ft_notice('off');
ft_info('off');
ft_warning('off');

%% Other setup.

% Suppress Matlab warnings (the NPy library generates these).
oldwarnstate = warning('off');

% Limit the number of channels LoopUtil will load into memory at a time.
% 30 ksps double-precision data takes up about 1 GB per channel-hour.
nlFT_setMemChans(6);

%% Read metadata (paths, headers, and channel lists).

% Get paths to individual devices.

[ folders_openephys folders_intanrec folders_intanstim folders_unity ] = ...
  euUtil_getExperimentFolders(inputfolder);

% debugging code
% disp(inputfolder)
% disp('folders_openephys:'); disp(folders_openephys)
% disp('folders_intanrec:');  disp(folders_intanrec)
% FIXME - Assume one recorder dataset and 0 or 1 stimulator datasets.

% If the data is recorded in OpenEphys it will search and recognize that
% otherwise it will use the intan recording data
have_openephys = ~isempty(folders_openephys);
if have_openephys
    % Handle multiple record nodes - find the one with actual data
    % (Sometimes a session has empty record nodes from false starts)
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

% Check for stimulator data
have_stim = false;


if ~isempty(folders_intanstim)
  folder_stim = folders_intanstim{1};
  have_stim = true;
end

folder_game = folders_unity{1};

%% Get headers.

% NOTE - Field Trip will throw an exception if this fails.
% Add a try/catch block if you want to fail gracefully.
rechdr = ft_read_header( folder_record, 'headerformat', 'nlFT_readHeader' );
if have_stim
  stimhdr = ft_read_header( folder_stim, 'headerformat', 'nlFT_readHeader' );
end

%% 
% Read Open Ephys channel mapping, if we can find it.
% FIXME - Only doing this for the recorder!

% NOTE - We're searching the entire tree, not just the recorder folder,
% for the channel map. If a channel map file contains 'correct' in the file
% name it will select this file
[ chanmap_rec_mapped chanmap_rec_unmapped chanmap_rec_recorded ] = ...
  cgg_euUtil_getLabelChannelMap_OEv5(inputfolder, folder_record);
have_chanmap = ~isempty(chanmap_rec_mapped);

% Forcibly disable channel mapping if we don't want it.
if ~want_channel_remap
  have_chanmap = false;
end

%% Read events and Frame Data.
%!!!!!!!!!!FIXME- Save and check Event and Frame Data!!!!!!!!!!!!
% Use the default settings for this.

outdatafile_GazeInformation=...
   sprintf([outdatadir_FrameInformation filesep ...
   'Gaze_Data_%s.mat'],SessionName);

outdatafile_FrameInformation=...
   sprintf([outdatadir_FrameInformation filesep ...
   'Frame_Data_%s.mat'],SessionName);

outdatafile_EventInformation_Each=...
   sprintf([outdatadir_EventInformation filesep ...
   'Event_Codes_Each_%s.mat'],SessionName);

outdatafile_EventInformation_Concatenated=...
   sprintf([outdatadir_EventInformation filesep ...
   'Event_Codes_Concatenated_%s.mat'],SessionName);

outdatafile_TrialInformation=...
   sprintf([outdatadir_TrialInformation filesep ...
   'Trial_Definition_%s.mat'],SessionName);

outdatafile_TrialInformation_Table=...
   sprintf([outdatadir_TrialInformation filesep ...
   'Trial_Definition_Table_%s.mat'],SessionName);

if ~(exist(outdatafile_GazeInformation,'file'))||...
        ~(exist(outdatafile_FrameInformation,'file'))||...
        ~(exist(outdatafile_EventInformation_Each,'file'))||...
        ~(exist(outdatafile_EventInformation_Concatenated,'file'))

% Read USE and SynchBox events. This also fetches the code definitions.
% This returns each device's event tables as structure fields.
% This also gives its own banner, so we don't need to print one.
[ boxevents gameevents evcodedefs ] = euUSE_readAllUSEEvents(folder_game);

% Now that we have the code definitions, read events and codes from the
% recorder and stimulator.

% These each return a table of TTL events, and a structure with tables for
% each extracted signal we asked for.

disp('-- Reading digital events from recorder.');

recbitsignals = recbitsignals_openephys;
reccodesignals = reccodesignals_openephys;
if ~have_openephys
  recbitsignals = recbitsignals_intan;
  reccodesignals = reccodesignals_intan;
end

[ recevents_ttl recevents ] = euUSE_readAllEphysEvents( ...
  folder_record, recbitsignals, reccodesignals, evcodedefs );

if have_stim
  disp('-- Reading digital events from stimulator.');
  [ stimevents_ttl stimevents ] = euUSE_readAllEphysEvents( ...
    folder_stim, stimbitsignals, stimcodesignals, evcodedefs );
end


% Report what we found from each device.

helper_reportEvents('.. From SynchBox:', boxevents);
helper_reportEvents('.. From USE:', gameevents);
helper_reportEvents('.. From recorder:', recevents);
if have_stim
helper_reportEvents('.. From stimulator:', stimevents);
end

%% Clean up timestamps.

% Subtract the enormous offset from the Unity timestamps.
% Unity timestamps start at 1 Jan 1970 by default.

[ unityreftime gameevents ] = ...
  euUSE_removeLargeTimeOffset( gameevents, 'unityTime' );
% We have a reference time now; pass it as an argument to ensure consistency.
[ unityreftime boxevents ] = ...
  euUSE_removeLargeTimeOffset( boxevents, 'unityTime', unityreftime );


% Add a "timestamp in seconds" column to the ephys signal tables.

recevents = ...
  euFT_addEventTimestamps( recevents, rechdr.Fs, 'sample', 'recTime' );
if have_stim
stimevents = ...
  euFT_addEventTimestamps( stimevents, stimhdr.Fs, 'sample', 'stimTime' );
end

%% Do time alignment.

% Default alignment config is fine.
alignconfig = struct();
alignconfig.coarsewindows=1000;
% Just align using event codes. Falling back to reward pulses takes too long.


disp('.. Propagating recorder timestamps to SynchBox.');

% Use raw code bytes for this, to avoid glitching from missing box codes.
% boxevents.cookedcodes = removevars(boxevents.cookedcodes, 'recTime');
% boxevents.rawcodes = removevars(boxevents.rawcodes, 'recTime');
% boxevents.rwdB = removevars(boxevents.rwdB, 'recTime');
% boxevents.rwdA = removevars(boxevents.rwdA, 'recTime');
% boxevents.rwdA = removevars(boxevents.synchB, 'recTime');
eventtables = { recevents.rawcodes, boxevents.rawcodes };
% eventtables = { recevents.cookedcodes(recevents.cookedcodes.codeLabel=="TrialIndex",:), boxevents.cookedcodes(boxevents.cookedcodes.codeLabel=="TrialIndex",:) };
[ newtables times_recorder_synchbox ] = euUSE_alignTwoDevices( ...
  eventtables, 'recTime', 'synchBoxTime', alignconfig );

boxevents = euAlign_addTimesToAllTables( ...
  boxevents, 'synchBoxTime', 'recTime', times_recorder_synchbox );


disp('.. Propagating recorder timestamps to USE.');

% Use cooked codes for this, since both sides have a complete event list.
% gameevents.cookedcodes = removevars(gameevents.cookedcodes, 'recTime');
% gameevents.rawcodes = removevars(gameevents.rawcodes, 'recTime');
% gameevents.rwdB = removevars(gameevents.rwdB, 'recTime');
% gameevents.rwdA = removevars(gameevents.rwdA, 'recTime');
eventtables = { recevents.cookedcodes, gameevents.cookedcodes };
% eventtables = { recevents.cookedcodes(recevents.cookedcodes.codeLabel=="TrialIndex",:), gameevents.cookedcodes(gameevents.cookedcodes.codeLabel=="TrialIndex",:) };
[ newtables times_recorder_game ] = euUSE_alignTwoDevices( ...
  eventtables, 'recTime', 'unityTime', alignconfig );

gameevents = euAlign_addTimesToAllTables( ...
  gameevents, 'unityTime', 'recTime', times_recorder_game );


if have_stim
  disp('.. Propagating recorder timestamps to stimulator.');

  % The old test script aligned using SynchBox TTL signals as a fallback.
  % Since we're only using codes here, we don't have a fallback option. Use
  % event codes or fail.

  eventtables = { recevents.cookedcodes, stimevents.cookedcodes };
  [ newtables times_recorder_stimulator ] = euUSE_alignTwoDevices( ...
    eventtables, 'recTime', 'stimTime', alignconfig );

  stimevents = euAlign_addTimesToAllTables( ...
    stimevents, 'stimTime', 'recTime', times_recorder_stimulator );


  % Propagate stimulator timestamps to the SynchBox, in case we need to
  % use the SynchBox's event records with the stimulator.

  disp('.. Propagating stimulator timestamps to SynchBox.');

  boxevents = euAlign_addTimesToAllTables( ...
    boxevents, 'recTime', 'stimTime', times_recorder_stimulator );
end

%% Gaze and Frame Data


% Read USE gaze and framedata tables.
% These return concatenated table data from the relevant USE folders.
% These take a while, so stub them out for testing.
gamegazedata = table();
gameframedata = table();
disp('-- Reading USE gaze data.');
gamegazedata = euUSE_readRawGazeData(folder_game);
disp('-- Reading USE frame data.');
gameframedata = euUSE_readRawFrameData(folder_game);
disp('-- Finished reading USE gaze and frame data.');

% First, make "eyeTime" and "unityTime" columns.
% Remember to subtract the offset from Unity timestamps.

gameframedata.eyeTime = gameframedata.EyetrackerTimeSeconds;
gameframedata.unityTime = ...
gameframedata.SystemTimeSeconds - unityreftime;

gamegazedata.eyeTime = gamegazedata.time_seconds;


% Get alignment information for Unity and eye-tracker timestamps.
% This information is already in gameframedata; we just have to extract
% it.

% Timestamps are not guaranteed to be unique, so filter them.
times_game_eyetracker = euAlign_getUniqueTimestampTuples( ...
gameframedata, {'unityTime', 'eyeTime'} );


% Unity timestamps are unique but ET timestamps aren't.
% Interpolate new ET timestamps from the Unity timestamps.

disp('.. Cleaning up eye tracker timestamps in frame data.');

gameframedata = euAlign_addTimesToTable( gameframedata, ...
'unityTime', 'eyeTime', times_game_eyetracker );


% Add recorder timestamps to game and frame data tables.
% To do this, we'll also have to augment gaze data with unity timestamps.

disp('.. Propagating recorder timestamps to frame data table.');

gameframedata = euAlign_addTimesToTable( gameframedata, ...
'unityTime', 'recTime', times_recorder_game );

disp('.. Propagating Unity and recorder timestamps to gaze data table.');

gamegazedata = euAlign_addTimesToTable( gamegazedata, ...
'eyeTime', 'unityTime', times_game_eyetracker );
gamegazedata = euAlign_addTimesToTable( gamegazedata, ...
'unityTime', 'recTime', times_recorder_game );


disp('.. Finished time alignment.');


% Save gaze and frame data



%% Clean up the event tables.

% Propagate any missing events to the recorder and stimulator.

% We have SynchBox events with accurate timestamps, and we've aligned
% the synchbox to the ephys machines with high precision.

% NOTE - This only works if we do have accurate time alignment. If we fell
% back to guessing in the previous step, the events will be at the wrong
% times.

% Copy missing events from the SynchBox to the recorder.
disp('-- Checking for missing recorder events.');
recevents = euAlign_copyMissingEventTables( ...
  boxevents, recevents, 'recTime', rechdr.Fs );

% Copy missing events from the SynchBox to the stimulator.
if have_stim
  disp('-- Checking for missing stimulator events.');
  stimevents = euAlign_copyMissingEventTables( ...
    boxevents, stimevents, 'stimTime', stimhdr.Fs );
end


% Copy TTL events into the event code tables, if present.

disp('-- Copying TTL events into event code streams.');

% NOTE - Not copying into "gameevents" for now.

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

if have_stim
  if isfield(stimevents, 'cookedcodes')

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
end

%% Get trial definitions. (NEED TO KEEP)

disp('-- Segmenting data into trials.');

% NOTE - We have to use the recorder code list for this.
% Using the Unity code list gets about 1 ms of jitter.

[ trialcodes_each trialcodes_concat ] = euUSE_segmentTrialsByCodes( ...
  recevents.cookedcodes, 'codeLabel', 'codeData', false );

if have_stim
  trialcodes_concat = euAlign_addTimesToTable( trialcodes_concat, ...
    'recTime', 'stimTime', times_recorder_stimulator );
end

save(outdatafile_FrameInformation,'gameframedata');

save(outdatafile_GazeInformation,'gamegazedata');

save(outdatafile_EventInformation_Each,'trialcodes_each');

save(outdatafile_EventInformation_Concatenated,'trialcodes_concat');

end

% END OF EVENT ALIGNMENT SECTION

%% Get trial definitions.
% This replaces ft_definetrial().

if ~(exist('trialcodes_concat','var'))
load(outdatafile_EventInformation_Concatenated);
end

[ rectrialdefs rectrialdeftable ] = euFT_defineTrialsUsingCodes( ...
  trialcodes_concat, 'codeLabel', 'recTime', rechdr.Fs, ...
  padtime, padtime, 'TrlStart', 'TrlEnd', trial_align_evcode, ...
  trial_metadata_events, 'codeData' );

TrialStartInsideRecording=rectrialdefs(:,1)<rechdr.nSamples;
TrialEndInsideRecording=rectrialdefs(:,2)<rechdr.nSamples;
if any(xor(TrialStartInsideRecording,TrialEndInsideRecording))
    disp('!! Trial starts within recording but ends outside of recording');
end

% WeirdnessAmount=100;
% 
% TrialWeirdnessMeasure=abs(rectrialdefs(:,8)-rectrialdefs(:,7));
% TrialWeird=TrialWeirdnessMeasure>WeirdnessAmount | ...
%     isnan(TrialWeirdnessMeasure);
% 
% TrialNormal=~TrialWeird;
% 
% if any(TrialWeird)
%     disp('!! Trial numbers and indices have a large difference');
% end

[~,BadTrials] = cgg_procIdentifyBadTrialNumbers(rectrialdefs);

GoodTrials=~BadTrials;

% TrialValid=TrialEndInsideRecording & TrialNormal & GoodTrials;
TrialValid=TrialEndInsideRecording & GoodTrials;

rectrialdefs=rectrialdefs(TrialValid,:);
rectrialdeftable=rectrialdeftable(TrialValid,:);

trialcount = height(rectrialdeftable);

if have_stim
  % FIXME - We're assuming that we'll get the same set of trials for the
  % recorder and stimulator. That's only the case if the event code
  % sequences received by each are the same and start at the same time!

  [ stimtrialdefs stimtrialdeftable ] = euFT_defineTrialsUsingCodes( ...
    trialcodes_concat, 'codeLabel', 'stimTime', stimhdr.Fs, ...
    padtime, padtime, 'TrlStart', 'TrlEnd', trial_align_evcode, ...
    trial_metadata_events, 'codeData' );
else
    stimtrialdefs=zeros(trialcount,1);
    stimtrialdeftable=zeros(trialcount,1);
end

save(outdatafile_TrialInformation,'rectrialdefs');

save(outdatafile_TrialInformation_Table,'rectrialdeftable');

% FIXME FIXME FIXME THIS IS THE START OF ITERATING THROUGH TRIALS

%% Begin Iterating Through Trials

% Variables needed: rectrialdeftable, rectrialdefs, stimtrialdeftable,
% stimtrialdefs, have_stim, folder_record, chanmap_rec_cooked, rechdr,
% have_chanmap, chanmap_rec_raw, notch_filter_freqs, notch_filter_bandwidth

% Variables accesible: rectrialdeftable, rectrialdefs, stimtrialdeftable,
% stimtrialdefs, have_stim, folder_record, chanmap_rec_cooked, rechdr
% have_chanmap, chanmap_rec_raw, notch_filter_freqs, notch_filter_bandwidth

% Wrapping this to suppress the annoying banner.
% parfeval(@ft_defaults,0,0);

% parfevalOnAll(@ft_defaults,0,0);
% parfevalOnAll(@ft_notice,0,'off');
% parfevalOnAll(@ft_info,0,'off');
% parfevalOnAll(@ft_warning,0,'off');

% parfeval(@ft_defaults,0,0);
% parfeval(@ft_notice,0,'off');
% parfeval(@ft_info,0,'off');
% parfeval(@ft_warning,0,'off');      

for aidx=1:length(probe_area)
    
    this_probe_area=probe_area{aidx};
    this_probe_selection=probe_selection{aidx};
    
[outdatadir_WideBand,outdatadir_LFP,outdatadir_Spike,...
    outdatadir_MUA,outdatadir_Raw,outdatadir_Notch] = ...
    cgg_generateNeuralDataFolders(outdatadir,SessionName, ...
    ExperimentName,this_probe_area,'keep_raw',keep_raw, ...
    'keep_notch',keep_notch);

parfor tidx=1:trialcount
%    disp(have_stim)

    % Use trial index (event codes) to label the trials. This corresponds
    % to the TrialCounter in the frame data. This should prevent any
    % confusion over the definitions of bad trials because all trials have
    % a unique trial index regardless of status.
    
   this_trial_index=rectrialdefs(tidx,8);
   this_trial_wideband_file_name=...
       sprintf([outdatadir_WideBand filesep 'WideBand_Trial_%d.mat'],...
       this_trial_index);
   this_trial_LFP_file_name=...
       sprintf([outdatadir_LFP filesep 'LFP_Trial_%d.mat'],...
       this_trial_index);
   this_trial_MUA_file_name=...
       sprintf([outdatadir_MUA filesep 'MUA_Trial_%d.mat'],...
       this_trial_index);
   this_trial_Spike_file_name=...
       sprintf([outdatadir_Spike filesep 'Spike_Trial_%d.mat'],...
       this_trial_index);
   this_trial_Raw_file_name=...
       sprintf([outdatadir_Raw filesep 'Raw_Trial_%d.mat'],...
       this_trial_index);
   
   have_desired_data=...
       ~(((~(exist(this_trial_LFP_file_name,'file'))) && want_LFP)||...
            ((~(exist(this_trial_MUA_file_name,'file'))) && want_MUA)||...
            ((~(exist(this_trial_Spike_file_name,'file'))) && want_Spike));
    
    if ~(exist(this_trial_wideband_file_name,'file')) && ~have_desired_data
    
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
nlFT_setMemChans(6);  

this_rectrialdeftable = rectrialdeftable(tidx,:);
this_rectrialdefs = rectrialdefs(tidx,:);

% Initialize stim variables to avoid parfor warning about uninitialized temporaries
this_stimtrialdeftable = [];
this_stimtrialdefs = [];

if have_stim
    try
        this_stimtrialdeftable = stimtrialdeftable(tidx,:);
        this_stimtrialdefs = stimtrialdefs(tidx,:);
    catch ME
        warning('Failed to get stim trial defs for trial %d: %s', tidx, ME.message);
    end
end

% Sanity check.
if isempty(this_rectrialdefs)
    error('No valid recorder trial epochs defined!');
end

if have_stim && isempty(this_stimtrialdefs)
    error('No valid stimulator trial epochs defined!');
end

preproc_config_rec = struct( ...
  'headerfile', folder_record, 'datafile', folder_record, ...
  'headerformat', 'nlFT_readHeader', 'dataformat', 'nlFT_readDataDouble', ...
  'trl', this_rectrialdefs, 'detrend', 'yes', 'feedback', 'text' );

switch probe_mapping
    case 'recorded'
        this_channel_map = chanmap_rec_recorded;
    case 'unmapped'
        this_channel_map = chanmap_rec_unmapped;
    case 'mapped'
        this_channel_map = chanmap_rec_mapped;
    otherwise
        this_channel_map = chanmap_rec_mapped;
end

if have_chanmap
	preproc_config_rec.channel = ...
  	ft_channelselection( this_channel_map(this_probe_selection), rechdr.label, {} );
else
	preproc_config_rec.channel = ...
  	ft_channelselection(this_probe_selection, rechdr.label, {} );
end
% preproc_config_rec.channel = ...
%   ft_channelselection( this_channel_map(this_probe_selection), rechdr.label, {} );

disp('.. Reading wideband recorder data.');
this_recdata_wideband = ft_preprocessing( preproc_config_rec );

if have_chanmap
  newlabels = nlFT_mapChannelLabels( this_recdata_wideband.label, ...
    chanmap_rec_mapped, chanmap_rec_unmapped );

  badmask = strcmp(newlabels, '');
  if sum(badmask) > 0
    disp('###  Couldn''t map all recorder labels!');
    newlabels(badmask) = {'bogus'};
  end

  % Figure out new order for channels after remapping saved order 
  [newlabels_in_order,newlabels_order]=sort(newlabels);
  % There are at least three places where the labels are stored.
  % Update all copies.
%   this_recdata_wideband.oldlabel=newlabels;
  this_recdata_wideband.label = this_recdata_wideband.label(newlabels_order);
  this_recdata_wideband.label_in_order = newlabels_in_order;
  this_recdata_wideband.old_label = preproc_config_rec.channel;
%   this_recdata_wideband.hdr.label = newlabels_in_order;
%   rechdr.label = newlabels_in_order;
  
  
  this_trial_count=length(this_recdata_wideband.trial);
  
  for ttidx=1:this_trial_count
      
      this_recdata_wideband.trial{ttidx}=...
          this_recdata_wideband.trial{ttidx}(newlabels_order,:);
      
  end
end



% save(this_trial_wideband_file_name,'this_recdata_wideband');

m = matfile(this_trial_wideband_file_name,'Writable',true);
m.this_recdata_wideband=this_recdata_wideband;

if keep_raw
m_raw = matfile(this_trial_Raw_file_name,'Writable',true);
m_raw.this_recdata_wideband=this_recdata_wideband;
end

    end

end

%% Connected Channels
% Here the information for what channels are connected is obtained.

[cfg_directories] = cgg_generateNeuralDataFolders_v2(this_probe_area,...
    'inputfolder',inputfolder,'outdatadir',outdatadir);

this_area_clustering_file_name=...
    [cfg_directories.outdatadir.Experiment.Session.Activity.Area.Connected.path ...
    filesep 'Clustering_Results.mat'];

% NOTE - You'd normally do re-referencing here.
is_any_previously_rereferenced=false;
if ~(exist(this_area_clustering_file_name,'file')) 
    disp('.. Performing Clustering to Identify Connected Channels');
% [Connected_Channels,Disconnected_Channels,is_any_previously_rereferenced] = cgg_getDisconnectedChannels(trialcount,...
%     clustering_trial_count,[outdatadir_WideBand filesep ...
%     'WideBand_Trial_%d.mat']);
[Connected_Channels,Disconnected_Channels,...
    is_any_previously_rereferenced,Debugging_Info] = ...
    cgg_getDisconnectedChannelsFromDirectories_v2(clustering_trial_count,...
    'inputfolder',inputfolder,'outdatadir',outdatadir,...
    'Activity_Type', 'WideBand','probe_area',this_probe_area);

m_Cluster = matfile(this_area_clustering_file_name,'Writable',true);
m_Cluster.Connected_Channels=Connected_Channels;
m_Cluster.Disconnected_Channels=Disconnected_Channels;
m_Cluster.is_any_previously_rereferenced=is_any_previously_rereferenced;
m_Cluster.Debugging_Info=Debugging_Info;
end

m_Cluster = matfile(this_area_clustering_file_name,'Writable',true);
    Connected_Channels=m_Cluster.Connected_Channels;
    Disconnected_Channels=m_Cluster.Disconnected_Channels;
    is_any_previously_rereferenced=m_Cluster.is_any_previously_rereferenced;

Message_Rereferencing=sprintf('--- Disconnected Channels for Area: %s are:',this_probe_area);
for didx=1:length(Disconnected_Channels)
    if didx<length(Disconnected_Channels)
    Message_Rereferencing=sprintf([Message_Rereferencing ' %d,'],Disconnected_Channels(didx));
    else
    Message_Rereferencing=sprintf([Message_Rereferencing ' %d'],Disconnected_Channels(didx));
    end
end

disp(Message_Rereferencing);
%%
% ----------------Tring to fix artifacts across multiple channels at once problem by
% removing bad channels with z scoring-------------------------
%%
% --- Build list of saved wideband trial files (produced by the first parfor)
wbDir = outdatadir_WideBand;  % same var you used when saving
wbFiles = dir(fullfile(wbDir, 'WideBand_Trial_*.mat'));
assert(~isempty(wbFiles), 'No WideBand_Trial_*.mat files found in %s', wbDir);

% --- Pick ~10 trials deterministically or randomly
nTot = numel(wbFiles);
nSampleTrials = min(10, nTot);
rng(0);   % optional reproducibility
pick = randperm(nTot, nSampleTrials);   % or pick = 1:nSampleTrials;

% --- Load the first picked trial to get labels & Connected_Channels mapping
S0 = load(fullfile(wbDir, wbFiles(pick(1)).name), 'this_recdata_wideband');
labels = S0.this_recdata_wideband.label;

% IMPORTANT: translate Connected_Channels (indices) -> labels AFTER remap
refLabels0 = labels(Connected_Channels);
refIdx = match_str(labels, refLabels0);

% --- Concatenate candidate reference data across the chosen trials
Xcat = [];   % [nRef x total_time_across_10_trials]
for ii = 1:numel(pick)
    Si = load(fullfile(wbDir, wbFiles(pick(ii)).name), 'this_recdata_wideband');
    Xi = Si.this_recdata_wideband.trial{1}(refIdx,:);   % each file has 1 trial
    % Optional: Xi = Xi(:,1:2:end);  % light decimation to save RAM
    Xcat = [Xcat, Xi]; %#ok<AGROW>
end

% --- Robust per-channel stats across all sampled data
medc = median(Xcat, 2);
madc = mad(Xcat, 1, 2);
rZ   = (Xcat - medc) ./ max(madc, eps);

fracHi = mean(abs(rZ) > 7, 2);      % threshold 7 robust SDs
keep   = isfinite(medc) & isfinite(madc) & fracHi < 0.01;

% --- Final, stable ref list (labels)
refLabelsGood = labels(refIdx(keep));

% (Optional but wise) require a minimum ref size
if numel(refLabelsGood) < max(3, ceil(0.2*numel(refLabels0)))
    warning('Few stable ref channels survived (%d/%d). Consider local CAR or looser thresholds.', ...
            numel(refLabelsGood), numel(refLabels0));
end

% 1) Find which of the originally Connected didn't survive z-screening
origConnLabels = labels(Connected_Channels);
badZLabels     = setdiff(origConnLabels, refLabelsGood, 'stable');  % Connected \ Good

% 2) Map those labels back to indices in the current label order
badZIdx = match_str(labels, badZLabels);   % row indices into data/trial matrices

% 3) Update the Connected/Disconnected lists
Disconnected_Channels = unique([Disconnected_Channels(:); badZIdx(:)]);  % add; uniq
Connected_Channels    = setdiff(Connected_Channels(:), badZIdx(:), 'stable');

% 4) Persist the updated lists so later stages see the change
m_Cluster = matfile(this_area_clustering_file_name, 'Writable', true);
m_Cluster.Connected_Channels    = Connected_Channels;
m_Cluster.Disconnected_Channels = Disconnected_Channels;

% 5) (Optional) print a short report
fprintf('Z-screen removed %d ref channels; Connected now %d; Disconnected now %d.\n', ...
        numel(badZIdx), numel(Connected_Channels), numel(Disconnected_Channels));

% Recompute "good" ref set but restricted to current Connected (safety)
procLabels = labels(Connected_Channels);                         % channels we'll keep/process
goodRef    = intersect(refLabelsGood, procLabels, 'stable');     % ref = Good ∩ Connected

% --- Build cfg for reref using labels (not indices)
if want_rereference
cfg_rereference = [];
cfg_rereference.reref      = 'yes';
cfg_rereference.refmethod  = rereference_type;    % e.g., 'median'
% cfg_rereference.channel    = procLabels;          % ONLY Connected are processed
cfg_rereference.refchannel = goodRef;             % reference built from Good∩Connected
end
% if want_rereference
% cfg_rereference=[];
% cfg_rereference.reref='yes';
% % cfg_rereference.refchannel=Connected_Channels; %All Good Channels
% cfg_rereference.refchannel=refLabelsGood;
% cfg_rereference.refmethod=rereference_type;
% end

%% Iterate through trials for LFP, MUA, and Spike Data

% Variables needed: lfp_maxfreq, lfp_samprate, spike_minfreq,
% rect_bandfreqs, rect_lowpassfreq, rect_samprate

% Variables accesible: lfp_maxfreq, lfp_samprate, spike_minfreq,
% rect_bandfreqs, rect_lowpassfreq, rect_samprate
%%
parfor tidx=1:trialcount

   this_trial_index=rectrialdefs(tidx,8);
   this_trial_LFP_file_name=...
       sprintf([outdatadir_LFP filesep 'LFP_Trial_%d.mat'],...
       this_trial_index);
   this_trial_MUA_file_name=...
       sprintf([outdatadir_MUA filesep 'MUA_Trial_%d.mat'],...
       this_trial_index);
   this_trial_Spike_file_name=...
       sprintf([outdatadir_Spike filesep 'Spike_Trial_%d.mat'],...
       this_trial_index);
   this_trial_wideband_file_name=...
       sprintf([outdatadir_WideBand filesep 'WideBand_Trial_%d.mat'],...
       this_trial_index);
   this_trial_Notch_file_name=...
       sprintf([outdatadir_Notch filesep 'Notch_Trial_%d.mat'],...
       this_trial_index);
   
    
    if ((~(exist(this_trial_LFP_file_name,'file'))) && want_LFP)||...
            ((~(exist(this_trial_MUA_file_name,'file'))) && want_MUA)||...
            ((~(exist(this_trial_Spike_file_name,'file'))) && want_Spike)
        
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
        
    m_wideband = matfile(this_trial_wideband_file_name,'Writable',true);
    this_recdata_wideband=m_wideband.this_recdata_wideband;



    % Second step: Do notch filtering using our own filter, as FT's brick wall
    % filter acts up as of 2021.

    disp('.. Performing notch filtering (recorder).');
    this_recdata_wideband = euFT_doBrickNotchRemoval( ...
      this_recdata_wideband, notch_filter_freqs, notch_filter_bandwidth );

    if keep_notch
    m_notch = matfile(this_trial_Notch_file_name,'Writable',true);
    m_notch.this_recdata_wideband=this_recdata_wideband;
    end
        
    is_previously_rereferenced=cgg_checkFTRereference(this_recdata_wideband);
    
    if want_rereference && ~is_any_previously_rereferenced &&~is_previously_rereferenced
        disp('.. Rereferencing Wideband data.');
    this_recdata_wideband = ft_preprocessing(cfg_rereference, this_recdata_wideband);        
    end
    
    % Third step: Get derived signals (LFP, spike, and rectified activity).
    
    disp('.. Getting LFP, spike, and rectified activity signals.');
    
    [ this_recdata_lfp, this_recdata_spike, this_recdata_activity ] = ...
        euFT_getDerivedSignals( this_recdata_wideband, lfp_maxfreq, ...
        lfp_samprate, spike_minfreq, rect_bandfreqs, rect_lowpassfreq, ...
        rect_samprate, false);
        
%         save(this_trial_LFP_file_name,'this_recdata_lfp');
%         save(this_trial_Spike_file_name,'this_recdata_spike');
%         save(this_trial_MUA_file_name,'this_recdata_activity');
        if want_LFP
        m_LFP = matfile(this_trial_LFP_file_name,'Writable',true);
        m_LFP.this_recdata_lfp=this_recdata_lfp;
        end
        if want_Spike
        m_Spike = matfile(this_trial_Spike_file_name,'Writable',true);
        m_Spike.this_recdata_spike=this_recdata_spike;
        end
        if want_MUA
        m_MUA = matfile(this_trial_MUA_file_name,'Writable',true);
        m_MUA.this_recdata_activity=this_recdata_activity;
        end
         
        if want_rereference && ~is_any_previously_rereferenced && ~is_previously_rereferenced
        m_WB = matfile(this_trial_wideband_file_name,'Writable',true);
        m_WB.this_recdata_wideband=this_recdata_wideband;
        end

    end

end
%%
if ~keep_wideband
    rmdir(outdatadir_WideBand, 's');
end
end

%% Time Courses
% Get Time courses for each trial and each activity type. This is used in
% processing steps that look for time information, but do not need the
% entire trial data.

cgg_procTrialTimeCourses('inputfolder',inputfolder,...
    'outdatadir',outdatadir);

%%

% Save Session Preprocessing Parameters
ParameterDir=cfg_directories.outdatadir.Experiment.Session.Parameters.path;
ParameterPreProcessing_SaveName='Parameters_Preprocessing.yaml';

ParameterPreProcessing_SaveNameFull=[ParameterDir filesep ParameterPreProcessing_SaveName];
WriteYaml(ParameterPreProcessing_SaveNameFull, cfg);

%%

% Done.

%% Helper functions.


% This writes event counts from a specific device to the console.
% Input is a structure containing zero or more tables of events.

function helper_reportEvents(prefix, eventstruct)
  msgtext = prefix;

  evsigs = fieldnames(eventstruct);
  for evidx = 1:length(evsigs)
    thislabel = evsigs{evidx};
    thisdata = eventstruct.(thislabel);
    msgtext = [ msgtext sprintf('  %d %s', height(thisdata), thislabel) ];
  end

  disp(msgtext);
end

end

%
% This is the end of the file.