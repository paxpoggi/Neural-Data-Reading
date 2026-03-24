function outPath = pgp_buildAlignEventFile(varargin)
%PGP_BUILDALIGNEVENTFILE  Save per-trial recTime for an alignment event (MATLAB -> Python bridge).
%
% This replaces the ad-hoc event_information_conversion.m script with a
% reusable function that matches your pipeline conventions.
%
% It extracts ONE recTime per trial for a given event + location (START/END)
% from gameframedata, and saves it as a struct array Salign where each
% element has fields:
%   - trialCounter (or whatever idcol you choose)
%   - recTime
%
% Usage (minimal):
%   outPath = pgp_buildAlignEventFile( ...
%       'session', 'Ig_VU595_07_2023-03-14_A', ...
%       'root',    '/Volumes/NVME SSD/processed_data/Ig_VU595_07_2023-03-14_A', ...
%       'Event',   'SelectObject', ...
%       'Location','END');
%
% Options:
%   'FrameMat'  : full path to Frame_Data_<session>.mat (default: root/Frame_Information/Frame_Data_<session>.mat)
%   'evcol'     : event-name column in gameframedata (default: 'TrialEpoch')
%   'idcol'     : trial id column in gameframedata (default: 'TrialCounter')
%   'loccol'    : location column (auto-detect among Location, Frame_Event_Location, StartEnd). Override to force.
%   'LocPolicy' : how to collapse multiple rows/trial for the event:
%                  - 'last' (default): takes last row in time per trial (END-ish)
%                  - 'first': takes first row in time per trial (START-ish)
%                  - 'strict': if Location provided, filter by it; else error if multiple rows/trial.
%   'OutName'   : output filename (default auto: AlignEvent_<Event>_<Location>_<session>.mat)
%   'OutDir'    : output directory (default: root/Frame_Information)
%   'VarName'   : variable name to save (default: 'Salign')
%   'SaveVersion': '-v7' (default) or '-v7.3'
%
% Output:
%   outPath: full path to saved .mat
%
% Notes:
% - SciPy reads struct arrays saved with -v7 reliably.
% - This function does NOT require trialcodes_concat or any offset c.

% ------------------ parse inputs ------------------
p = inputParser;
p.addParameter('session', '', @(s)ischar(s)||isstring(s));
p.addParameter('root',    '', @(s)ischar(s)||isstring(s));
p.addParameter('Event',   'SelectObject', @(s)ischar(s)||isstring(s));
p.addParameter('Location','END', @(s)ischar(s)||isstring(s)||isempty(s));
p.addParameter('FrameMat','', @(s)ischar(s)||isstring(s));
p.addParameter('evcol',   'TrialEpoch', @(s)ischar(s)||isstring(s));
p.addParameter('idcol',   'TrialCounter', @(s)ischar(s)||isstring(s));
p.addParameter('loccol',  '', @(s)ischar(s)||isstring(s)||isempty(s));
p.addParameter('LocPolicy','last', @(s)ischar(s)||isstring(s));
p.addParameter('OutDir',  '', @(s)ischar(s)||isstring(s));
p.addParameter('OutName', '', @(s)ischar(s)||isstring(s));
p.addParameter('VarName', 'Salign', @(s)ischar(s)||isstring(s));
p.addParameter('SaveVersion','-v7', @(s)ischar(s)||isstring(s));
p.parse(varargin{:});
opt = p.Results;

session = char(opt.session);
root    = char(opt.root);
Event   = char(opt.Event);
Location = opt.Location;
if ~isempty(Location), Location = char(Location); end

if isempty(session)
    error('pgp_buildAlignEventFile:MissingSession','Provide ''session''.');
end
if isempty(root)
    error('pgp_buildAlignEventFile:MissingRoot','Provide ''root'' (processed_data/<session>).');
end

% defaults
if isempty(opt.FrameMat)
    frameMat = fullfile(root,'Frame_Information',sprintf('Frame_Data_%s.mat',session));
else
    frameMat = char(opt.FrameMat);
end

if isempty(opt.OutDir)
    outDir = fullfile(root,'Frame_Information');
else
    outDir = char(opt.OutDir);
end
if ~exist(outDir,'dir'), mkdir(outDir); end

% sanitize event/location for filename
eventTag = regexprep(Event,'\s+','');
locTag = '';
if ~isempty(Location)
    locTag = regexprep(upper(Location),'\s+','');
else
    locTag = 'AUTO';
end

if isempty(opt.OutName)
    outName = sprintf('AlignEvent_%s_%s_%s.mat', eventTag, locTag, session);
