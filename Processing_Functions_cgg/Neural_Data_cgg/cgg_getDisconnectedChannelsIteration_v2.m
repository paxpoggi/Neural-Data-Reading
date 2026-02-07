function [Connected_Channels,Disconnected_Channels,Debugging_Info] = ...
    cgg_getDisconnectedChannelsIteration_v2(InData,NumReplicates,...
    InDistance,Start_Group,End_Group,Disconnected_Channels_GT,...
    Disconnected_Threshold,NumIterations)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

%%

% Start_Group=2;
% End_Group=7;
% NumReplicates=10; %10
% InDistance='sqeuclidean';
% NumIterations=10;
% Disconnected_Channels_GT=60:64;

% Disconnected_Threshold=0.5;

[NumChannels,~]=size(InData{1});
All_Channels=1:NumChannels;

%%
% Identify good channels (exclude Method I bad channels from PCA computation)
% Handle edge cases: no bad channels, all channels bad, insufficient good channels
Good_Channels = setdiff(All_Channels, Disconnected_Channels_GT);
use_all_channels_for_pca = false;

if isempty(Disconnected_Channels_GT)
    % No bad channels: use all channels (current behavior)
    Good_Channels = All_Channels;
    use_all_channels_for_pca = true;
    fprintf('.. Method ii: No Method I bad channels - using all %d channels for PCA\n', NumChannels);
elseif isempty(Good_Channels) || numel(Good_Channels) < 2
    % All channels bad or insufficient good channels: use all channels with warning
    Good_Channels = All_Channels;
    use_all_channels_for_pca = true;
    warning('Method ii: Too few good channels (%d) - using all channels for PCA', numel(Good_Channels));
else
    % Normal case: exclude bad channels from PCA
    fprintf('.. Method ii: Excluding %d Method I bad channel(s) from PCA computation: [%s]\n', ...
        numel(Disconnected_Channels_GT), num2str(Disconnected_Channels_GT));
    fprintf('.. Method ii: Computing PCA on %d good channel(s)...\n', numel(Good_Channels));
end

fprintf('.. Method ii: Starting clustering analysis...\n');
fprintf('.. Method ii: Parameters - Components: %d, Clusters: %d-%d, Iterations: %d\n', ...
    NumIterations, Start_Group, End_Group, NumIterations);

NumGroups_Iter=length(Start_Group:End_Group);
Disconnected_Count=cell(1,NumIterations);

% Compute PCA and save all outputs (including loadings)
% Critical: Centering and scaling must be identical for projection
if use_all_channels_for_pca
    % Use all channels (edge case: no bad channels or insufficient good channels)
    fprintf('.. Method ii: Computing PCA for LFP and Wideband data (all channels)...\n');
    [COEFF_LFP,PCA_SCORE_LFP,LATENT_LFP,EXPLAINED_LFP] = fastpca(InData{1});
    [COEFF_WB,PCA_SCORE_WB,LATENT_WB,EXPLAINED_WB] = fastpca(InData{2});
    
    % Mean is computed internally by fastpca (from all channels)
    mean_LFP = mean(InData{1}, 1);  % [1 x TotalSamples] - mean per time point across all channels
    mean_WB = mean(InData{2}, 1);   % [1 x TotalSamples] - mean per time point across all channels
