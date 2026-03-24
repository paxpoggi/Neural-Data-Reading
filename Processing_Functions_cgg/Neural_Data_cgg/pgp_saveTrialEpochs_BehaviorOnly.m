function pgp_saveTrialEpochs_BehaviorOnly(trialVariables, Epoch, Probe_Order, cfg_directories, cfg_param)
%PGP_SAVETRIALEPOCHS_BEHAVIORONLY
% Writes ONLY:
%   - Target/Target_Information.mat   (Target struct array)
%   - Processing/Probe_Processing_Information.mat
%   - Processing/Parameters_Processing.yaml
%
% Does NOT create any Data trial files.

%% --- paths (match existing directory scheme) ---
TargetDir     = cfg_directories.outdatadir.Experiment.Session.Epoched_Data.Epoch.Target.path;
ProcessingDir = cfg_directories.outdatadir.Experiment.Session.Epoched_Data.Epoch.Processing.path;

if ~exist(TargetDir,'dir'), mkdir(TargetDir); end
if ~exist(ProcessingDir,'dir'), mkdir(ProcessingDir); end

Target_SaveNameFull          = fullfile(TargetDir, 'Target_Information.mat');
ProbeProcessing_SaveNameFull = fullfile(ProcessingDir, 'Probe_Processing_Information.mat');
ParameterProcessing_SaveNameFull = fullfile(ProcessingDir, 'Parameters_Processing.yaml');

%% --- Target_Information.mat ---
% Keep exactly what the original function conceptually stores: Target struct array.
% Add TrialChosen default = true for all (or preserve if it exists).
Target = trialVariables(:);

% If TrialChosen doesn't exist, create it (all true).
if ~isfield(Target,'TrialChosen')
    tc = num2cell(true(size(Target)));
    [Target.TrialChosen] = tc{:};
end

% Write (overwrite is OK for behavior-only; if you want append-only, change)
mT = matfile(Target_SaveNameFull,'Writable',true);
mT.Target = Target;

%% --- Probe_Processing_Information.mat ---
% Mirror original: a struct with fields per probe set to true/false.
ProbeProcessing = struct();
for p = 1:numel(Probe_Order)
    ProbeProcessing.(Probe_Order{p}) = true;  % behavior-only → mark true (or false if you prefer)
end

mP = matfile(ProbeProcessing_SaveNameFull,'Writable',true);
mP.ProbeProcessing = ProbeProcessing;

%% --- Parameters_Processing.yaml ---
% Write the PARAMETERS used so downstream knows what epoch config was used.
WriteYaml(ParameterProcessing_SaveNameFull, cfg_param);



fprintf('pgp_saveTrialEpochs_BehaviorOnly: wrote Target + Processing (no Data) in:\n  %s\n', ...
    cfg_directories.outdatadir.Experiment.Session.Epoched_Data.Epoch.path);

end