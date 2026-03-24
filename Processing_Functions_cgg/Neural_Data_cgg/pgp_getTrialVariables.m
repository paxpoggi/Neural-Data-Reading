function [trialVariables] = pgp_getTrialVariables(varargin)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
%%

isfunction=exist('varargin','var');
monkey_name = CheckVararginPairs('monkey_name', 'Frey', varargin{:});
ExperimentName = CheckVararginPairs('ExperimentName', 'IDED_DBC_AH_AN', varargin{:});
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
        
        case 'IDED_DBC_AH_AN'
            [~, SessionName] = fileparts(inputfolder);
            
            % Find all candidate BHV folders for this session
            bhvStruct = dir(fullfile(inputfolder, '*_BHV'));
            bhvStruct = bhvStruct([bhvStruct.isdir]);

            if isempty(bhvStruct)
                error('No *_BHV folder found under: %s', inputfolder);
            end

            if numel(bhvStruct) > 1
                disp(['!!! Please make sure there is only one USE session in the '...
                      'recording folder']);
                disp('!!! The wrong session may be used to identify trial variables');
            end

            % Score each BHV folder by how much is in RuntimeData/FrameData
            scores_nFiles = -inf(numel(bhvStruct),1);
            scores_bytes  = -inf(numel(bhvStruct),1);

            for i = 1:numel(bhvStruct)
                bhvName = bhvStruct(i).name;
                frameDir = fullfile(inputfolder, bhvName, 'RuntimeData', 'FrameData');

                if exist(frameDir, 'dir')
                    ff = dir(fullfile(frameDir, '*.txt'));
                    ff = ff(~[ff.isdir]);
                    scores_nFiles(i) = numel(ff);
                    if ~isempty(ff)
                        scores_bytes(i) = sum([ff.bytes]);
                    else
                        scores_bytes(i) = 0;
                    end
                else
                    scores_nFiles(i) = -1;  % missing FrameData -> penalize hard
                    scores_bytes(i)  = -1;
                end
            end

            % Pick best by (nFiles, bytes)
            [~, bestIdx] = max([scores_nFiles scores_bytes], [], 1); %#ok<ASGLU>
            % max on columns doesn't directly give row; do lexicographic:
            [~, bestIdx] = max(scores_nFiles);
            tied = find(scores_nFiles == scores_nFiles(bestIdx));
            if numel(tied) > 1
                [~, j] = max(scores_bytes(tied));
                bestIdx = tied(j);
            end

            USE_Session_Name = bhvStruct(bestIdx).name;

            % Optional: print what was chosen for transparency
            if numel(bhvStruct) > 1
                fprintf('DEBUG: BHV candidates:\n');
                for i = 1:numel(bhvStruct)
                    fprintf('  %s | FrameData txt files=%d | bytes=%g\n', ...
                        bhvStruct(i).name, scores_nFiles(i), scores_bytes(i));
                end
                fprintf('DEBUG: using BHV folder: %s\n', USE_Session_Name);
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



% --- Sanity check: make sure we're reading from the INPUT tree
% ---debugging code 
td = fullfile(dataFolder, 'RuntimeData', 'TrialData');
fprintf('DEBUG dataFolder = %s\n', dataFolder);
fprintf('DEBUG trialData path = %s\n', td);

if ~startsWith(dataFolder, inputfolder)
    error('dataFolder points to the output tree! dataFolder=%s  inputfolder=%s', dataFolder, inputfolder);
end

if ~exist(td, 'dir')
    error('Expected TrialData dir does not exist: %s', td);
end

listing = dir(fullfile(td, '*TrialData.txt'));
fprintf('DEBUG found %d TrialData files\n', numel(listing));
for k = 1:min(5, numel(listing))
    fprintf('   %s\n', fullfile(listing(k).folder, listing(k).name));
end

if isempty(listing)
    error('No *TrialData.txt in %s. (Check you are pointing at INPUT, not OUTPUT.)', td);