else
    % Normal case: exclude bad channels from PCA, then project them
    fprintf('.. Method ii: Computing mean from %d good channel(s) for centering...\n', numel(Good_Channels));
    
    % Extract good channel data
    InData_Good_LFP = InData{1}(Good_Channels, :);  % [N_good x TotalSamples]
    InData_Good_WB = InData{2}(Good_Channels, :);   % [N_good x TotalSamples]
    
    % Compute mean from good channels BEFORE PCA (critical for consistent projection)
    mean_LFP = mean(InData_Good_LFP, 1);  % [1 x TotalSamples] - mean per time point across good channels
    mean_WB = mean(InData_Good_WB, 1);    % [1 x TotalSamples] - mean per time point across good channels
    
    fprintf('.. Method ii: Computing PCA on %d good channel(s) (centered)...\n', numel(Good_Channels));
    
    % Compute PCA on good channels (fastpca will center internally using mean of good channels)
    [COEFF_LFP, SCORE_Good_LFP, LATENT_LFP, EXPLAINED_LFP] = fastpca(InData_Good_LFP);
    [COEFF_WB, SCORE_Good_WB, LATENT_WB, EXPLAINED_WB] = fastpca(InData_Good_WB);
    
    % Extract bad channel data
    InData_Bad_LFP = InData{1}(Disconnected_Channels_GT, :);  % [N_bad x TotalSamples]
    InData_Bad_WB = InData{2}(Disconnected_Channels_GT, :);   % [N_bad x TotalSamples]
    
    fprintf('.. Method ii: Projecting %d bad channel(s) onto PCA space using same mean...\n', numel(Disconnected_Channels_GT));
    
    % Project bad channels using IDENTICAL preprocessing (same mean from good channels)
    % Center bad channels using same mean: (bad_data - mean) * COEFF
    InData_Bad_LFP_Centered = InData_Bad_LFP - mean_LFP;  % Broadcasting: [N_bad x TotalSamples] - [1 x TotalSamples]
    InData_Bad_WB_Centered = InData_Bad_WB - mean_WB;     % Broadcasting: [N_bad x TotalSamples] - [1 x TotalSamples]
    
    SCORE_Bad_LFP = InData_Bad_LFP_Centered * COEFF_LFP;  % [N_bad x NumComponents]
    SCORE_Bad_WB = InData_Bad_WB_Centered * COEFF_WB;     % [N_bad x NumComponents]
    
    % Combine scores maintaining original channel order
    % Create full score matrices [NumChannels x NumComponents]
    NumComponents_Computed = size(COEFF_LFP, 2);  % Number of components computed by PCA
    
    PCA_SCORE_LFP = zeros(NumChannels, NumComponents_Computed);
    PCA_SCORE_WB = zeros(NumChannels, NumComponents_Computed);
    
    % Fill good channel positions (maintain order via Good_Channels indices)
    PCA_SCORE_LFP(Good_Channels, :) = SCORE_Good_LFP;
    PCA_SCORE_WB(Good_Channels, :) = SCORE_Good_WB;
    
    % Fill bad channel positions (maintain order via Disconnected_Channels_GT indices)
    PCA_SCORE_LFP(Disconnected_Channels_GT, :) = SCORE_Bad_LFP;
    PCA_SCORE_WB(Disconnected_Channels_GT, :) = SCORE_Bad_WB;
    
    fprintf('.. Method ii: PCA complete. Scores computed for all %d channels (good: %d, projected: %d).\n', ...
        NumChannels, numel(Good_Channels), numel(Disconnected_Channels_GT));
end

fprintf('.. Method ii: Starting clustering iterations...\n');

% Initialize structures to store detailed clustering results
Clustering_Results_LFP = struct();
Clustering_Results_WB = struct();

% Initialize status matrices for Method ii tracking
% Values: 0=good, 1=clustered_with_bad_seeds, 2=outlier, 3=both reasons
ChannelStatus_LFP = zeros(NumChannels, NumIterations, NumGroups_Iter);
ChannelStatus_WB = zeros(NumChannels, NumIterations, NumGroups_Iter);

%%

for tidx=1:NumIterations
    
Disconnected_Channels_LFP_iter=cell(1,NumGroups_Iter);
Disconnected_Channels_WB_iter=cell(1,NumGroups_Iter);
    
for idx=Start_Group:End_Group
    %%
NumGroups=idx;
NumComponents = tidx;  % PCA components used (1 to NumIterations)

