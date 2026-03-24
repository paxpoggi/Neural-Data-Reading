function [P_Value,R_Value,P_Value_Coefficients,CoefficientNames,R_Value_Adjusted,B_Value_Coefficients,R_Correlation,P_Correlation,Mean_Value] = ...
    cgg_procTrialVariableRegression(InData,MatchArray,InIncrement)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

NaNIDX = any(isnan(MatchArray),2);
NotNaNIDX = ~NaNIDX;

this_FitaData=InData(:,:,NotNaNIDX);
this_MatchArray = MatchArray(NotNaNIDX,:);

[NumChannels,NumSamplesData,NumData]=size(this_FitaData);

[~,NumMatchArray]=size(this_MatchArray);
%% Debugging assert statements
assert(size(this_MatchArray,1)==NumData,...
    'Rows mismatch: trials in data (%d) vs predictors (%d).', NumData, size(this_MatchArray,1));
assert(isfinite(InIncrement) && InIncrement >= 1, 'Bad InIncrement: %g', InIncrement);
%%
NumParameters=NaN(NumMatchArray,1);
IsCategorical=true(NumMatchArray,1);

CategoricalFraction = NumData*0.05;

for midx=1:NumMatchArray
    this_NumParameters = length(unique(this_MatchArray(:,midx)));
    if CategoricalFraction < this_NumParameters
        NumParameters(midx) = 1;
        IsCategorical(midx) = false;
    else
        NumParameters(midx)=this_NumParameters-any(isnan(this_MatchArray(:,midx)));
    end
end

TotalParameters=sum(NumParameters)-NumMatchArray+1;
if any(~IsCategorical)
TotalParameters = TotalParameters + 1; % Intercept
end

Regress_Period=1;
Increment_Amount=InIncrement;
Increment_Values=1:Increment_Amount:NumSamplesData;
NumIncrements=length(Increment_Values);
%%
P_Value=NaN(NumChannels,NumIncrements,1);
R_Value=NaN(NumChannels,NumIncrements,1);
R_Value_Adjusted=NaN(NumChannels,NumIncrements,1);
P_Value_Coefficients=NaN(NumChannels,NumIncrements,TotalParameters);
B_Value_Coefficients=NaN(NumChannels,NumIncrements,TotalParameters);
R_Correlation=NaN(NumChannels,NumIncrements,NumMatchArray);
P_Correlation=NaN(NumChannels,NumIncrements,NumMatchArray);
Mean_Value=NaN(NumChannels,NumIncrements,1);
% P_Value_Coefficients=NaN(NumChannels,NumIncrements,NumMatchArray+2);
%% Update Information Setup

% Setting up the DataQueue to receive messages during the parfor loop and
% have it run the update function
q = parallel.pool.DataQueue;
afterEach(q, @nUpdateWaitbar);
gcp;

% Set the number of iterations for the loop.
% Change the value of All_Iterations to the total number of iterations for
% the proper progress update. Change this for specific uses
%                VVVVVVV
All_Iterations = NumIncrements*NumChannels; %<<<<<<<<<
%                ^^^^^^^
% Iteration count starts at 0... seems self explanatory ¯\_(ツ)_/¯
Iteration_Count = 0;
% Initialize the time elapsed and remaining
Elapsed_Time=seconds(0); Elapsed_Time.Format='hh:mm:ss';
Remaining_Time=seconds(0); Remaining_Time.Format='hh:mm:ss';
Current_Day=datetime('now','TimeZone','local','Format','MMM-d');
Current_Time=datetime('now','TimeZone','local','Format','HH:mm:ss');