end
%% debugging code

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

    % ------------------------------------------------------------
    % NEW: save ALL relevant stim feature vectors + locations
    % (match existing structure: take from this_RelevantStims)
    % ------------------------------------------------------------
    nStims = numel(this_RelevantStims);

    % --- StimDimVals for all stims (keep as cell for safety) ---
    % Typical: 3 stims, each has StimDimVals numeric row
    allStimDimVals = cell(nStims,1);
    for si = 1:nStims
        if isfield(this_RelevantStims(si), 'StimDimVals')
            allStimDimVals{si} = this_RelevantStims(si).StimDimVals;
        else
            allStimDimVals{si} = [];
        end
    end
    trialVariables(tidx).RelevantStimDimVals = allStimDimVals;

    % Also provide a convenient 3xK numeric matrix when possible
    % (keeps code robust if K differs across sessions)
    if nStims == 3 && all(cellfun(@(x) isnumeric(x) && ~isempty(x), allStimDimVals))
        try
            K = max(cellfun(@numel, allStimDimVals));
            mat = nan(3, K);
            for si = 1:3
                v = double(allStimDimVals{si}(:))';
                mat(si,1:numel(v)) = v;
            end
            trialVariables(tidx).RelevantStimDimVals_mat = mat;  % [3 x K]
        catch
            trialVariables(tidx).RelevantStimDimVals_mat = [];
        end
    else
        trialVariables(tidx).RelevantStimDimVals_mat = [];
    end

    % --- StimLocation XYZ for all stims ---
    % You said: each RelevantStim has StimLocation with xyz fields/structs
    allStimXYZ = cell(nStims,1);
    for si = 1:nStims
        xyz = [];
        if isfield(this_RelevantStims(si), 'StimLocation')
            SL = this_RelevantStims(si).StimLocation;

            % tolerate different schemas:
            %  (a) SL.xyz is [1x3]
            %  (b) SL has fields x,y,z
            %  (c) SL is struct with one numeric [1x3] field inside
            if isstruct(SL)
                if isfield(SL,'xyz') && isnumeric(SL.xyz) && numel(SL.xyz)==3
                    xyz = double(SL.xyz(:))';
                elseif all(isfield(SL,{'x','y','z'}))
                    xyz = [double(SL.x) double(SL.y) double(SL.z)];
                else
                    f = fieldnames(SL);
                    for fi = 1:numel(f)
                        vv = SL.(f{fi});
                        if isnumeric(vv) && numel(vv)==3
                            xyz = double(vv(:))';
                            break;
                        end
                    end
                end
            elseif isnumeric(SL) && numel(SL)==3
                xyz = double(SL(:))';
            end
        end
        allStimXYZ{si} = xyz; % either [] or [1x3]
    end
    trialVariables(tidx).RelevantStimXYZ = allStimXYZ;

    % convenient [3 x 3] numeric matrix when possible
    if nStims == 3 && all(cellfun(@(x) isnumeric(x) && numel(x)==3, allStimXYZ))
        trialVariables(tidx).RelevantStimXYZ_mat = [allStimXYZ{1}; allStimXYZ{2}; allStimXYZ{3}];
    else
        trialVariables(tidx).RelevantStimXYZ_mat = [];
    end
    this_Token_Gain=this_trialDef.TokenRewardsPositive.NumTokens;
    this_Token_Loss=this_trialDef.TokenRewardsNegative.NumTokens;
    
    this_SelectedObjectID=SelectedObjectID{tidx};
    this_SelectedObjectID_idx=str2double(regexp(this_SelectedObjectID,'\d*','Match'));
    
    if isempty(this_SelectedObjectID_idx)
        this_SelectedObjectDimVals=[];
    else
        this_SelectedObjectDimVals=this_RelevantStims(this_SelectedObjectID_idx).StimDimVals;
    end
    if isempty(this_SelectedObjectID_idx)
        this_SelectedObjectXYZ = [];
    else
        % raw location struct
        SL = this_RelevantStims(this_SelectedObjectID_idx).StimLocation;
    
        % parse SL -> [x y z] depending on your schema
        % (fill this in with your actual field names once confirmed)
        this_SelectedObjectXYZ = [SL.x SL.y SL.z];  % example
    end

    trialVariables(tidx).SelectedObjectXYZ = this_SelectedObjectXYZ;
    this_NumDimensions=length(this_SelectedObjectDimVals);
    this_ObjectNumZeroDim=sum(this_SelectedObjectDimVals==0);
    
    this_trialDimensionality=this_NumDimensions-this_ObjectNumZeroDim;

    % -----------End of New Code------------------

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
