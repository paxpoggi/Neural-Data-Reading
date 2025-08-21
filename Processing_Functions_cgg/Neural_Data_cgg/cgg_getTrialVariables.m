function [trialVariables] = cgg_getTrialVariables(varargin)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
%%

isfunction=exist('varargin','var');
monkey_name = CheckVararginPairs('monkey_name', 'Frey', varargin{:});
ExperimentName = CheckVararginPairs('ExperimentName', 'IDED_DBC_AH_AN/VU595_DBC', varargin{:});
if isfunction
[cfg] = cgg_generateNeuralDataFoldersTopLevel(varargin{:});
[cfg_v2] = cgg_generateNeuralDataFoldersTopLevel_v2(varargin{:});
elseif (exist('inputfolder','var'))&&(exist('outdatadir','var'))
[cfg] = cgg_generateNeuralDataFoldersTopLevel('inputfolder',...
    inputfolder,'outdatadir',outdatadir);
[cfg_v2] = cgg_generateNeuralDataFoldersTopLevel_v2('inputfolder',...
    inputfolder,'outdatadir',outdatadir);
elseif (exist('inputfolder','var'))&&~(exist('outdatadir','var'))
[cfg] = cgg_generateNeuralDataFoldersTopLevel('inputfolder',inputfolder);
[cfg_v2] = cgg_generateNeuralDataFoldersTopLevel_v2(...
    'inputfolder',inputfolder);
elseif ~(exist('inputfolder','var'))&&(exist('outdatadir','var'))
[cfg] = cgg_generateNeuralDataFoldersTopLevel('outdatadir',outdatadir);
[cfg_v2] = cgg_generateNeuralDataFoldersTopLevel_v2(...
    'outdatadir',outdatadir);
else
[cfg] = cgg_generateNeuralDataFoldersTopLevel;
[cfg_v2] = cgg_generateNeuralDataFoldersTopLevel_v2;
end

inputfolder=cfg.inputfolder;
outdatadir=cfg.outdatadir;

%%

TrialVariables_file_name=[cfg_v2.outdatadir.Experiment.Session.Trial_Information.path filesep 'TrialVariables_', cfg.SessionName, '.mat'];

if ~(exist(TrialVariables_file_name,'file')) 

    %% add in cases for woton and frey vs Igor
    switch ExperimentName
        
        case 'Wotan_FLToken_Probe_01'
            
            Session_struct = dir(fullfile(inputfolder,'Session*'));
            USE_Session_Name = Session_struct.name;
        
            if length(Session_struct)>1
                disp(['!!! Please make sure there is only one USE session in the '...
                'recording folder']);
                disp('!!! The wrong session may be used to identify trial variables');
            end

        case 'Frey_FLToken_Probe_02'
            
            Session_struct = dir(fullfile(inputfolder,'Session*'));
            USE_Session_Name = Session_struct.name;
        
            if length(Session_struct)>1
                disp(['!!! Please make sure there is only one USE session in the '...
                'recording folder']);
                disp('!!! The wrong session may be used to identify trial variables');
            end

        case 'Frey_FLToken_Probe_03'
            
            Session_struct = dir(fullfile(inputfolder,'Session*'));
            USE_Session_Name = Session_struct.name;
        
            if length(Session_struct)>1
                disp(['!!! Please make sure there is only one USE session in the '...
                'recording folder']);
                disp('!!! The wrong session may be used to identify trial variables');
            end
        
        case 'IDED_DBC_AH_AN/VU595_DBC'
            [~, SessionName]=fileparts(inputfolder);
            Session_struct = dir(fullfile(inputfolder, '*_BHV'));
            USE_Session_Name = [SessionName '_BHV'];
            if length(Session_struct)>1
                            disp(['!!! Please make sure there is only one USE session in the '...
                            'recording folder']);
                            disp('!!! The wrong session may be used to identify trial variables');
            end
        otherwise
            warning('Unknown monkey name: %s.', monkey_name)
    end

[Path_Experiment,Session_Name,~]=fileparts(inputfolder);

%%


dataFolder=[inputfolder filesep USE_Session_Name];
outdatadir_LT=cfg.outdatadir_SessionName;

gazeArgs='TX300';
exptType='FLU';

[trialData, blockData] = ProcessSingleSessionData_FLU('exptType',exptType,'gazeArgs',gazeArgs,'outdatadir',outdatadir_LT,'dataFolder',dataFolder);

folder_name = Session_Name;
session_file = USE_Session_Name;
data_path = Path_Experiment;
% Area = 1; %1 = ACC, 2 = CD
switch monkey_name
    case 'Frey', MnkID=1;
    case 'Wotan', MnkID=2;
    case 'Igor', MnkID=3;
end
% MnkID = 1; %1 = Frey

proccessed_path = cfg.outdatadir_SessionName;

[TrialDATA, BlockDATA]  = cgg_singlesession_data_LT3(folder_name, session_file, data_path,proccessed_path, NaN, MnkID, ExperimentName);
% Save behavior once per session (area-agnostic)
sessTrialPath = fullfile(cfg_v2.outdatadir.Experiment.Session.Trial_Information.path, ...
                         ['TrialDATA_session_' cfg.SessionName '.mat']);
