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
NumGroups_Iter=length(Start_Group:End_Group);
Disconnected_Count=cell(1,NumIterations);

% Compute PCA and save all outputs (including loadings)
[COEFF_LFP,PCA_SCORE_LFP,LATENT_LFP,EXPLAINED_LFP] = fastpca(InData{1});
[COEFF_WB,PCA_SCORE_WB,LATENT_WB,EXPLAINED_WB] = fastpca(InData{2});

% Initialize structures to store detailed clustering results
Clustering_Results_LFP = struct();
Clustering_Results_WB = struct();

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

Disconnected_GT_IDX_LFP=Group_Labels_LFP(Disconnected_Channels_GT);
Disconnected_GT_IDX_WB=Group_Labels_WB(Disconnected_Channels_GT);

% Find unique values and their counts
[uniqueValues_LFP, ~, indices_LFP] = unique(Group_Labels_LFP);
counts_LFP = histcounts(indices_LFP, 1:numel(uniqueValues_LFP)+1);
[uniqueValues_WB, ~, indices_WB] = unique(Group_Labels_WB);
counts_WB = histcounts(indices_WB, 1:numel(uniqueValues_WB)+1);

% Find values that appear only once
valuesAppearingOnce_LFP = uniqueValues_LFP(counts_LFP == 1);
valuesAppearingOnce_WB = uniqueValues_WB(counts_WB == 1);

Disconnected_GT_IDX_LFP=[Disconnected_GT_IDX_LFP;setdiff(valuesAppearingOnce_LFP,Disconnected_GT_IDX_LFP)];
Disconnected_GT_IDX_WB=[Disconnected_GT_IDX_WB;setdiff(valuesAppearingOnce_WB,Disconnected_GT_IDX_WB)];

Disconnected_Channels_LFP_iter{idx-Start_Group+1}=All_Channels(ismember(Group_Labels_LFP,Disconnected_GT_IDX_LFP));
Disconnected_Channels_WB_iter{idx-Start_Group+1}=All_Channels(ismember(Group_Labels_WB,Disconnected_GT_IDX_WB));

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

% Add detailed clustering results
Debugging_Info.Clustering_Results.LFP = Clustering_Results_LFP;
Debugging_Info.Clustering_Results.WB = Clustering_Results_WB;

% Store parameter ranges for reference
Debugging_Info.Parameters.NumIterations = NumIterations;
Debugging_Info.Parameters.Start_Group = Start_Group;
Debugging_Info.Parameters.End_Group = End_Group;
Debugging_Info.Parameters.NumReplicates = NumReplicates;
Debugging_Info.Parameters.Disconnected_Channels_GT = Disconnected_Channels_GT;

end

