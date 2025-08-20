function cgg_procTrialTimeCourses(varargin)
%CGG_PROCTRIALTIMECOURSES Summary of this function goes here
%   Detailed explanation goes here


[cfg] = cgg_generateNeuralDataFoldersTopLevel(varargin{:});
%%

% get the folder contents
Contents_Activity=dir(cfg.outdatadir_Activity);
% remove all files (isdir property is 0)
Contents_Activity=Contents_Activity([Contents_Activity(:).isdir]);
% remove '.' and '..'
Contents_Activity = Contents_Activity(~ismember({Contents_Activity(:).name},{'.','..',}));
% remove folders that start with '._'
Contents_Activity = Contents_Activity(~startsWith({Contents_Activity.name}, '._'));

outdatadir_EX_Area=[cfg.outdatadir_Activity, filesep, Contents_Activity(1).name];

% get the folder contents
Contents_EX_Area = dir(outdatadir_EX_Area);
% remove all files (isdir property is 0)
Contents_EX_Area = Contents_EX_Area([Contents_EX_Area(:).isdir]);
% remove '.' and '..' and the 'Connected' Folder
Contents_EX_Area = Contents_EX_Area(~ismember({Contents_EX_Area(:).name},{'.','..','Connected'}));
%%
NumTypesActivity=length(Contents_EX_Area);

% Generate the folder name for the Time Information
outdatadir_TimeInformation=[cfg.outdatadir_SessionName, filesep, 'Time_Information'];

% Check if the Time Information folder exists
if ~exist(outdatadir_TimeInformation, 'dir')
    mkdir(outdatadir_TimeInformation);
end
% Record the Time information in the configuration struct
cfg.outdatadir_TimeInformation=outdatadir_TimeInformation;

% Generate the folder names for the Time Information for the types of
% activity

for aidx=1:NumTypesActivity
    
    outdatadir_TimeInformation_Type{aidx}=[outdatadir_TimeInformation filesep Contents_EX_Area(aidx).name];

    outdatadir_EX_Area_Type{aidx}=[outdatadir_EX_Area filesep Contents_EX_Area(aidx).name];
    
    % Check if the Time Information folder for this type of Activity exists
    if ~exist(outdatadir_TimeInformation_Type{aidx}, 'dir')
        mkdir(outdatadir_TimeInformation_Type{aidx});
    end
end

% Record the Time information in the configuration struct
cfg.outdatadir_TimeInformation_Type=outdatadir_TimeInformation_Type;

%%

for aidx=1:NumTypesActivity

% get the folder contents
Contents_EX_Area_Type = dir(outdatadir_EX_Area_Type{aidx});
% remove all files (isdir property is 0)
Contents_EX_Area_Type = Contents_EX_Area_Type(~([Contents_EX_Area_Type(:).isdir]));
% remove '.' and '..' and remove files starting with '._'
mask = ~ismember({Contents_EX_Area_Type(:).name},{'.','..'})& ~startsWith({Contents_EX_Area_Type(:).name},'._');
Contents_EX_Area_Type = Contents_EX_Area_Type(mask);

NumTrials=length(Contents_EX_Area_Type);

parfor tidx=1:NumTrials
    
[~,EX_Area_Type_Trial_File_Name,~]=fileparts(Contents_EX_Area_Type(tidx).name); 
    
EX_Area_Type_Trial_Time_Name=[outdatadir_TimeInformation_Type{aidx} filesep EX_Area_Type_Trial_File_Name '_Time.mat'];

if ~(exist(EX_Area_Type_Trial_Time_Name,'file'))

outdatadir_EX_Area_Type_Trial=[outdatadir_EX_Area_Type{aidx} filesep EX_Area_Type_Trial_File_Name '.mat'];

m_EX_Area_Type_Trial=matfile(outdatadir_EX_Area_Type_Trial);

EX_Area_Type_Trial_Name=who(m_EX_Area_Type_Trial);
EX_Area_Type_Trial_Name=EX_Area_Type_Trial_Name{1};

EX_Area_Type_Trial=m_EX_Area_Type_Trial.(EX_Area_Type_Trial_Name);

EX_Area_Type_Trial_Time=EX_Area_Type_Trial.time{1};

% [~,EX_Area_Type_Trial_File_Name,~]=fileparts(Contents_EX_Area_Type(tidx).name);
% 
% EX_Area_Type_Trial_Time_Name=[outdatadir_TimeInformation_Type{aidx} filesep EX_Area_Type_Trial_File_Name '_Time.mat'];

m_EX_Area_Type_Trial_Time=matfile(EX_Area_Type_Trial_Time_Name,'writable',true);
m_EX_Area_Type_Trial_Time.this_trial_time=EX_Area_Type_Trial_Time;
% m_EX_Area_Type_Trial_Time.this_fsample=EX_Area_Type_Trial.fsample;
end

end
end

end