[Group_Labels_LFP,Group_Distance_LFP,~] = cgg_procChannelClustering_v4(InData{1},NumGroups,NumReplicates,InDistance{1},NumComponents,'PCA_SCORE',PCA_SCORE_LFP);
[Group_Labels_WB,Group_Distance_WB,~] = cgg_procChannelClustering_v4(InData{2},NumGroups,NumReplicates,InDistance{2},NumComponents,'PCA_SCORE',PCA_SCORE_WB);

% Track clusters containing bad seed channels (Method i seeds)
Disconnected_GT_IDX_LFP=Group_Labels_LFP(Disconnected_Channels_GT);
Disconnected_GT_IDX_WB=Group_Labels_WB(Disconnected_Channels_GT);

% Find unique values and their counts
[uniqueValues_LFP, ~, indices_LFP] = unique(Group_Labels_LFP);
counts_LFP = histcounts(indices_LFP, 1:numel(uniqueValues_LFP)+1);
[uniqueValues_WB, ~, indices_WB] = unique(Group_Labels_WB);
counts_WB = histcounts(indices_WB, 1:numel(uniqueValues_WB)+1);

% Find values that appear only once (outliers)
valuesAppearingOnce_LFP = uniqueValues_LFP(counts_LFP == 1);
valuesAppearingOnce_WB = uniqueValues_WB(counts_WB == 1);

% Track separately: clusters with bad seeds vs outlier clusters
badSeedClusters_LFP = unique(Disconnected_GT_IDX_LFP);
badSeedClusters_WB = unique(Disconnected_GT_IDX_WB);
outlierClusters_LFP = setdiff(valuesAppearingOnce_LFP, badSeedClusters_LFP);
outlierClusters_WB = setdiff(valuesAppearingOnce_WB, badSeedClusters_WB);

% Combined list for backward compatibility (used in Disconnected_Count)
Disconnected_GT_IDX_LFP=[Disconnected_GT_IDX_LFP;outlierClusters_LFP];
Disconnected_GT_IDX_WB=[Disconnected_GT_IDX_WB;outlierClusters_WB];

Disconnected_Channels_LFP_iter{idx-Start_Group+1}=All_Channels(ismember(Group_Labels_LFP,Disconnected_GT_IDX_LFP));
Disconnected_Channels_WB_iter{idx-Start_Group+1}=All_Channels(ismember(Group_Labels_WB,Disconnected_GT_IDX_WB));

% Track per-channel status: 0=good, 1=clustered_with_bad_seeds, 2=outlier, 3=both
% Matrix indices: (channel, component, k_group)
k_idx = idx - Start_Group + 1;  % Index into NumGroups_Iter dimension

% For LFP
for ch = 1:NumChannels
    ch_cluster = Group_Labels_LFP(ch);
    is_bad_seed_cluster = ismember(ch_cluster, badSeedClusters_LFP);
    is_outlier_cluster = ismember(ch_cluster, outlierClusters_LFP);
    
    if is_bad_seed_cluster && is_outlier_cluster
        ChannelStatus_LFP(ch, tidx, k_idx) = 3;  % both reasons
    elseif is_bad_seed_cluster
        ChannelStatus_LFP(ch, tidx, k_idx) = 1;  % clustered with bad seeds
    elseif is_outlier_cluster
        ChannelStatus_LFP(ch, tidx, k_idx) = 2;  % outlier
    else
        ChannelStatus_LFP(ch, tidx, k_idx) = 0;  % good
    end
end

% For WB
for ch = 1:NumChannels
    ch_cluster = Group_Labels_WB(ch);
    is_bad_seed_cluster = ismember(ch_cluster, badSeedClusters_WB);
    is_outlier_cluster = ismember(ch_cluster, outlierClusters_WB);
    
    if is_bad_seed_cluster && is_outlier_cluster
        ChannelStatus_WB(ch, tidx, k_idx) = 3;  % both reasons
    elseif is_bad_seed_cluster
        ChannelStatus_WB(ch, tidx, k_idx) = 1;  % clustered with bad seeds
    elseif is_outlier_cluster
        ChannelStatus_WB(ch, tidx, k_idx) = 2;  % outlier
    else
        ChannelStatus_WB(ch, tidx, k_idx) = 0;  % good
    end