% This is the format specification for the message that is displayed.
% Change this to get a different message displayed. The % at the end is 4
% since sprintf and fprintf takes the 4 to 2 to 1. Use 4 if you want to
% display a percent sign otherwise remove them (!!! if removed the delete
% message should no longer be '-1' at the end but '-0'. '\n' is 
%            VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
formatSpec = '*** Current [%s at %s] Trial Variable Regression Progress is: %.2f%%%%\n*** Time Elapsed: %s, Estimated Time Remaining: %s\n'; %<<<<<
%            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

% Get the message with the specified percent
Current_Message=sprintf(formatSpec,Current_Day,Current_Time,0,Elapsed_Time,'N/A');
% Display the message
fprintf(Current_Message);
tic
%%

try
this_FitaData_Constant = parallel.pool.Constant(this_FitaData);
catch
this_FitaData_Constant = this_FitaData;
end
%% removed parfor and just use for to debug
fprintf('Reg: Channels=%d, Samples=%d, Trials=%d, Predictors=%d, Increments=%d\n', ...
    NumChannels, NumSamplesData, NumData, NumMatchArray, NumIncrements);
for sidx=1:NumIncrements
 %%   
    this_sidx=Increment_Values(sidx);
     
    this_DataSection_Start = this_sidx - floor(Regress_Period/2);
    this_DataSection_End=this_sidx+floor(Regress_Period/2)-(rem(Regress_Period, 2) == 0);

    if this_DataSection_Start<1
        this_DataSection_Start=1;
    end
    if this_DataSection_End>NumSamplesData
        this_DataSection_End=NumSamplesData;
    end
    
    this_DataSection=this_DataSection_Start:this_DataSection_End;
    
    if isa(this_FitaData_Constant,'parallel.pool.Constant')
       FitData_sel = this_FitaData_Constant.Value(:, this_sidx,:);
    else
        FitData_sel = this_FitaData_Constant(:,this_sidx,:);
    end
    % FitData_sel=this_FitaData(:,this_DataSection,:);
    %FitData_sel=this_FitaData_Constant.Value(:,this_DataSection,:);
    
    % no need for mean if regression_period = 1 
    %FitData_sel=mean(FitData_sel,2);
    
    FitData_sel=reshape(FitData_sel,NumChannels,NumData); % [C x T]
    
    %%
    for cidx=1:NumChannels
        %%
        this_Channel=cidx;
        % edit that uses simple reshape instad of diag(diag( to save space. 
        FitData_sel_channel = FitData_sel(this_Channel,:).';
        %FitData_sel_channel = FitData_sel(this_Channel,:).';
        %FitData_sel_channel=diag(diag(FitData_sel(this_Channel,:)));
        
        % Data_Table=table(MatchArray,FitData_sel_channel,'VariableNames',{'Predictor','Y'});
        % Data_Table.Predictor = nominal(Data_Table.Predictor);
        % Data_Table=splitvars(Data_Table);
        % mdl_lme = fitlme(Data_Table,'Y ~ 1 + Predictor_1 + Predictor_2 + Predictor_3');
        % mdl_lme_Full = fitlme(Data_Table,'Y ~ -1 + Predictor_1 + Predictor_2 + Predictor_3','DummyVarCoding','full');
        % mdl_lme_Full = fitlme(Data_Table,'Y ~ -1 + Predictor','DummyVarCoding','full');
        % mdl_lme = fitlme(Data_Table,'Y ~ 1 + Predictor');
        % mdl_lm_Full = fitlm(Data_Table,'Y ~ 1 + Predictor','DummyVarCoding','full');
        % X must have one row per trial; y must have same length
        assert(size(this_MatchArray,1) == NumData, ...
            'Predictor rows (%d) != NumData (%d).', size(this_MatchArray,1), NumData);
        
        assert(isvector(FitData_sel_channel) && numel(FitData_sel_channel) == NumData, ...
            'Response length (%d) != NumData (%d) at sidx=%d, cidx=%d.', ...
            numel(FitData_sel_channel), NumData, sidx, cidx);
        
        % Optional: ensure numeric
        assert(isnumeric(FitData_sel_channel), 'Response is %s, expected numeric.', class(FitData_sel_channel));
        this_Mean = 0;
        if NumMatchArray>1 || any(~IsCategorical)
            mdl = fitlm(this_MatchArray,FitData_sel_channel,'CategoricalVars',IsCategorical);
        else
            this_Mean = mean(FitData_sel_channel);
            % mdl = fitlm(this_MatchArray,FitData_sel_channel - this_Mean,'CategoricalVars',IsCategorical,'Intercept',false,'DummyVarCoding','full');
            mdl = fitlm(this_MatchArray,FitData_sel_channel,'CategoricalVars',IsCategorical,'Intercept',false,'DummyVarCoding','full');
            % mdl = fitlm(MatchArray,FitData_sel_channel,'CategoricalVars',1:NumMatchArray,'Intercept',false,'DummyVarCoding','full');
            %     mdl_lm_Full = fitlm(Data_Table,'Y ~ -1 + Predictor','DummyVarCoding','full');
        %     mdl_lm_Full_tmp = fitlm(MatchArray,FitData_sel_channel,'y ~ -1 + x1','DummyVarCoding','full','CategoricalVars',1:NumMatchArray);
        end
        %%
        mdl_summary=anova(mdl,'summary');
        % mdl_partial=partialDependence(mdl,1);
        % aaa=sum(mdl_partial);
        
        P_Value_Coefficients(cidx,sidx,:)=mdl.Coefficients.pValue;
        B_Value_Coefficients(cidx,sidx,:)=mdl.Coefficients.Estimate;
        
        P_Value(cidx,sidx)=mdl_summary{"Model","pValue"};
        
        R_Value(cidx,sidx)=mdl.Rsquared.Ordinary;
        R_Value_Adjusted(cidx,sidx)=mdl.Rsquared.Adjusted;
        
        Mean_Value(cidx,sidx) = this_Mean;
        
        %% Correlation
        
        %this_CorrelationMatrix = [FitData_sel_channel,this_MatchArray];
        %[this_R_Correlation,this_P_Correlation] = corrcoef(this_CorrelationMatrix);
        %R_Correlation(cidx,sidx,:) = this_R_Correlation(2:end,1);
        %P_Correlation(cidx,sidx,:) = this_P_Correlation(2:end,1);
        [r_corr,p_corr] = corr(this_MatchArray, FitData_sel_channel, "rows",'pairwise');
        R_Correlation(cidx,sidx,:) = r_corr(:);
        P_Correlation(cidx,sidx,:) = p_corr(:);
        %%
        send(q, sidx);
    end
    
 end
    % edit that also reshapes instead of using diag(diag( to prevent memory
    % blowup
    Data_tmp = squeeze(mean(this_FitaData(:,1,:), 2));
    Data_tmp = Data_tmp(1,:).';
    %Data_tmp=this_FitaData(:,1,:);
    %Data_tmp=mean(Data_tmp,2);
    %Data_tmp=squeeze(Data_tmp);
    %Data_tmp=diag(diag(Data_tmp(1,:)));
    if NumMatchArray>1 || any(~IsCategorical)
        mdl = fitlm(this_MatchArray,Data_tmp,'CategoricalVars',IsCategorical);
    else
        mdl = fitlm(this_MatchArray,Data_tmp,'CategoricalVars',IsCategorical,'Intercept',false,'DummyVarCoding','full');
    end
    CoefficientNames=mdl.CoefficientNames;
    
    %% SubFunctions
    
    % Function for displaying an update for a parfor loop. Not able to do as
    % simply as with a regular for loop
    function nUpdateWaitbar(~)
        % Update global iteration count
        Iteration_Count = Iteration_Count + 1;
        % Get percentage for progress
        Current_Progress=Iteration_Count/All_Iterations*100;
        % Get the amount of time that has passed and how much remains
        Elapsed_Time=seconds(toc); Elapsed_Time.Format='hh:mm:ss';
        Remaining_Time=Elapsed_Time/Current_Progress*(100-Current_Progress);
        Remaining_Time.Format='hh:mm:ss';
        Current_Day=datetime('now','TimeZone','local','Format','MMM-d');
        Current_Time=datetime('now','TimeZone','local','Format','HH:mm:ss');
        % Generate deletion message to remove previous progress update. The
        % '-1' comes from fprintf converting the two %% to one % so the
        % original message is one character longer than what needs to be
        % deleted.
        Delete_Message=repmat(sprintf('\b'),1,length(Current_Message)-1);
        % Generate the update message using the formate specification
        % constructed earlier
        Current_Message=sprintf(formatSpec,Current_Day,Current_Time,...
            Current_Progress,Elapsed_Time,Remaining_Time);
        % Display the update message
        fprintf([Delete_Message,Current_Message]);
    end


end

