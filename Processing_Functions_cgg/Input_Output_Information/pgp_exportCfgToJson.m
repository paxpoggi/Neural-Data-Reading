function pgp_exportCfgToJson(json_out, varargin)
% pgp_exportCfgToJson
% Export DATA_cggAllSessionInformationConfiguration() into a JSON for Python batch processing.
%
% Required:
%   json_out : full path to write .json
%
% Name-Value:
%   'sorted_root_base' : e.g. '/Volumes/Womelsdorf Lab/Experiments/M1VU595_ACC_PFC_CD/sorted'
%                        OR on ACCRE '/panfs/.../sorted'
%   'sorted_prefix'    : default 'continuous_'  (so sorted_root = base + '/continuous_<session>')
%   'Epoch'            : default 'Decision' (used to determine AlignEvent filenames via PARAMETERS_*)
%   'append'           : kept for backward compat; function now updates existing sessions too
%
% Output JSON payload:
%   payload.generated_at
%   payload.Epoch
%   payload.sessions : cell array of structs, each with:
%       session, experiment, inputfolder, outroot_base, processed_session_root,
%       sorted_root, align_mat, baseline_align_mat

p = inputParser;
addParameter(p,'sorted_root_base','',@(s)ischar(s)||isstring(s));
addParameter(p,'sorted_prefix','continuous_',@(s)ischar(s)||isstring(s));
addParameter(p,'Epoch','Decision',@(s)ischar(s)||isstring(s));
addParameter(p,'append',true,@(x)islogical(x)||isnumeric(x)); %#ok<NASGU> % kept but not used
parse(p,varargin{:});
opts = p.Results;

cfg = DATA_cggAllSessionInformationConfiguration();

S = struct([]);
for i = 1:numel(cfg)
    inputfolder  = cfg(i).inputfolder;
    outroot_base = cfg(i).outdatadir;

    [inputfolder_dir, SessionName, ~] = fileparts(inputfolder);
    [~, ExperimentName, ~] = fileparts(inputfolder_dir);

    processed_session_root = fullfile(outroot_base, ExperimentName, SessionName);

    % ---------------- sorted root ----------------
    sorted_root = '';
    if ~isempty(opts.sorted_root_base)
        sorted_root = fullfile(char(opts.sorted_root_base), [char(opts.sorted_prefix) SessionName]);
    elseif isfield(cfg(i),'sorted_root') && ~isempty(cfg(i).sorted_root)
        sorted_root = cfg(i).sorted_root;
    end

    % ---------------- align mats (data + baseline) ----------------
    cfg_param = PARAMETERS_cgg_procFullTrialPreparation_v2(char(opts.Epoch));

    evD  = cfg_param.Frame_Event_Selection_Data;
    locD = cfg_param.Frame_Event_Selection_Location_Data;
    evB  = cfg_param.Frame_Event_Selection_Baseline;
    locB = cfg_param.Frame_Event_Selection_Location_Baseline;

    % allow cell arrays (older epochs); choose last element by default
    if iscell(evD);  evD  = evD{end};  end
    if iscell(locD); locD = locD{end}; end
    if iscell(evB);  evB  = evB{end};  end
    if iscell(locB); locB = locB{end}; end

    evD  = char(string(evD));
    locD = char(string(locD));
    evB  = char(string(evB));
    locB = char(string(locB));

    frame_dir = fullfile(processed_session_root,'Frame_Information');

    align_mat = '';
    baseline_align_mat = '';

    if exist(frame_dir,'dir')
        % Match pgp_buildAlignEventFile default naming:
        % AlignEvent_<EventNoSpaces>_<LOCATIONUPPER>_<session>.mat
        eventTagD = regexprep(evD,'\s+','');
        eventTagB = regexprep(evB,'\s+','');
        locTagD   = upper(regexprep(locD,'\s+',''));
        locTagB   = upper(regexprep(locB,'\s+',''));

        fD = sprintf('AlignEvent_%s_%s_%s.mat', eventTagD, locTagD, SessionName);
        fB = sprintf('AlignEvent_%s_%s_%s.mat', eventTagB, locTagB, SessionName);

        pD = fullfile(frame_dir, fD);
        pB = fullfile(frame_dir, fB);

        if exist(pD,'file')
            align_mat = pD;
        else
            warning('pgp_exportCfgToJson:MissingAlignMatData', ...
                '[%s] missing DATA align mat: %s', SessionName, pD);
        end

        if exist(pB,'file')
            baseline_align_mat = pB;
        else
            warning('pgp_exportCfgToJson:MissingAlignMatBaseline', ...
                '[%s] missing BASELINE align mat: %s', SessionName, pB);
        end
    else
        warning('pgp_exportCfgToJson:MissingFrameDir', ...
            '[%s] missing Frame_Information dir: %s', SessionName, frame_dir);
    end

    % ---------------- fill struct ----------------
    S(i).session               = SessionName;
    S(i).experiment            = ExperimentName;
    S(i).inputfolder           = inputfolder;
    S(i).outroot_base          = outroot_base;
    S(i).processed_session_root= processed_session_root;
    S(i).sorted_root           = sorted_root;
    S(i).align_mat             = align_mat;
    S(i).baseline_align_mat    = baseline_align_mat;
end

% ---------------- payload header ----------------
payload = struct();
payload.generated_at = char(datetime('now'));
payload.Epoch = char(opts.Epoch);

% ---------------- load old JSON (if exists) ----------------
if exist(json_out,'file')
    old = jsondecode(fileread(json_out));
    if isfield(old,'sessions')
        oldS = old.sessions;
        if iscell(oldS); oldS = [oldS{:}]; end
    else
        oldS = struct([]);
    end
else
    oldS = struct([]);
end

% ---------------- merge: update existing sessions, append missing ----------------
if exist(json_out,'file')
    old = jsondecode(fileread(json_out));
    if isfield(old,'sessions')
        mergedC = old.sessions;
        if ~iscell(mergedC); mergedC = num2cell(mergedC); end
    else
        mergedC = {};
    end
else
    mergedC = {};
end

oldNames = strings(0,1);
for k = 1:numel(mergedC)
    if isfield(mergedC{k},'session')
        oldNames(k,1) = string(mergedC{k}.session);
    else
        oldNames(k,1) = "";
    end
end

for i = 1:numel(S)
    nm = string(S(i).session);
    j = find(oldNames == nm, 1);

    if isempty(j)
        mergedC{end+1} = S(i); %#ok<AGROW>
        oldNames(end+1,1) = nm; %#ok<AGROW>
    else
        % update in place (preserve any extra old fields)
        mergedC{j}.experiment             = S(i).experiment;
        mergedC{j}.inputfolder            = S(i).inputfolder;
        mergedC{j}.outroot_base           = S(i).outroot_base;
        mergedC{j}.processed_session_root = S(i).processed_session_root;
        mergedC{j}.sorted_root            = S(i).sorted_root;
        mergedC{j}.align_mat              = S(i).align_mat;
        mergedC{j}.baseline_align_mat     = S(i).baseline_align_mat;
    end
end

payload.sessions = mergedC;
fprintf('[OK] merged %d sessions\n', numel(mergedC));

% ---------------- write JSON ----------------
txt = jsonencode(payload);
fid = fopen(json_out,'w');
assert(fid>0,'Could not open %s',json_out);
fwrite(fid, txt, 'char');
fclose(fid);

end