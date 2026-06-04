[cfg] = DATA_cggAllSessionInformationConfiguration;
Epoch = 'Decision';   % or any existing Epoch

for s = 1:length(cfg)

    inputfolder = cfg(s).inputfolder;
    outdatadir     = cfg(s).outdatadir;
    session     = cfg(s).SessionName;
    monkey_name= cfg(s).Monkey_Name;
    ExperimentName = cfg(s).ExperimentName;

    % (1) Build trial definitions & frame/event tables
    pgp_proc_EventFrameTrialPreparation( ...
        'inputfolder',inputfolder,'outdatadir',outdatadir);

    % (2) Build behavioral / target variables
    pgp_procProcessingBehaviorOnly( ...
        'inputfolder',inputfolder,'outdatadir',outdatadir, ...
        'Epoch',Epoch,'ExperimentName',ExperimentName,'monkey_name',monkey_name);

    % (3) Build align-event recTime file using Epoch parameters
    pgp_buildAlignFromEpoch( ...
        'inputfolder',inputfolder,...
        'session',session, ...
        'outroot',outdatadir, ...
        'Epoch',Epoch,...
        'which','Data');

    pgp_buildAlignFromEpoch( ...
        'inputfolder',inputfolder,...
        'session', session, ...
        'outroot', outdatadir, ...
        'Epoch', Epoch, ...
        'which', 'Baseline');
end

% Set these directories to where you want them 
% json_out specifies where you want to save the JSON to
% sorted_root_base specifies the root for saved KS_4 outputs e.g.
% sorted/continuous_{session_name}/{session_name}_prb{num}/KS4_OUTPUT
% spikeFilePath specifies where the spike alignment function is
json_out = fullfile(outdatadir, 'ALL_SESSIONS_spike_pipeline.json');
sorted_root_base = '/data/womelsdorf_lab/kazezew/Old_Dataset_Related/FLToken_Sorted/sorted';

pgp_exportCfgToJson( ...
  json_out, ...
  'sorted_root_base', sorted_root_base, ...
  'Epoch', Epoch);

spikeFilePath = '/panfs/accrepfs.vampire/data/womelsdorf_lab/kazezew/Old_Dataset_Related/Thilo_Research_Work/Processing_Functions_cgg/Spike_Alignment/pgp_spikeTrialAlignment_v5_stability.py';

%% ----FixME - make the argument inputs programmatic not hard coded---
% ---- Python: run spike alignment on everything in JSON ----
% only --cfg_json path required, the rest are set by default but set here
% for clarity
% must have python loaded in environment to use
% system(sprintf(['python -u "%s" --cfg_json "%s" --out_subdir SpikeAligned ' ...
%                 '--Fs 30mak000 --bin_ms 1 --win_before 1.5 --win_after 1.5  --win_before_base 0.15 --win_after_base .4 --qualities 4,5'], ...
%                 spikeFilePath, json_out));



% in ACCRE, needed to unset matlab library stuff so ran this:
% make sure to first activate python with something like:   
% source ~/venvs/my_virtual_python_env/bin/activate e.g. 
% souce ~/venvs/spike_align_v3/bin/activate
% also, add to path Spike_Alignment folder

pybin = '/data/womelsdorf_lab/kazezew/Old_Dataset_Related/venvs/spike_align_v3/bin/python';
% 
cmd = sprintf([ ...
    'bash -c ''unset LD_LIBRARY_PATH; ' ...
    '"%s" -u "%s" --cfg_json "%s" --out_subdir SpikeAligned ' ...
    '--Fs 30000 --bin_ms 1 --win_before 1.5 --win_after 1.5 ' ...
    '--win_before_base 0.15 --win_after_base 0.4 --qualities 4,5''' ], ...
    pybin, spikeFilePath, json_out);


system(cmd);