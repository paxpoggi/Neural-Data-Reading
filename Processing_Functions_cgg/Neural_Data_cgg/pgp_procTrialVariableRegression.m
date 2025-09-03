function [P_Value,R_Value,P_Value_Coefficients,CoefficientNames, ...
          R_Value_Adjusted,B_Value_Coefficients,R_Correlation,P_Correlation,Mean_Value] = ...
    pgp_procTrialVariableRegression(InData,MatchArray,InIncrement)
% Trial-variable regression with parfor-safe I/O:
% - Stages InData to a -v7.3 MATFILE so parfor workers DON'T broadcast
% - Reads one time index (column) per increment across kept trials
% - Avoids diag/diag and corrcoef (uses transpose and corr)

    %% Filter out trials with any NaNs in predictors
    NaNIDX     = any(isnan(MatchArray),2);
    NotNaNIDX  = ~NaNIDX;
    trial_idx  = find(NotNaNIDX);         % numeric trial indices (for matfile indexing)
    NumData    = numel(trial_idx);        % # kept trials

    % Shapes from original InData BEFORE staging
    [NumChannels, NumSamplesData, ~] = size(InData);

    % Slice predictors once (small)
    this_MatchArray = MatchArray(trial_idx,:);
    [~, NumMatchArray] = size(this_MatchArray);

    %% Predictor meta (categorical detection & parameter count)
    NumParameters  = NaN(NumMatchArray,1);
    IsCategorical  = true(NumMatchArray,1);
    CategoricalFraction = max(1, round(NumData*0.05));  % heuristic threshold

    for midx = 1:NumMatchArray
        uvals = unique(this_MatchArray(:,midx));
        this_NumParameters = numel(uvals);
        if this_NumParameters > CategoricalFraction
            % treat as continuous
            NumParameters(midx) = 1;
            IsCategorical(midx) = false;
        else
            % categorical: number of levels (exclude NaN)
            NumParameters(midx) = this_NumParameters - any(isnan(uvals));
        end
    end

    TotalParameters = sum(NumParameters) - NumMatchArray + 1;
    if any(~IsCategorical)
        TotalParameters = TotalParameters + 1; % Intercept when any continuous predictors present
    end

    %% Increments along the time dimension
    assert(isfinite(InIncrement) && InIncrement >= 1, 'Bad InIncrement: %g', InIncrement);
    Regress_Period   = 1;  %#ok<NASGU>  % kept for API parity; we slice a single sample per increment
    Increment_Amount = InIncrement;
    Increment_Values = 1:Increment_Amount:NumSamplesData;
    NumIncrements    = numel(Increment_Values);

    assert(size(this_MatchArray,1) == NumData, ...
        'Predictor rows (%d) != NumData (%d).', size(this_MatchArray,1), NumData);

    %% Preallocate outputs (double for compatibility downstream)
    P_Value              = nan(NumChannels,NumIncrements,1);
    R_Value              = nan(NumChannels,NumIncrements,1);
    R_Value_Adjusted     = nan(NumChannels,NumIncrements,1);
    P_Value_Coefficients = nan(NumChannels,NumIncrements,TotalParameters);
    B_Value_Coefficients = nan(NumChannels,NumIncrements,TotalParameters);
    R_Correlation        = nan(NumChannels,NumIncrements,NumMatchArray);
    P_Correlation        = nan(NumChannels,NumIncrements,NumMatchArray);
    Mean_Value           = nan(NumChannels,NumIncrements,1);

    %% Progress setup (one tick per increment)
    q = parallel.pool.DataQueue;
    afterEach(q, @nUpdateWaitbar);

    All_Iterations = NumIncrements;  % progress by increment
    Iteration_Count = 0;
    Elapsed_Time = seconds(0); Elapsed_Time.Format = 'hh:mm:ss';
    Remaining_Time = seconds(0); Remaining_Time.Format = 'hh:mm:ss';
    Current_Day  = datetime('now','TimeZone','local','Format','MMM-d');
    Current_Time = datetime('now','TimeZone','local','Format','HH:mm:ss');
    formatSpec = ['*** Current [%s at %s] Trial Variable Regression Progress is: %.2f%%%%\n' ...
                  '*** Time Elapsed: %s, Estimated Time Remaining: %s\n'];
    Current_Message = sprintf(formatSpec,Current_Day,Current_Time,0,Elapsed_Time,'N/A');
    fprintf(Current_Message);
    tic;

    %% ----- Stage InData to MATFILE (avoid parfor broadcast) -----
    tmpRegPath = fullfile(tempdir, ['InData_tmp_regression_' char(java.util.UUID.randomUUID) '.mat']);
    InData_mem = InData; %#ok<NASGU>
    save(tmpRegPath, 'InData_mem', '-v7.3');  % HDF5-backed partial reads
    InData = [];                              % free RAM
    InData_m = matfile(tmpRegPath, 'Writable', false);

    fprintf('Reg: Channels=%d, Samples=%d, TrialsKept=%d, Predictors=%d, Increments=%d\n', ...
        NumChannels, NumSamplesData, NumData, NumMatchArray, NumIncrements);

    %%Optional uncomment to limit workers to 12
    %p = gcp('nocreate');
   % if isempty(p) || p.numworkers>12
     %   if ~isempty(p), delete(p); end
      %  parpool('local',12);
   % end



    %% ----- Main loop: parfor over increments -----
    parfor sidx = 1:NumIncrements
        this_sidx = Increment_Values(sidx);

        % Read exactly one time sample for the kept trials: [C x 1 x NumData] -> [C x NumData]
        slice = InData_m.InData_mem(:, this_sidx, trial_idx);
        FitData_sel = reshape(slice, NumChannels, NumData);

        % Loop channels
        for cidx = 1:NumChannels
            y = FitData_sel(cidx,:).';   % [NumData x 1] response

            this_Mean = 0;
            if NumMatchArray > 1 || any(~IsCategorical)
                mdl = fitlm(this_MatchArray, y, 'CategoricalVars', IsCategorical);
            else
                this_Mean = mean(y);
                mdl = fitlm(this_MatchArray, y, 'CategoricalVars', IsCategorical, ...
                            'Intercept', false, 'DummyVarCoding', 'full');
            end

            mdl_summary = anova(mdl, 'summary');

            % Write into sliced outputs along 2nd dim (sidx) — parfor-friendly
            P_Value_Coefficients(cidx,sidx,:) = mdl.Coefficients.pValue;
            B_Value_Coefficients(cidx,sidx,:) = mdl.Coefficients.Estimate;

            P_Value(cidx,sidx)          = mdl_summary{"Model","pValue"};
            R_Value(cidx,sidx)          = mdl.Rsquared.Ordinary;
            R_Value_Adjusted(cidx,sidx) = mdl.Rsquared.Adjusted;
            Mean_Value(cidx,sidx)       = this_Mean;

            % Lean correlation (no full corrcoef)
            [rc, pc] = corr(this_MatchArray, y, 'Rows','pairwise');
            R_Correlation(cidx,sidx,:) = rc(:);
            P_Correlation(cidx,sidx,:) = pc(:);
        end

        % progress: once per increment
        send(q, sidx);
    end

    %% Coefficient names (sample once, small)
    sample_col  = 1;
    if NumData >= 1 && sample_col <= NumSamplesData
        sample_slice = InData_m.InData_mem(:, sample_col, trial_idx);
        sample_sel   = reshape(sample_slice, NumChannels, NumData);
        y0 = sample_sel(1,:).';   % one channel

        if NumMatchArray > 1 || any(~IsCategorical)
            mdl0 = fitlm(this_MatchArray, y0, 'CategoricalVars', IsCategorical);
        else
            mdl0 = fitlm(this_MatchArray, y0, 'CategoricalVars', IsCategorical, ...
                         'Intercept', false, 'DummyVarCoding', 'full');
        end
        CoefficientNames = mdl0.CoefficientNames;
    else
        CoefficientNames = strings(0,1);
    end

    % (Optional) cleanup temp file
    try, delete(tmpRegPath); catch, end

    %% ---- nested progress updater (parfor-safe) ----
    function nUpdateWaitbar(~)
        Iteration_Count = Iteration_Count + 1;
        Current_Progress = Iteration_Count/All_Iterations*100;
        Elapsed_Time = seconds(toc); Elapsed_Time.Format = 'hh:mm:ss';
        if Current_Progress > 0
            Remaining_Time = Elapsed_Time/Current_Progress*(100-Current_Progress);
        else
            Remaining_Time = seconds(0);
        end
        Remaining_Time.Format = 'hh:mm:ss';
        Current_Day  = datetime('now','TimeZone','local','Format','MMM-d');
        Current_Time = datetime('now','TimeZone','local','Format','HH:mm:ss');
        Delete_Message = repmat(sprintf('\b'),1,length(Current_Message)-1);
        Current_Message = sprintf(formatSpec, Current_Day, Current_Time, ...
                                  Current_Progress, Elapsed_Time, Remaining_Time);
        fprintf([Delete_Message, Current_Message]);
    end
end