end

% Store detailed clustering results for this (NumComponents, NumGroups) combination
field_name = sprintf('C%d_K%d', NumComponents, NumGroups);
Clustering_Results_LFP.(field_name).Group_Labels = Group_Labels_LFP;
Clustering_Results_LFP.(field_name).Group_Distance = Group_Distance_LFP;
Clustering_Results_LFP.(field_name).PCA_SCORE = PCA_SCORE_LFP(:,1:min(3,NumComponents)); % Save first 3 components for plotting
Clustering_Results_LFP.(field_name).NumComponents = NumComponents;
Clustering_Results_LFP.(field_name).NumGroups = NumGroups;
Clustering_Results_LFP.(field_name).Disconnected_Channels = Disconnected_Channels_LFP_iter{idx-Start_Group+1};
Clustering_Results_LFP.(field_name).Connected_Channels = setdiff(All_Channels, Disconnected_Channels_LFP_iter{idx-Start_Group+1});

Clustering_Results_WB.(field_name).Group_Labels = Group_Labels_WB;
Clustering_Results_WB.(field_name).Group_Distance = Group_Distance_WB;
Clustering_Results_WB.(field_name).PCA_SCORE = PCA_SCORE_WB(:,1:min(3,NumComponents)); % Save first 3 components for plotting
Clustering_Results_WB.(field_name).NumComponents = NumComponents;
Clustering_Results_WB.(field_name).NumGroups = NumGroups;
Clustering_Results_WB.(field_name).Disconnected_Channels = Disconnected_Channels_WB_iter{idx-Start_Group+1};
Clustering_Results_WB.(field_name).Connected_Channels = setdiff(All_Channels, Disconnected_Channels_WB_iter{idx-Start_Group+1});

end
%%
Disconnected_Count{tidx}=[cell2mat(Disconnected_Channels_LFP_iter),cell2mat(Disconnected_Channels_WB_iter)];
end

Disconnected_Count_Combined=cell2mat({Disconnected_Count{:}});
Disconnected_Possible = unique(Disconnected_Count_Combined)';
Disconnected_Histogram = [Disconnected_Possible,...
    histc(Disconnected_Count_Combined(:),Disconnected_Possible)];

Disconnected_Histogram_Probability=[Disconnected_Histogram(:,1),Disconnected_Histogram(:,2)/(NumIterations*NumGroups_Iter*2)];

Disconnected_IDX=Disconnected_Possible(Disconnected_Histogram_Probability(:,2)>=Disconnected_Threshold);

Connected_Channels=setdiff(All_Channels,Disconnected_IDX);
Disconnected_Channels=All_Channels(Disconnected_IDX);

fprintf('.. Method ii: Clustering complete. Analyzing results...\n');
fprintf('.. Method ii: Final disconnected channels from clustering: %d\n', numel(Disconnected_Channels));
if ~isempty(Disconnected_Channels)
    fprintf('.. Method ii: Disconnected channels: [%s]\n', num2str(Disconnected_Channels));
end

% Store PCA results in Debugging_Info
Debugging_Info.Disconnected_Count_Combined=Disconnected_Count_Combined;
Debugging_Info.Disconnected_Histogram=Disconnected_Histogram;
Debugging_Info.Disconnected_Histogram_Probability=Disconnected_Histogram_Probability;

% Add PCA loadings and detailed clustering results
Debugging_Info.PCA_Results.LFP.COEFF = COEFF_LFP;
Debugging_Info.PCA_Results.LFP.SCORE = PCA_SCORE_LFP;
Debugging_Info.PCA_Results.LFP.LATENT = LATENT_LFP;
Debugging_Info.PCA_Results.LFP.EXPLAINED = EXPLAINED_LFP;

