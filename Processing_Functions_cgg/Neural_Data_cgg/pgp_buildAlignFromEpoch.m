function pgp_buildAlignFromEpoch(varargin)
% pgp_buildAlignFromEpoch
%
% Wrapper that uses PARAMETERS_cgg_procFullTrialPreparation_v2(Epoch) to:
%   (A) ensure recTime_offset_<session>.mat exists (c, Fs, sample_col)
%   (B) generate an align-event .mat file (one recTime per trial) for Python spike alignment.
%
% Inputs (Name-Value):
%   'inputfolder' : path to session input folder (used to infer Experiment/Session names)
%   'outroot'     : base processed_data root (e.g., .../processed_data/Data_Neural)
%   'session'     : session string (optional; inferred from inputfolder if empty)
%   'Epoch'       : e.g. 'Decision', 'Epoch_1', ...
%   'which'       : 'Data' (default) or 'Baseline'
%
% Output:
%   Saves AlignEvent_*.mat under <root>/Frame_Information/
%   Saves recTime_offset_<session>.mat under <root>/Event_Information/ if missing.

% --- parse ---
inputfolder = CheckVararginPairs('inputfolder','',varargin{:});
outroot     = CheckVararginPairs('outroot','',varargin{:});
session     = CheckVararginPairs('session','',varargin{:});
Epoch       = CheckVararginPairs('Epoch','Decision',varargin{:});
which       = CheckVararginPairs('which','Data',varargin{:});  % 'Data' or 'Baseline'

assert(~isempty(inputfolder), 'pgp_buildAlignFromEpoch: inputfolder is required');
assert(~isempty(outroot),     'pgp_buildAlignFromEpoch: outroot is required');

% --- build full session output path ---
[inputfolder_dir, SessionName, ~] = fileparts(inputfolder);
[~, ExperimentName, ~] = fileparts(inputfolder_dir);

root = fullfile(outroot, ExperimentName, SessionName);

% infer session name if not provided
if isempty(session)
    session = SessionName;
end

% --- parameters (to get Fs and event/loc) ---
cfg_param = PARAMETERS_cgg_procFullTrialPreparation_v2(Epoch);
Fs = 30000;

switch lower(string(which))
    case "data"
        ev  = cfg_param.Frame_Event_Selection_Data;
        loc = cfg_param.Frame_Event_Selection_Location_Data;
    case "baseline"
        ev  = cfg_param.Frame_Event_Selection_Baseline;
        loc = cfg_param.Frame_Event_Selection_Location_Baseline;
    otherwise
        error("pgp_buildAlignFromEpoch: 'which' must be 'Data' or 'Baseline'");
end

% allow cell arrays (older epochs); choose last element by default
if iscell(ev);  ev  = ev{end};  end
if iscell(loc); loc = loc{end}; end
ev  = char(string(ev));
loc = char(string(loc));

% -------------------------------------------------------------------------
% (A) Ensure recTime_offset_<session>.mat exists
% -------------------------------------------------------------------------
eventDir   = fullfile(root, 'Event_Information');
offsetPath = fullfile(eventDir, sprintf('recTime_offset_%s.mat', session));

if ~exist(offsetPath, 'file')
    fprintf('[info] recTime_offset missing; building: %s\n', offsetPath);

    eventCatPath = fullfile(eventDir, sprintf('Event_Codes_Concatenated_%s.mat', session));
    assert(exist(eventCatPath,'file')==2, 'Missing event codes file: %s', eventCatPath);

    S = load(eventCatPath);
    assert(isfield(S,'trialcodes_concat'), 'trialcodes_concat not found in %s', eventCatPath);
    T = S.trialcodes_concat;
    assert(istable(T), 'trialcodes_concat in %s is not a table', eventCatPath);

    % ----- SIMPLE + EXPLICIT: col 1 = sample (abs samples), col 8 = recTime (sec)
    samp    = double(T{:,1});
    recTime = double(T{:,8});

    m = isfinite(recTime) & isfinite(samp);
    assert(nnz(m) > 100, 'Too few finite recTime/sample pairs to estimate offset (n=%d)', nnz(m));

    % recTime ≈ samp/Fs + c  ->  c = median(recTime - samp/Fs)
    c = median(recTime(m) - (samp(m) ./ Fs));

    % sanity check: refuse to save nonsense
    if abs(c) > 300  % 5 minutes; adjust if you truly expect larger
        error('Estimated c is too large (%.3f sec). Check trialcodes_concat col1/col8 and Fs.', c);
    end

    if ~exist(eventDir,'dir'); mkdir(eventDir); end
    sample_col = "col1";
    recTime_col = "col8";
    save(offsetPath, 'c', 'Fs', 'sample_col', 'recTime_col', '-v7');
    fprintf('[OK] Saved %s (c=%.9f, Fs=%.0f, sample_col=%s, recTime_col=%s)\n', ...
        offsetPath, c, Fs, sample_col, recTime_col);

else
    D = load(offsetPath);
    if isfield(D,'c')
        fprintf('[info] using existing recTime_offset: c=%.9f (%s)\n', double(D.c), offsetPath);
    else
        fprintf('[warn] recTime_offset exists but missing c? (%s)\n', offsetPath);
    end
end
% -------------------------------------------------------------------------
% (B) Build AlignEvent file
% -------------------------------------------------------------------------
pgp_buildAlignEventFile( ...
    'session',   session, ...
    'root',      root, ...
    'Event',     ev, ...
    'Location',  loc);

fprintf('[OK] Align file built for %s | Epoch=%s | %s/%s | root=%s\n', ...
    session, Epoch, ev, loc, root);

end
