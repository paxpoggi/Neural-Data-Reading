%% Compile Data Script - single session data
function [TrialDATA, BlockDATA]  = cgg_singlesession_data_LT3(folder_name, session_file, data_path, Processed_path, Area, MnkID, monkey_name)


%Practice data
% folder_name = 'Fr_EStim_01_21-11-12_009_01';
% session_file = 'Session4__12_11_2021__11_29_57';
% data_path = '/Users/rltreuting/Desktop/Lab/TEBA_Temp/Frey_EStim_01';

%[trialData, blockData] = ProcessSingleSessionData_FLU('exptType','FLU',[data_path filesep folder_name filesep session_file],'Spectrum');


% Check that you are adding new sessions to existing data
newStr = split(folder_name,"_");
session_num = sscanf(newStr{end-1}, '%d');

main_path = [data_path filesep folder_name filesep session_file]; 
% Processed_path = [data_path filesep folder_name filesep session_file]; 

%Load primary session folder
% trialData  = load([main_path filesep 'ProcessedData' filesep 'TrialData.mat']);
% blockData = load([main_path filesep 'ProcessedData' filesep 'BlockData.mat']);
% 
% % Gaze duration on each object - does stimuation affect the length or
% % coverage of the gaze if objects
% frameData = load([main_path filesep 'ProcessedData' filesep 'FrameData.mat']);

%Load primary session folder
trialData  = load([Processed_path filesep 'ProcessedData' filesep 'TrialData.mat']);
trialData = trialData.trialData;
blockData = load([Processed_path filesep 'ProcessedData' filesep 'BlockData.mat']);
blockData = blockData.blockData;

% Gaze duration on each object - does stimuation affect the length or
% coverage of the gaze if objects
frameData = load([Processed_path filesep 'ProcessedData' filesep 'FrameData.mat']);
frameData = frameData.frameData;

switch monkey_name
    case 'Wotan_FLToken_Probe_01'
        % Block feature
        BlkDef_name = dir([main_path filesep 'RuntimeData' filesep 'SessionSettings' filesep 'FDF03*.*']);
        BlkDef_file = BlkDef_name.name;
        BlkDef_file = split(BlkDef_file ,"_");
        %stimulatio setting
        stimulation_setting = BlkDef_file{9};
    case 'Frey_FLToken_Probe_02'
        % Block feature
        BlkDef_name = dir([main_path filesep 'RuntimeData' filesep 'SessionSettings' filesep 'FDF03*.*']);
        BlkDef_file = BlkDef_name.name;
        BlkDef_file = split(BlkDef_file ,"_");
        %stimulatio setting
        stimulation_setting = BlkDef_file{9};

    case 'Frey_FLToken_Probe_03'
        % Block feature
        BlkDef_name = dir([main_path filesep 'RuntimeData' filesep 'SessionSettings' filesep 'FDF03*.*']);
        BlkDef_file = BlkDef_name.name;
        BlkDef_file = split(BlkDef_file ,"_");
        %stimulatio setting
        stimulation_setting = BlkDef_file{9};

    case 'IDED_DBC_AH_AN/VU595_DBC'
        BlkDef_name = dir([main_path filesep 'RuntimeData' filesep 'SessionSettings' filesep 'FL2D*.*']);
        BlkDef_file = BlkDef_name.name;
        BlkDef_file = split(BlkDef_file ,"_");
        %Stimulation setting
        stimulation_setting = 'NONE';

end

%feature target:
if verLessThan('matlab','9.8')
BlkDef_rules = readtable([BlkDef_name.folder filesep BlkDef_name.name], 'HeaderLines', 1);
else
BlkDef_rules = readtable([BlkDef_name.folder filesep BlkDef_name.name], 'ReadVariableNames', false, 'HeaderLines', 1);
end
disp([BlkDef_name.folder filesep BlkDef_name.name])
Var3 = BlkDef_rules.Var3;
relFeat_idx = find(contains(Var3,'ContextNums'));

BlkFeatureTarget = zeros(36,1); % 1-4

for i = 1:36

    relfeatures = Var3(relFeat_idx(i));
    relfeatures = split(relfeatures ,",");

    feats = zeros(4,1);

    feat1 = relfeatures{1};
    feat1(1) = []; 

    feats(1) = str2num(feat1);
    feats(2) = str2num(relfeatures{2});
    feats(3) = str2num(relfeatures{3});
    %not using texture as feature??
    %feats(4) = str2num(relfeatures{4});

    feat4 = relfeatures{5};
    feat4(end) = []; 
    feats(4) = str2num(feat4);

    BlkFeatureTarget(i,:) = find(feats > -1);
end