sessBlockPath = fullfile(cfg_v2.outdatadir.Experiment.Session.Trial_Information.path, ...
                         ['BlockDATA_session_' cfg.SessionName '.mat']);
try
    save(sessTrialPath, 'TrialDATA', '-v7.3');
    save(sessBlockPath, 'BlockDATA', '-v7.3');
catch ME
     warning(ME.identifier, ...
        'Could not save per-probe Trial/Block data for %s: %s', ...
        this_probe_area, ME.message);
end

%%
trialDefsFolder=[proccessed_path, filesep, 'ProcessedData', filesep, 'TrialDefs.mat'];
load(trialDefsFolder);
%%

Performance_Window=5;

TrialNumber=trialData.TrialCounter;
TrialInBlock=trialData.TrialInBlock;
AbortCode=trialData.AbortCode;
SelectedObjectID=trialData.SelectedObjectID;
CorrectTrial=trialData.PositiveFbObtained;
TrialsFromLP=trialData.TrialsFromLP;
TrialTime=trialData.TrialTime;
Block=trialData.Block;
TargetFeature=TrialDATA.TargetFeature;
ReactionTime=TrialDATA.RT;

IsTrialCorrect=strcmp(CorrectTrial,{'True'});

trialVariables=struct();

for tidx=1:length(TrialNumber)
    
    trialVariables(tidx).TrialNumber=TrialNumber(tidx);
    trialVariables(tidx).TrialInBlock=TrialInBlock(tidx);
    trialVariables(tidx).AbortCode=AbortCode(tidx);
    trialVariables(tidx).CorrectTrial=CorrectTrial(tidx);
    trialVariables(tidx).TrialsFromLP=TrialsFromLP(tidx);
    trialVariables(tidx).TrialTime=TrialTime(tidx);
    trialVariables(tidx).Block=Block(tidx);
    trialVariables(tidx).TargetFeature=TargetFeature(tidx);
    trialVariables(tidx).ReactionTime=ReactionTime(tidx);
    
    this_Perfromance=NaN;

    if TrialInBlock(tidx)<Performance_Window
        this_Perfromance=sum(IsTrialCorrect(tidx-TrialInBlock(tidx)+1:tidx))/Performance_Window;
    else
        this_Perfromance=sum(IsTrialCorrect(tidx-Performance_Window+1:tidx))/Performance_Window;
    end
    
    trialVariables(tidx).Performance=this_Perfromance;
    
    this_trialDef=trialDefs{tidx};
    this_RelevantStims=this_trialDef.RelevantStims;
    this_Token_Gain=this_trialDef.TokenRewardsPositive.NumTokens;
    this_Token_Loss=this_trialDef.TokenRewardsNegative.NumTokens;
    
    this_SelectedObjectID=SelectedObjectID{tidx};
    this_SelectedObjectID_idx=str2double(regexp(this_SelectedObjectID,'\d*','Match'));
    
    if isempty(this_SelectedObjectID_idx)
        this_SelectedObjectDimVals=[];
    else
        this_SelectedObjectDimVals=this_RelevantStims(this_SelectedObjectID_idx).StimDimVals;
    end
    
    this_NumDimensions=length(this_SelectedObjectDimVals);
    this_ObjectNumZeroDim=sum(this_SelectedObjectDimVals==0);
    
    this_trialDimensionality=this_NumDimensions-this_ObjectNumZeroDim;

    trialVariables(tidx).SelectedObjectDimVals=this_SelectedObjectDimVals;
    trialVariables(tidx).Dimensionality=this_trialDimensionality;
    trialVariables(tidx).Gain=this_Token_Gain;
    trialVariables(tidx).Loss=this_Token_Loss;
    
    Previous_Trial=NaN;
%     this_Previous_SelectedObjectDimVals=NaN;
%     hasSharedFeature=NaN;
    
    if tidx>1
        Previous_Trial=CorrectTrial(tidx-1);
%         this_Previous_SelectedObjectDimVals=trialVariables(tidx-1).SelectedObjectDimVals;
%         PriorNonZeroFeature=this_Previous_SelectedObjectDimVals~=0;
%         hasSharedFeature=any(this_Previous_SelectedObjectDimVals(PriorNonZeroFeature)==this_SelectedObjectDimVals(PriorNonZeroFeature));
    end
    
    trialVariables(tidx).PreviousTrialCorrect=Previous_Trial;
%     trialVariables(tidx).PreviousSelectedObjectDimVals=this_Previous_SelectedObjectDimVals;
%     trialVariables(tidx).SharesFeature=hasSharedFeature;
end

% m_TrialVariables = matfile(TrialVariables_file_name,'Writable',true);
% m_TrialVariables.trialVariables=trialVariables;

SaveVariables={trialVariables};
SaveVariablesName={'trialVariables'};
cgg_saveVariableUsingMatfile(SaveVariables,SaveVariablesName,TrialVariables_file_name);
else
m_TrialVariables = matfile(TrialVariables_file_name,'Writable',false);
trialVariables=m_TrialVariables.trialVariables;
end

end

