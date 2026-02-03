function [rectrialdefs_corrected,BadTrials] = cgg_procIdentifyBadTrialNumbers(rectrialdefs)
%CGG_PROCIDENTIFYBADTRIALNUMBERS Summary of this function goes here
%   Detailed explanation goes here

%%
% Every Trial has a unique Trial Index, but Trial Number only increments
% after a valid trial. Trial Index >= TrialNumber under valid number
% scheme.
TrialNumber=rectrialdefs(:,7);
TrialIndex=rectrialdefs(:,8);

% The Difference should always be monotonically non-decreasing. Get the
% difference between the index and the number. Take the absolute value so
% that no issues arise with incorrect labeling that may lead to an issue.
% FIXME: should probably just have any where TrialIndex-TrialNumber<0 is
% automatically a bad channel
TrialDifference=abs(TrialIndex-TrialNumber);

% plot(TrialDifference)

%%

% Get the array to check if it's monotonically increasing (weakly
% increasing) [x<=y -> f(x)<=f(y)]
Monotonic_Array=TrialDifference;

% Initialize whether to check for removing bad numbering
Continue_Removal=true;

% Initialize the logical indices for each bad channel to false
IDX_logical_Aggregate=false(size(Monotonic_Array));

% While checking if the last check detected any bad trials. The first pass
% has not checked anythign so it hasn't detected any bad trials yet.
while Continue_Removal

% get a Difference array of the target array. Adding a difference of 0 to
% the end so that each index refers to the order in the original array.
% (e.x. a difference of 1 in the first position [Difference_Array=1] means
% the first and second elements have a difference of 1.)
Difference_Array=[diff(Monotonic_Array);0];

% Check for indixes where the difference is less than 1, indicating that
% the right value is less than the value on the left, which idicates a
% numbering issue
IDX_logical=Difference_Array < 0 | isnan(Monotonic_Array);

% Get the value to the right of the bad index
IDX_logical_plus_1=circshift(IDX_logical,1);

% Initialize a temporary Array of interest
Monotonic_Array_tmp=Monotonic_Array;

% Replace the bad value with the value to its right. This will keep the
% array the same as the original and allow for another check of bad
% numbering and compare it to the far right value
Monotonic_Array_tmp(IDX_logical)=Monotonic_Array(IDX_logical_plus_1);

% Replace the array of interest where the bad numbering is replaced by the
% one to the right
Monotonic_Array=Monotonic_Array_tmp;

% Add the bad trial numbering to the aggregate bad numbering indices
IDX_logical_Aggregate=IDX_logical_Aggregate | IDX_logical;

% if there are any bad numberings in the current pass keep iterating
Continue_Removal=any(IDX_logical);

end

% Record the bad trials and remove them from the rectrials.
BadTrials=IDX_logical_Aggregate;

% Safety check: Warn if bad trials were found
if any(BadTrials)
    numBadTrials = sum(BadTrials);
    totalTrials = length(BadTrials);
    badTrialIndices = find(BadTrials);
    
    warning('cgg_procIdentifyBadTrialNumbers: Found %d bad trial(s) out of %d total trials (indices: %s).', ...
        numBadTrials, totalTrials, mat2str(badTrialIndices));
end

% Keep only the good trials (those NOT in BadTrials)
rectrialdefs_corrected=rectrialdefs(~BadTrials,:);

end