%stim type
if strcmpi(stimulation_setting, 'SREL')    
    Stim_object = 1; % Rewarded object stim
elseif strcmpi(stimulation_setting,'SIRR')
    Stim_object = 2 ;% Unrewarded object stim
else
    % no stimulation 
    Stim_object = 0;
end


%%%%%%%%%%%%%% Make TrialDATA and BlockDATA struct %%%%%%%%%%%%%%%

% Intial set up
fb=trialData.PositiveFbObtained;
oc=strcmp(fb,'True');
Reactiontime = trialData.SelectObject_Duration;
Stimulation = strcmp(trialData.SonicationPulseSent,'True');
abort_trls = find(trialData.AbortCode ~= 0);
good_trls = find(trialData.AbortCode == 0);
%gazedata = trialData.gaze_data;
%LP_block = trialData.LP;

Stim_pattern = [0 0 0 0 0 0 ...
               1 0 1 0 1 0 ...
               1 0 1 0 1 0 ...
               1 0 1 0 1 0 ...
               1 0 1 0 1 0 ...
               1 0 1 0 1 0]; % 36 blocks total are possible

% Start making BlockDATA struct
BlockDATA.BlockNum = blockData.Block;
Nblk = length(BlockDATA.BlockNum);

BlockDATA.MnkID = MnkID*ones(Nblk,1); %1 = Frey, 2 = ?
BlockDATA.SessionNum = session_num*ones(Nblk,1);
BlockDATA.BlockLabel = blockData.BlockID;
BlockDATA.Dimension = blockData.NumActiveDims; %[1,2,3]
BlockDATA.GainCond = blockData.MeanPositiveTokens; %[2,3]
BlockDATA.LossCond = blockData.MeanNegativeTokens; %[-1,-3]
BlockDATA.StimSession = Stim_object*ones(Nblk,1); %1 = SR+, 2 = SR-
BlockDATA.StimBlockCond = (Stim_pattern(1:Nblk))';
% BlockDATA.Area = Area*ones(Nblk,1); %1 = ACC, 2 = CD
BlockDATA.TargetFeature = BlkFeatureTarget(1:Nblk,1); % 1-4


% Start making TrialDATA struct
TrialDATA.Block = trialData.Block;
Ntrls = length(TrialDATA.Block);

TrialDATA.TrialInExperiment = trialData.TrialInExperiment;
TrialDATA.TrialInBlock = trialData.TrialInBlock;
TrialDATA.SessionNum = session_num*ones(Ntrls,1);
% TrialDATA.Area = Area*ones(Ntrls,1);
TrialDATA.StimSession = Stim_object*ones(Ntrls,1); %1 = SR+, 2 = SR-
TrialDATA.Accuracy = oc;
TrialDATA.RT = Reactiontime;
TrialDATA.Stim = Stimulation;

DimensionVec = zeros(Ntrls,1);
GainCondVec = zeros(Ntrls,1);
LossCondVec = zeros(Ntrls,1);
TokenCondVec = zeros(Ntrls,1);
StimBlockVec = zeros(Ntrls,1);
TargetFeatureVec = zeros(Ntrls,1);

for i = 1:Nblk
    %update Blockdata too
    if BlockDATA.GainCond(i) == 2 & BlockDATA.LossCond(i) == -1
        BlockDATA.TokenCond(i,:) = 1;

    elseif BlockDATA.GainCond(i) == 2 & BlockDATA.LossCond(i) == -3
        BlockDATA.TokenCond(i,:) = 2;

    elseif BlockDATA.GainCond(i) == 3 & BlockDATA.LossCond(i) == -1
        BlockDATA.TokenCond(i,:) = 3;

    elseif BlockDATA.GainCond(i) == 3 & BlockDATA.LossCond(i) == -3
        BlockDATA.TokenCond(i,:) = 4;
    end

    idx = find(TrialDATA.Block == i);

    DimensionVec(idx) = BlockDATA.Dimension(i);
    GainCondVec(idx) = BlockDATA.GainCond(i);
    LossCondVec(idx) = BlockDATA.LossCond(i);
    TokenCondVec(idx) = BlockDATA.TokenCond(i);
    StimBlockVec(idx) = BlockDATA.StimBlockCond(i);
    TargetFeatureVec(idx) = BlockDATA.TargetFeature(i);
end

TrialDATA.iCndDim = DimensionVec;
TrialDATA.GainCond = GainCondVec;
TrialDATA.LossCond = LossCondVec;
TrialDATA.iCndTok = TokenCondVec;
TrialDATA.StimBlockCond = StimBlockVec;
TrialDATA.TargetFeature = TargetFeatureVec;


gaze_data_object = cell(Ntrls,1);
gaze_data_duration = cell(Ntrls,1);