Debugging_Info.PCA_Results.WB.COEFF = COEFF_WB;
Debugging_Info.PCA_Results.WB.SCORE = PCA_SCORE_WB;
Debugging_Info.PCA_Results.WB.LATENT = LATENT_WB;
Debugging_Info.PCA_Results.WB.EXPLAINED = EXPLAINED_WB;

% Store PCA exclusion and projection information
if use_all_channels_for_pca
    % Edge case: all channels used for PCA
    Debugging_Info.PCA_Results.LFP.Channels_Excluded_From_PCA = [];
    Debugging_Info.PCA_Results.LFP.Channels_Included_In_PCA = All_Channels;
    Debugging_Info.PCA_Results.LFP.Mean_Computed_From_Good_Channels = mean_LFP;  % Mean from all channels
    Debugging_Info.PCA_Results.LFP.Bad_Channels_Projected = false;
    Debugging_Info.PCA_Results.LFP.Preprocessing_Note = 'All channels used for PCA (no exclusion)';
    
    Debugging_Info.PCA_Results.WB.Channels_Excluded_From_PCA = [];
    Debugging_Info.PCA_Results.WB.Channels_Included_In_PCA = All_Channels;
    Debugging_Info.PCA_Results.WB.Mean_Computed_From_Good_Channels = mean_WB;  % Mean from all channels
    Debugging_Info.PCA_Results.WB.Bad_Channels_Projected = false;
    Debugging_Info.PCA_Results.WB.Preprocessing_Note = 'All channels used for PCA (no exclusion)';
else
    % Normal case: bad channels excluded from PCA, then projected
    Debugging_Info.PCA_Results.LFP.Channels_Excluded_From_PCA = Disconnected_Channels_GT;
    Debugging_Info.PCA_Results.LFP.Channels_Included_In_PCA = Good_Channels;
    Debugging_Info.PCA_Results.LFP.Mean_Computed_From_Good_Channels = mean_LFP;  % Mean from good channels only
    Debugging_Info.PCA_Results.LFP.Bad_Channels_Projected = true;
    Debugging_Info.PCA_Results.LFP.Preprocessing_Note = 'Mean computed from good channels only, applied identically to all channels';
    
    Debugging_Info.PCA_Results.WB.Channels_Excluded_From_PCA = Disconnected_Channels_GT;
    Debugging_Info.PCA_Results.WB.Channels_Included_In_PCA = Good_Channels;
    Debugging_Info.PCA_Results.WB.Mean_Computed_From_Good_Channels = mean_WB;  % Mean from good channels only
    Debugging_Info.PCA_Results.WB.Bad_Channels_Projected = true;
    Debugging_Info.PCA_Results.WB.Preprocessing_Note = 'Mean computed from good channels only, applied identically to all channels';
end

% Store Method ii (Clustering) results
% ChannelStatus matrices: [NumChannels x NumComponents x NumGroups]
% Values: 0=good, 1=clustered_with_bad_seeds, 2=outlier, 3=both reasons
Debugging_Info.Method_ii_Clustering.ChannelStatus_LFP = ChannelStatus_LFP;
Debugging_Info.Method_ii_Clustering.ChannelStatus_WB = ChannelStatus_WB;
Debugging_Info.Method_ii_Clustering.Clustering_Results.LFP = Clustering_Results_LFP;
Debugging_Info.Method_ii_Clustering.Clustering_Results.WB = Clustering_Results_WB;
Debugging_Info.Method_ii_Clustering.Parameters.NumIterations = NumIterations;
Debugging_Info.Method_ii_Clustering.Parameters.Start_Group = Start_Group;
Debugging_Info.Method_ii_Clustering.Parameters.End_Group = End_Group;
Debugging_Info.Method_ii_Clustering.Parameters.NumReplicates = NumReplicates;
Debugging_Info.Method_ii_Clustering.Parameters.Disconnected_Channels_GT = Disconnected_Channels_GT;

end

