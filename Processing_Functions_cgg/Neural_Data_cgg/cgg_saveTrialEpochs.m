function SizeIssue = cgg_saveTrialEpochs(Input,Probe_Area,trialVariables,Epoch,Probe_Order,cfg,cfg_param)
%CGG_SAVETRIALEPOCHS Summary of this function goes here
%   Detailed explanation goes here

%%

NumProbes=length(Probe_Order);

tmp_ProbeNumber=1:NumProbes;

this_ProbeNumber=strcmp(Probe_Order,Probe_Area);
this_ProbeNumber=tmp_ProbeNumber(this_ProbeNumber);

IsProbeProcessed = cgg_checkProbeProcessed(Probe_Area,cfg);

%%

DataDir=cfg.outdatadir.Experiment.Session.Epoched_Data.Epoch.Data.path;
TargetDir=cfg.outdatadir.Experiment.Session.Epoched_Data.Epoch.Target.path;
ProcessingDir=cfg.outdatadir.Experiment.Session.Epoched_Data.Epoch.Processing.path;

Data_SaveName='%s_Data_%06d.mat';
Target_SaveName='Target_Information.mat';
ProbeProcessing_SaveName='Probe_Processing_Information.mat';
ParameterProcessing_SaveName='Parameters_Processing.yaml';
SessionProcessing_SaveName='Session_Processing_Information.mat';

Data_SaveNameFull=[DataDir filesep Data_SaveName];
Target_SaveNameFull=[TargetDir filesep Target_SaveName];
ProbeProcessing_SaveNameFull=[ProcessingDir filesep ProbeProcessing_SaveName];
ParameterProcessing_SaveNameFull=[ProcessingDir filesep ParameterProcessing_SaveName];

%%

isDataCell=iscell(Input(2).Trials);
isDataNumeric=isnumeric(Input(2).Trials);

if isDataCell
    NumData=length(Input(2).Trials);
elseif isDataNumeric
    [~,~,NumData]=size(Input(2).Trials);
else
    warning('DataType:unrecognized','Input Data is an unrecognized class');
end

TrialNumbers=Input(2).TrialNumber;

[~,ChosenTrial]=unique(TrialNumbers,'last');

TrialChosen=false(1,NumData);
TrialChosen(ChosenTrial)=true;
TrialChosen=num2cell(TrialChosen);

% [NumChannels,NumSamples,NumData]=size(Input(2).Trials);

Disconnected_Channels=Input(3).Connected_Channels;
NotSignificant_Channels=Input(3).Significant_Channels;

%%

[cfg_Session] = DATA_cggAllSessionInformationConfiguration;

ResultsDir=cfg_Session(1).outdatadir;

Folder='Variables';
SubFolder='Connected';

[cfg_Common] = cgg_generateSessionAggregationFolders(...
                'TargetDir',ResultsDir,'Folder',Folder,...
                'SubFolder',SubFolder);

ClusteringDir=cfg_Common.TargetDir.Aggregate_Data.Folder.SubFolder.path;

CommonNameExt='CommonBadChannels.mat';
CommonPathNameExt=[ClusteringDir filesep CommonNameExt];

CommonDisconnectedChannels=[];
if exist(CommonPathNameExt, 'file')
    info = whos('-file', CommonPathNameExt);
    if any(strcmp({info.name},'CommonBadChannels'))
        m_CommonClustering = matfile(CommonPathNameExt,"Writable",false);
        CommonDisconnectedChannels = m_CommonClustering.CommonDisconnectedChannels;
    else
        warning('CommonBadChannels:missingVar',...
            ['File exists but variable "CommonDisconnectedChannels" not found: %s.\n'...
            'Proceeding with no common bad channels'], CommonPathNameExt);
    end
else
    warning('CommonBadChannels:notFound',...
        ['Common bad file channel not found: %s.\n'...
        'Proceding with no common bad channels'], CommonPathNameExt);
end

assert(isvector(CommonDisconnectedChannels) || isempty(CommonDisconnectedChannels), ...
    'CommonDisconnectedChannels must be a vector of channel indices or empty.');
assert(isvector(Disconnected_Channels), 'Disconnected_Channels must be a vector of channel indices.');
assert(isvector(NotSignificant_Channels), 'NotSignificant_Channels must be a vector of channel indices.');
%m_CommonClustering=matfile(CommonPathNameExt,"Writable",false);
%CommonDisconnectedChannels=m_CommonClustering.CommonDisconnectedChannels;

    
%%
Target_IDX = NaN(1,NumData);
SizeIssue=false;

%% Update Information Setup

q = parallel.pool.DataQueue;
afterEach(q, @nUpdateWaitbar);

