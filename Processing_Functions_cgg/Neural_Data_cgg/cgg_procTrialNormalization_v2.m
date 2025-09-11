function [Mean_Norm_InData,Mean_Norm_InBaseline,...
    STD_ERROR_Norm_InData,STD_ERROR_Norm_InBaseline,Norm_InData,...
    Norm_InBaseline] = cgg_procTrialNormalization_v2(InData,...
    InBaseline,FullBaseline,TrialNumbers_Data,TrialNumbers_Baseline,...
    TrialNumbers_FullBaseline,do_zscore)
%CGG_PROCTRIALNORMALIZATION Summary of this function goes here
%   Detailed explanation goes here
assert(islogical(do_zscore) && isscalar(do_zscore), ...
    'do_zscore must be a logical scalar (true/false).');

IsCell_Data=iscell(InData);
IsCell_Baseline=iscell(InBaseline);
IsCell_FullBaseline=iscell(FullBaseline);

% [NumChannels,NumSamples,Trial_Counter]=size(InData);
if IsCell_Data
    [Trial_Counter_Data,~]=size(InData);
    Norm_InData=cell(size(InData));
else
    [~,~,Trial_Counter_Data]=size(InData);
end
if IsCell_Baseline
    [Trial_Counter_Baseline,~]=size(InBaseline);
    Norm_InBaseline=cell(size(InBaseline));
else
    [~,~,Trial_Counter_Baseline]=size(InBaseline);
end

if IsCell_FullBaseline
    Mean_FullBaseline=cell2mat((cellfun(@(x) mean(x,2),FullBaseline,'UniformOutput',false))');
    STD_FullBaseline=cell2mat((cellfun(@(x) std(x,0,2),FullBaseline,'UniformOutput',false))');
else
    if verLessThan('matlab','9.5')
    Mean_FullBaseline=mean(FullBaseline(:,:),2);
    STD_FullBaseline=std(FullBaseline(:,:),0,2);
    else
    Mean_FullBaseline=mean(FullBaseline,[2 3]);
    STD_FullBaseline=std(FullBaseline,0,[2 3]);
    end
end

% ---- InData normalization ------
if IsCell_Data
    for tidx=1:length(TrialNumbers_Data)
        this_TrialNumberData=TrialNumbers_Data(tidx);
        this_idx=TrialNumbers_FullBaseline==this_TrialNumberData;
        this_mu=Mean_FullBaseline(:,this_idx);
        this_sd=STD_FullBaseline(:,this_idx);
        
        if ~do_zscore % if we don't want to zscore
            Norm_InData{tidx}=(InData{tidx}); % pass the input data without normalizing
        else
            if all(this_sd==0)
            Norm_InData{tidx}=(InData{tidx}-this_mu);    
            else
            Norm_InData{tidx}=(InData{tidx}-this_mu)./this_sd;
            end
        end
    end
    Mean_Norm_InData=NaN;
    STD_ERROR_Norm_InData=NaN;
else
    if ~do_zscore
        Norm_InData = InData;
    else
        if all(STD_FullBaseline==0)
            Norm_InData=(InData-Mean_FullBaseline);
        else
            Norm_InData=(InData-Mean_FullBaseline)./STD_FullBaseline;
        end
    end
    Mean_Norm_InData=mean(Norm_InData,3);
    STD_ERROR_Norm_InData=std(Norm_InData,0,3)/sqrt(Trial_Counter_Data);
end

%------ InBaseline normalization ------
    
if IsCell_Baseline
    for tidx = 1:length(TrialNumbers_Baseline)
        tr  = TrialNumbers_Baseline(tidx);
        idx = (TrialNumbers_FullBaseline == tr);
        mu  = Mean_FullBaseline(:, idx);
        sd  = STD_FullBaseline(:,  idx);

        if ~do_zscore
            Norm_InBaseline{tidx} = InBaseline{tidx};             
        else
            if all(sd == 0)
                Norm_InBaseline{tidx} = (InBaseline{tidx} - mu);
            else
                Norm_InBaseline{tidx} = (InBaseline{tidx} - mu) ./ sd;
            end
        end
    end
    Mean_Norm_InBaseline      = NaN;
    STD_ERROR_Norm_InBaseline = NaN;
else
    if ~do_zscore                                                
        Norm_InBaseline = InBaseline;                             % pass-through
    else
        if all(STD_FullBaseline == 0)
            Norm_InBaseline = (InBaseline - Mean_FullBaseline);
        else
            Norm_InBaseline = (InBaseline - Mean_FullBaseline) ./ STD_FullBaseline;
        end
    end
    Mean_Norm_InBaseline      = mean(Norm_InBaseline, 3);
    STD_ERROR_Norm_InBaseline = std( Norm_InBaseline, 0, 3) / sqrt(Trial_Counter_Baseline); % <-- use Norm_
end

end

