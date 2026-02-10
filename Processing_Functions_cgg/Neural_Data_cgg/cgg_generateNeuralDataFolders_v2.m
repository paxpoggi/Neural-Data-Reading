function [cfg] = cgg_generateNeuralDataFolders_v2(probe_area,varargin)
%CGG_GENERATENEURALDATAFOLDERS Summary of this function goes here
%   Detailed explanation goes here

%%
isfunction=exist('varargin','var');

if isfunction
WantDirectory = CheckVararginPairs('WantDirectory', true, varargin{:});
else
if ~(exist('WantDirectory','var'))
WantDirectory=true;
end
end

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

cfg=struct();

cfg.outdatadir.path=outdatadir;
cfg.inputfolder.path=inputfolder;

%%

% Make the Experiment and Session output folder names.
cfg_tmp=cfg.outdatadir;
[cfg_tmp,~] = cgg_generateFolderAndPath(ExperimentName,'Experiment',cfg_tmp,'WantDirectory',WantDirectory);
cfg.outdatadir=cfg_tmp;

cfg_tmp=cfg.outdatadir.Experiment;
[cfg_tmp,~] = cgg_generateFolderAndPath(SessionName,'Session',cfg_tmp,'WantDirectory',WantDirectory);
cfg.outdatadir.Experiment=cfg_tmp;

% Make the Activity output folder names.
cfg_tmp=cfg.outdatadir.Experiment.Session;
[cfg_tmp,~] = cgg_generateFolderAndPath('Activity','Activity',cfg_tmp,'WantDirectory',WantDirectory);
cfg.outdatadir.Experiment.Session=cfg_tmp;

% Make the Parameters folder names.
cfg_tmp=cfg.outdatadir.Experiment.Session;
[cfg_tmp,~] = cgg_generateFolderAndPath('Parameters','Parameters',cfg_tmp,'WantDirectory',WantDirectory);
cfg.outdatadir.Experiment.Session=cfg_tmp;

% Make the Area output folder names.
cfg_tmp=cfg.outdatadir.Experiment.Session.Activity;
[cfg_tmp,~] = cgg_generateFolderAndPath(probe_area,'Area',cfg_tmp,'WantDirectory',WantDirectory);
cfg.outdatadir.Experiment.Session.Activity=cfg_tmp;

% FIXME: EDITTED THIS TO MAKE FOR EASIER FINDING OF ACTIVITY DOUBLE CHECK
% IT DID NOT RUIN ANYTHING!!!!!!!

% Make the Processed Activity output folder names.
cfg_tmp=cfg.outdatadir.Experiment.Session.Activity.Area;
[cfg_tmp,~] = cgg_generateFolderAndPath('WideBand','WideBand',cfg_tmp,'WantDirectory',WantDirectory);
cfg.outdatadir.Experiment.Session.Activity.Area=cfg_tmp;

cfg_tmp=cfg.outdatadir.Experiment.Session.Activity.Area;
[cfg_tmp,~] = cgg_generateFolderAndPath('LFP','LFP',cfg_tmp,'WantDirectory',WantDirectory);
cfg.outdatadir.Experiment.Session.Activity.Area=cfg_tmp;

cfg_tmp=cfg.outdatadir.Experiment.Session.Activity.Area;
[cfg_tmp,~] = cgg_generateFolderAndPath('Spike','Spike',cfg_tmp,'WantDirectory',WantDirectory);
cfg.outdatadir.Experiment.Session.Activity.Area=cfg_tmp;

cfg_tmp=cfg.outdatadir.Experiment.Session.Activity.Area;
[cfg_tmp,~] = cgg_generateFolderAndPath('MUA','MUA',cfg_tmp,'WantDirectory',WantDirectory);
cfg.outdatadir.Experiment.Session.Activity.Area=cfg_tmp;

cfg_tmp=cfg.outdatadir.Experiment.Session.Activity.Area;
[cfg_tmp,~] = cgg_generateFolderAndPath('Raw','Raw',cfg_tmp,'WantDirectory',WantDirectory);
cfg.outdatadir.Experiment.Session.Activity.Area=cfg_tmp;

% Make the Channel Clustering Folder output folder names
cfg_tmp=cfg.outdatadir.Experiment.Session.Activity.Area;
[cfg_tmp,~] = cgg_generateFolderAndPath('Connected','Connected',cfg_tmp,'WantDirectory',WantDirectory);
cfg.outdatadir.Experiment.Session.Activity.Area=cfg_tmp;


end