All_Iterations = NumData;
Iteration_Count = 0;

formatSpec = '*** Current Epoch Saving Progress is: %.2f%%%%\n';
Current_Message=sprintf(formatSpec,0);
% disp(Current_Message);
fprintf(Current_Message);

%%

for didx=1:NumData
    this_TrialNumber=TrialNumbers(didx);
%     disp(this_TrialNumber);
    if isDataCell
    this_Data=Input(2).Trials{didx};
    else
    this_Data=Input(2).Trials(:,:,didx);
    end
    this_Data_SaveName=sprintf(Data_SaveNameFull,Epoch,didx);
    
    this_Data(Disconnected_Channels,:)=NaN;
    this_Data(NotSignificant_Channels,:)=NaN;
    this_Data(CommonDisconnectedChannels,:)=[];

    [this_NumChannels,this_NumSamples]=size(this_Data);
    
    this_trialVariablesNumber=find([trialVariables.TrialNumber]==this_TrialNumber);
    
    if ~(exist(this_Data_SaveName,'file'))
        m = matfile(this_Data_SaveName,'Writable',true);
        m.Data=NaN(this_NumChannels,this_NumSamples,NumProbes);
        
    elseif ~(exist(ProbeProcessing_SaveNameFull,'file'))
        m = matfile(this_Data_SaveName,'Writable',true);
        m.Data=NaN(this_NumChannels,this_NumSamples,NumProbes);
        
    else
        m = matfile(this_Data_SaveName,'Writable',true);
        [this_DataNumChannels,this_DataNumSamples,this_DataNumProbes]=size(m.Data);
        if (~isequal(this_DataNumChannels,this_NumChannels))||...
                (~isequal(this_DataNumSamples,this_NumSamples))||...
                (~isequal(this_DataNumProbes,NumProbes))
               warning('DataNumbers:incorrectsize',...
       ['Size of the saved epoch (%d %d %d) does not match the size of '...
       'the epoch for this probe area (%d %d %d) for area: %s.' ...
       'Rewriting saved epoch to all NaN and setting probe processing '...
       'to false'],this_DataNumChannels,this_DataNumSamples,...
       this_DataNumProbes,this_NumChannels,this_NumSamples,NumProbes,...
       Probe_Area);
   
       m.Data=NaN(this_NumChannels,this_NumSamples,NumProbes);
       SizeIssue=true;
       end
    end
    
    m.Data(:,:,this_ProbeNumber)=this_Data;
    Target_IDX(didx)=this_trialVariablesNumber;
    
    send(q, didx);
end

%% Save the Target Information for Decoding

Target=trialVariables(Target_IDX);
[Target.TrialChosen]=TrialChosen{:};

    if ~(exist(Target_SaveNameFull,'file'))
        m_Target = matfile(Target_SaveNameFull,'Writable',true);
        m_Target.Target=Target;
    end
    
%% Save the Probe Processing Information
% This will identify which probes have been processed and do not need to be
% reprocessed. Can also be used to indicate a probe should be reprocessed
% if the value is set to false.
    
    if exist(ProbeProcessing_SaveNameFull,'file')
        m_Probe = matfile(ProbeProcessing_SaveNameFull,'Writable',true);
        ProbeProcessing=m_Probe.ProbeProcessing;
    else
        ProbeProcessing=struct();
        for pidx=1:NumProbes
        ProbeProcessing.(Probe_Order{pidx})=false;
        end
    end
    
    ProbeProcessing.(Probe_Area)=true;
    
    m_Probe = matfile(ProbeProcessing_SaveNameFull,'Writable',true);
    m_Probe.ProbeProcessing=ProbeProcessing;
    
    if SizeIssue
        for pidx=1:NumProbes
        ProbeProcessing.(Probe_Order{pidx})=false;
        end
    m_Probe = matfile(ProbeProcessing_SaveNameFull,'Writable',true);
    m_Probe.ProbeProcessing=ProbeProcessing;
    end

% Save Session Processing Parameters
% make sure cfg_param is yaml safe
cfg_param_yaml = yaml_sanitize(cfg_param);
WriteYaml(ParameterProcessing_SaveNameFull, cfg_param_yaml);
    
    
function nUpdateWaitbar(~)
    Iteration_Count = Iteration_Count + 1;
    Current_Progress=Iteration_Count/All_Iterations*100;
%     Delete_Message=repmat('\b',1,length(Current_Message)+1);
    Delete_Message=repmat(sprintf('\b'),1,length(Current_Message)-1);
%     fprintf(Delete_Message);
    Current_Message=sprintf(formatSpec,Current_Progress);
%     disp(Current_Message);
    fprintf([Delete_Message,Current_Message]);
end

end

