function [cfg] = cgg_generateNeuralDataFoldersTopLevel(varargin)
%CGG_GENERATENEURALDATAFOLDERS Summary of this function goes here
%   Detailed explanation goes here

%%
isfunction=exist('varargin','var');

if isfunction
inputfolder = CheckVararginPairs('inputfolder', '', varargin{:});
outdatadir = CheckVararginPairs('outdatadir', '', varargin{:});

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

%% Edit for if input folder is not the same as outdatadir
% Start from the outdatadir root
% outdir_contents = dir(outdatadir);
% subfolders = outdir_contents([outdir_contents.isdir]);
% subfolders = subfolders(~ismember({subfolders.name},{'.','..'}));
% 
% subfolderNames = {subfolders.name}; % Extract names of subfolders
% ExperimentName = subfolderNames{1}; % Assuming the first subfolder is the ExperimentName
% 
% session_dir = dir(fullfile(outdatadir, ExperimentName));
% session_dir = session_dir([session_dir.isdir]);
% session_dir_children_names = session_dir(~ismember({session_dir.name},{'.','..'}));
% 
% SessionName = session_dir_children_names(1).name; 

% disp(ExperimentName)
% disp(SessionName)

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

% Make the Experiment and Session output folder names.
outdatadir_Experiment=[outdatadir, filesep, ExperimentName];
outdatadir_SessionName=[outdatadir_Experiment, filesep, SessionName];
% Make the Activity, Event Information, Frame Information, and Trial
% Information output folder names.
outdatadir_Activity=[outdatadir_SessionName, filesep, 'Activity'];
outdatadir_EventInformation=[outdatadir_SessionName, filesep, 'Event_Information'];
outdatadir_FrameInformation=[outdatadir_SessionName, filesep, 'Frame_Information'];
outdatadir_TrialInformation=[outdatadir_SessionName, filesep, 'Trial_Information'];


%%

% Check if the Experiment and Session output folders exist and if they do
% not, create them.
if ~exist(outdatadir_Experiment, 'dir')
    mkdir(outdatadir_Experiment);
end
if ~exist(outdatadir_SessionName, 'dir')
    mkdir(outdatadir_SessionName);
end

% Check if the Activity, Event Information, Frame Information, and Trial
% Information output folders exist and if they do not, create them.
if ~exist(outdatadir_Activity, 'dir')
    mkdir(outdatadir_Activity);
end
if ~exist(outdatadir_EventInformation, 'dir')
    mkdir(outdatadir_EventInformation);
end
if ~exist(outdatadir_FrameInformation, 'dir')
    mkdir(outdatadir_FrameInformation);
end
if ~exist(outdatadir_TrialInformation, 'dir')
    mkdir(outdatadir_TrialInformation);
end


%% Assign all the full path folder names to fields
cfg.inputfolder=inputfolder;
cfg.outdatadir=outdatadir;
cfg.outdatadir_Experiment=outdatadir_Experiment;
cfg.outdatadir_SessionName=outdatadir_SessionName;
cfg.outdatadir_Activity=outdatadir_Activity;
cfg.outdatadir_EventInformation=outdatadir_EventInformation;
cfg.outdatadir_FrameInformation=outdatadir_FrameInformation;
cfg.outdatadir_TrialInformation=outdatadir_TrialInformation;

%% Assign Other Single Folder Names to Fields
cfg.SessionName=SessionName;
cfg.ExperimentName=ExperimentName;

end

