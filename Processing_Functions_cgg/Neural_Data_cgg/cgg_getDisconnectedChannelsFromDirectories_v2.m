function [Connected_Channels,Disconnected_Channels,is_previously_rereferenced,Debugging_Info] = cgg_getDisconnectedChannelsFromDirectories_v2(Count_Sel_Trial,monkey_name,varargin)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here


%%
isfunction=exist('varargin','var');

if isfunction
probe_area = CheckVararginPairs('probe_area', '', varargin{:});
else
if ~(exist('probe_area','var'))
    probe_area=[];
end
end
if isempty(probe_area)
    prompt = {'Enter Probe Area Name (e.g. ACC_001)'};
    dlgtitle = 'Input for Probe Area';
    dims = [1 35];
    definput = {'ACC_001'};
    probe_area = inputdlg(prompt,dlgtitle,dims,definput);
    probe_area = probe_area{1};
end

if isfunction
[cfg] = cgg_generateNeuralDataFolders_v2(probe_area,varargin{:});
elseif (exist('inputfolder','var'))&&(exist('outdatadir','var'))
[cfg] = cgg_generateNeuralDataFolders_v2(probe_area,'inputfolder',...
    inputfolder,'outdatadir',outdatadir);
elseif (exist('inputfolder','var'))&&~(exist('outdatadir','var'))
[cfg] = cgg_generateNeuralDataFolders_v2(probe_area,...
    'inputfolder',inputfolder);
elseif ~(exist('inputfolder','var'))&&(exist('outdatadir','var'))
[cfg] = cgg_generateNeuralDataFolders_v2(probe_area,...
    'outdatadir',outdatadir);
else
[cfg] = cgg_generateNeuralDataFolders_v2(probe_area);
end

if isfunction
Activity_Type = CheckVararginPairs('Activity_Type', '', varargin{:});
else
if ~(exist('Activity_Type','var'))
    Activity_Type=[];
end
end
if isempty(Activity_Type)
    prompt = {'Enter Activity Type (e.g. WideBand)'};
    dlgtitle = 'Input for Activity Type';
    dims = [1 35];
    definput = {'WideBand'};
    Activity_Type = inputdlg(prompt,dlgtitle,dims,definput);
    Activity_Type = Activity_Type{1};
end

%%

this_dir=cfg.outdatadir.Experiment.Session.Activity.Area.(Activity_Type).path;

% get the folder contents
Activity_Type_Folder = dir(this_dir);
% remove all files (isdir property is 0)
Activity_Type_Folder = Activity_Type_Folder(~[Activity_Type_Folder(:).isdir]);
% remove '.' and '..' and the 'Connected' Folder
Activity_Type_Folder = Activity_Type_Folder(~ismember({Activity_Type_Folder(:).name},{'.','..','Connected'}));

Trial_Numbers={Activity_Type_Folder.name};
Trial_Numbers = regexp(Trial_Numbers,'\d*','match');
Trial_Numbers=str2double([Trial_Numbers{:}]);

% fullfilename=regexprep(Activity_Type_Folder(1).name,'\d*','%d');
% 
% NumTrials=length(Trial_Numbers);
%%

inputfolder=cfg.inputfolder.path;
outdatadir=cfg.outdatadir.path;

fullfilename = cgg_generateActivityFullFileName('inputfolder',inputfolder,'outdatadir',outdatadir,...
    'Activity_Type', Activity_Type,'probe_area',probe_area);
%%
% Trial_Table_struct = dir(fullfile(cfg.outdatadir_TrialInformation,'*Table*'));
% Trial_Table_Name = Trial_Table_struct.name;
% rectrialdeftable=load([cfg.outdatadir_TrialInformation filesep Trial_Table_Name]);
% rectrialdeftable=rectrialdeftable.rectrialdeftable;
% [NumTrials,~]=size(rectrialdeftable);

[Connected_Channels,Disconnected_Channels,is_previously_rereferenced,Debugging_Info] = cgg_getDisconnectedChannels_v3(Trial_Numbers,Count_Sel_Trial,fullfilename,monkey_name);
end