else
    outName = char(opt.OutName);
end
outPath = fullfile(outDir, outName);

evcol = char(opt.evcol);
idcol = char(opt.idcol);
loccol_force = opt.loccol;
if ~isempty(loccol_force), loccol_force = char(loccol_force); end
locPolicy = lower(char(opt.LocPolicy));
varName = char(opt.VarName);
saveVer = char(opt.SaveVersion);

% ------------------ load gameframedata ------------------
S = load(frameMat);
if ~isfield(S,'gameframedata')
    error('pgp_buildAlignEventFile:NoGameFrameData','%s does not contain gameframedata', frameMat);
end
gameframedata = S.gameframedata;

% sanity
vn = gameframedata.Properties.VariableNames;
if ~ismember(evcol, vn)
    error('pgp_buildAlignEventFile:MissingEvCol','evcol "%s" not in gameframedata. Columns include: %s', ...
        evcol, strjoin(vn,', '));
end
if ~ismember(idcol, vn)
    error('pgp_buildAlignEventFile:MissingIdCol','idcol "%s" not in gameframedata. Columns include: %s', ...
        idcol, strjoin(vn,', '));
end
if ~ismember('recTime', vn)
    error('pgp_buildAlignEventFile:MissingRecTime','recTime not in gameframedata. Columns include: %s', strjoin(vn,', '));
end

% location column auto-detect unless forced
loccol = '';
if ~isempty(loccol_force)
    loccol = loccol_force;
    if ~ismember(loccol, vn)
        error('pgp_buildAlignEventFile:MissingLocCol','Forced loccol "%s" not in gameframedata.', loccol);
    end
else
    if ismember('Location', vn)
        loccol = 'Location';
    elseif ismember('Frame_Event_Location', vn)
        loccol = 'Frame_Event_Location';
    elseif ismember('StartEnd', vn)
        loccol = 'StartEnd';
    end
end

% ------------------ select rows matching event (+ location) ------------------
m = strcmpi(string(gameframedata.(evcol)), string(Event));

if ~isempty(Location)
    if isempty(loccol)
        warning('pgp_buildAlignEventFile:NoLocCol',...
            'Location="%s" requested but no location column found. Falling back to LocPolicy="%s" without location filtering.', ...
            Location, locPolicy);
    else
        m = m & strcmpi(string(gameframedata.(loccol)), string(Location));
    end
end

Tsel = gameframedata(m, {idcol, 'recTime'});

if isempty(Tsel)
    error('pgp_buildAlignEventFile:NoMatches',...
        'No rows matched Event="%s" (evcol="%s") with Location="%s" (loccol="%s").', ...
        Event, evcol, string(Location), loccol);
end

% ------------------ collapse to one row per trial ------------------
% sort by id then recTime
Tsel = sortrows(Tsel, {idcol,'recTime'});

switch locPolicy
    case 'last'
        [~, ia] = unique(Tsel.(idcol), 'last');
        Tsel = Tsel(ia,:);
    case 'first'
        [~, ia] = unique(Tsel.(idcol), 'first');
        Tsel = Tsel(ia,:);
    case 'strict'
        % if multiple rows per id, error
        [u,~,g] = unique(Tsel.(idcol));
        counts = accumarray(g,1);
        if any(counts>1)
            bad = u(counts>1);
            error('pgp_buildAlignEventFile:StrictMultipleRows',...
                'Strict policy: multiple recTime rows for %d trials (e.g. %s). Provide Location or use LocPolicy=first/last.', ...
                numel(bad), mat2str(bad(1:min(10,numel(bad)))'));
        end
    otherwise
        error('pgp_buildAlignEventFile:BadLocPolicy','Unknown LocPolicy "%s". Use first|last|strict.', locPolicy);
end

% enforce types
% convert to struct array with nice field names
% ensure trial id field is named trialCounter in the output (Python expects it)
trialIds = double(Tsel.(idcol));
recTimes = double(Tsel.recTime);

Salign = struct('trialCounter', num2cell(trialIds(:)), ...
                'recTime',      num2cell(recTimes(:)));

% ------------------ save ------------------
% save struct array under varName
tmp = struct();
tmp.(varName) = Salign;

% Prefer -v7 for SciPy compatibility unless user requests -v7.3
save(outPath, '-struct', 'tmp', saveVer);

fprintf('Saved %s (%d trials)  Event="%s"  Location="%s"  idcol="%s"  evcol="%s"\n', ...
    outPath, numel(Salign), Event, string(Location), idcol, evcol);

end