% for i = 0:blocks
%     trlsinblk = max(frame_data.TrialInBlock(find(frame_data.Block == i)));
%     for t = 1:trlsinblk
% 
%         trial_idx = find(frame_data.Block == i & frame_data.TrialInBlock == t);
for t = 1:Ntrls
    place = t;
    trial_idx = find(frameData.TrialCounter == place);

    selectObj_idx = ismember(frameData.TrialEpoch(trial_idx), 'SelectObject');

    if selectObj_idx == 0
        % do nothing
    else
        selectObj_data = zeros(length(trial_idx),2);
        for j = 1:length(trial_idx)
            condition  = selectObj_idx(j);
            idx = trial_idx(j);
        
            if condition == 1
                object_name = frameData.ShotgunGazeHits(idx);
        
                %conditons it could be
    
                Cond_rel1 = ~isempty(strfind(char(object_name),'rel1'));
                Cond_rel2 = ~isempty(strfind(char(object_name),'rel2'));
                Cond_rel3 = ~isempty(strfind(char(object_name),'rel3'));
                Cond_explore = ~isempty(strfind(char(object_name),'ExplorationFloor'));
        
                if Cond_explore == 1
                    object = 4;
                end
    
                if Cond_rel1 == 1
                    object = 1;
                elseif Cond_rel2 == 1
                    object = 2;
                elseif Cond_rel3 == 1
                    object = 3;
                end
        
                selectObj_data(j,1) = frameData.EyetrackerTimeStamp(idx);
                selectObj_data(j,2) = object;
            end
        end
        
        object_change = diff(selectObj_data(:,2));
        object_change_idx = [(find(object_change ~= 0)); length(selectObj_data)]; %add the end for below to work
        
        objectselection = cell(length(object_change_idx),2);
        place = 1;
        for k = 1:length(object_change_idx)
            
            idx = object_change_idx(k);
        
            object = selectObj_data(place,2);
    
            if object > 0
                duration = (selectObj_data(idx,1) - selectObj_data(place,1))/1000000 + 0.016666666; %adding a frame
            else
                duration = (selectObj_data(idx,1) - selectObj_data(place,1))/1000000;
            end
        
            place = idx+1;
      
        
            objectselection{k,1} = object;
            objectselection{k,2} = duration;
        end
    
        % correct the gaze for selection
    
    %         s = struct; % make a struct
    %         s.object = objectselection(:,1);
    %         s.duration = objectselection(:,2);
    
        %gaze_data{t,:} = objectselection;
        gaze_data_object{t,:} = objectselection(:,1);
        gaze_data_duration{t,:} = objectselection(:,2);

    end
end

TrialDATA.GazeObjectsType = gaze_data_object;
TrialDATA.GazeObjectsDuration = gaze_data_duration;


% ExplObjTime : Time of exploring objects prior to final selection with 4
% ExplObjNum : Number of exploring objects prior to final selection
% ExplObjTime_no4 : Time of exploring objects prior to final selection without 4


%keep good cleans, not the abort trials
% TrialDATA = structfun(@(x) x(good_trls), TrialDATA, 'UniformOutput', false);


Ntrls = length(good_trls);

%added 11/2/22
ExplObjdurationVec = zeros(Ntrls,1);
ExplObjNumVec = zeros(Ntrls,1);
ExplObjduration_no4Vec = zeros(Ntrls,1);

% Gaze data details
for i = 1:Ntrls
    trlgaze_object = cell2mat(TrialDATA.GazeObjectsType{i});
    trlgaze_duration = cell2mat(TrialDATA.GazeObjectsDuration{i});

    % remove 0s
    trlgaze_object(trlgaze_object == 0) = [];
    trlgaze_duration(trlgaze_duration == 0) = [];

    ExplObjdurationVec(i) = sum(trlgaze_duration(1:end-1));

    %remove final fixation
    if ~isempty(trlgaze_object)||~isempty(trlgaze_duration)
    trlgaze_object(end) = [];
    trlgaze_duration(end) = [];
    
    % not 4
    Obj_ind = find(trlgaze_object <= 3);
    
    ExplObjNumVec(i) = length(Obj_ind);
    ExplObjduration_no4Vec(i) = sum(trlgaze_duration(Obj_ind));
    else
    ExplObjNumVec(i)=NaN;
    ExplObjduration_no4Vec(i)=NaN;
    end


end

TrialDATA.ExplObjduration = ExplObjdurationVec;
TrialDATA.ExplObjNum = ExplObjNumVec;
TrialDATA.ExplObjduration_no4 = ExplObjduration_no4Vec;

% Final dataset: TrialDATA, BlockDATA

end


