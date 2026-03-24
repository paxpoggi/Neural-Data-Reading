function [Significant_Channels,NotSignificant_Channels] = cgg_procChannelSelectionFromRegression(InData,trialVariables,SamplingFrequency,Regression_SP,TrialNumbers,Significance_Value,Minimum_Length,GainValue,LossValue,cfg,varargin)
%CGG_PROCCHANNELSELECTIONFROMREGRESSION Summary of this function goes here
%   Regression_SP Regression Sampling Period in ms

this_area_regression_file_name=...
    [cfg.outdatadir.Experiment.Session.Regression.Area.path ...
    filesep 'Regression_Results.mat'];

want_rerun = CheckVararginPairs('want_rerun', false, varargin{:});

%%
if want_rerun || ~(exist(this_area_regression_file_name,'file'))

Connected_Channels = CheckVararginPairs('Connected_Channels', NaN, varargin{:});

%%
if iscell(InData)
    InData=cat(3,InData{:});
end

[NumChannels,~]=size(InData);

Sampling_Period_Data=1/SamplingFrequency*1000; %Get the sampling period in ms

InIncrement=round(Regression_SP/Sampling_Period_Data);

Minimum_Length_Data_Samples=round(Minimum_Length/Regression_SP);
% no need to divide by Sampling_Period_Data again, both min length and
% regression SP are in ms already
%Minimum_Length_Data_Samples=round(Minimum_Length/Sampling_Period_Data/Regression_SP);

[Data_Fit,MatchArray_Fit] = cgg_getRegressionInputs(InData,TrialNumbers,trialVariables,GainValue,LossValue,varargin{:});

%%
[P_Value,R_Value,P_Value_Coefficients,CoefficientNames] = pgp_procTrialVariableRegression(Data_Fit,MatchArray_Fit,InIncrement);
%%
[this_Data] = cgg_procSignificanceOverChannels(P_Value,Significance_Value,Minimum_Length_Data_Samples);

this_Data=this_Data*1;

All_Channels=1:NumChannels;

    if ~any(isnan(Connected_Channels))
        Disconnected_Channels=1:NumChannels;
        Disconnected_Channels(Connected_Channels)=[];
        this_Data(Disconnected_Channels,:)=NaN;
    end

    
    is_Channel_Significant=any(this_Data,2);
    
    Significant_Channels=All_Channels(is_Channel_Significant);
    NotSignificant_Channels=intersect(All_Channels(~is_Channel_Significant),Connected_Channels);
    
m_Regression = matfile(this_area_regression_file_name,'Writable',true);
m_Regression.Significant_Channels=Significant_Channels;
m_Regression.NotSignificant_Channels=NotSignificant_Channels; 
m_Regression.P_Value=P_Value; 
m_Regression.R_Value=R_Value; 
m_Regression.P_Value_Coefficients=P_Value_Coefficients; 
m_Regression.CoefficientNames=CoefficientNames;
m_Regression.CriteriaArray=this_Data; 

else
m_Regression = matfile(this_area_regression_file_name,'Writable',true);
Significant_Channels=m_Regression.Significant_Channels;
NotSignificant_Channels=m_Regression.NotSignificant_Channels; 
    
end
end

