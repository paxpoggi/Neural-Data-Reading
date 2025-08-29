function [cfg] = DATA_cggAllSessionInformationConfiguration
%DATA_CGGALLSESSIONINFORMATIONCONFIGURATION Summary of this function goes here
%   Detailed explanation goes here

cfg=struct([]);
%% New VU595 Experiment with Wotan and Igor
% Monkey_Name='Wotan';
% ExperimentName='IDED_DBC_AH_AN/VU595_DBC';
% SessionName ='Wo_VU595_02_2023-05-23_A';
% LearningModelName='Wo_VU595_02_2023-05-23_A_001';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];

Monkey_Name='Igor';  
ExperimentName='IDED_DBC_AH_AN/VU595_DBC';
SessionName= 'Ig_VU595_03_2023-03-08_A';
LearningModelName='Ig_VU595_05_2023-03-10_A_001';

[inputfolder,outdatadir,temporarydir,~] = ...
    cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
    ExperimentName,SessionName);

this_FieldNum=length(cfg)+1;
cfg(this_FieldNum).inputfolder=inputfolder;
cfg(this_FieldNum).outdatadir=outdatadir;
cfg(this_FieldNum).temporarydir=temporarydir;
cfg(this_FieldNum).Monkey_Name=Monkey_Name;
cfg(this_FieldNum).ExperimentName=ExperimentName;
cfg(this_FieldNum).SessionName=SessionName;
cfg(this_FieldNum).LearningModelName=LearningModelName;
cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
    filesep SessionName];

% Monkey_Name='Igor';  
% ExperimentName='IDED_DBC_AH_AN/VU595_DBC';
% SessionName= 'Ig_VU595_07_2023-03-14_A';
% LearningModelName='Ig_VU595_05_2023-03-10_A_001';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];

%% Old FLToken experiment 
% %% Wo_Probe_01_23-02-13_003_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-02-13_003_01';
% LearningModelName='Wo_Probe_01_23-02-13_072_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Wo_Probe_01_23-02-21_006_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-02-21_006_01';
% LearningModelName='Wo_Probe_01_23-02-21_073_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Wo_Probe_01_23-02-22_007_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-02-22_007_01';
% LearningModelName='Wo_Probe_01_23-02-22_074_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Wo_Probe_01_23-02-23_008_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-02-23_008_01';
% LearningModelName='Wo_Probe_01_23-02-23_075_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Wo_Probe_01_23-02-24_009_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-02-24_009_01';
% LearningModelName='Wo_Probe_01_23-02-24_076_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Wo_Probe_01_23-02-27_010_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-02-27_010_01';
% LearningModelName='Wo_Probe_01_23-02-27_077_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Wo_Probe_01_23-02-28_011_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-02-28_011_01';
% LearningModelName='Wo_Probe_01_23-02-28_078_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Wo_Probe_01_23-03-01_012_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-03-01_012_01';
% LearningModelName='Wo_Probe_01_23-03-01_079_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Wo_Probe_01_23-03-02_013_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-03-02_013_01';
% LearningModelName='Wo_Probe_01_23-03-02_080_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Wo_Probe_01_23-03-03_014_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-03-03_014_01';
% LearningModelName='Wo_Probe_01_23-03-03_081_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Wo_Probe_01_23-03-07_016_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-03-07_016_01';
% LearningModelName='Wo_Probe_01_23-03-07_083_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Wo_Probe_01_23-03-08_017_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-03-08_017_01';
% LearningModelName='Wo_Probe_01_23-03-08_084_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Wo_Probe_01_23-03-09_018_01
% Monkey_Name='Wotan';
% ExperimentName='Wotan_FLToken_Probe_01';
% SessionName='Wo_Probe_01_23-03-09_018_01';
% LearningModelName='Wo_Probe_01_23-03-09_085_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% % %% Fr_Probe_02_22-04-27_003_01
% % Monkey_Name='Frey';
% % ExperimentName='Frey_FLToken_Probe_02';
% % SessionName='Fr_Probe_02_22-04-27_003_01';
% % 
% % [inputfolder,outdatadir,temporarydir,~] = ...
% %     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
% %     ExperimentName,SessionName);
% % 
% % this_FieldNum=length(cfg)+1;
% % cfg(this_FieldNum).inputfolder=inputfolder;
% % cfg(this_FieldNum).outdatadir=outdatadir;
% % cfg(this_FieldNum).temporarydir=temporarydir;
% % cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% % cfg(this_FieldNum).ExperimentName=ExperimentName;
% % cfg(this_FieldNum).SessionName=SessionName;
% % cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
% %     filesep SessionName];
% % 
% %% Fr_Probe_02_22-05-02_004_01
% Monkey_Name='Frey';
% ExperimentName='Frey_FLToken_Probe_02';
% SessionName='Fr_Probe_02_22-05-02_004_01';
% LearningModelName='Fr_Probe_02_22-05-02_204_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Fr_Probe_02_22-05-03_005_01
% Monkey_Name='Frey';
% ExperimentName='Frey_FLToken_Probe_02';
% SessionName='Fr_Probe_02_22-05-03_005_01';
% LearningModelName='Fr_Probe_02_22-05-03_205_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Fr_Probe_02_22-05-04_006_01
% Monkey_Name='Frey';
% ExperimentName='Frey_FLToken_Probe_02';
% SessionName='Fr_Probe_02_22-05-04_006_01';
% LearningModelName='Fr_Probe_02_22-05-04_206_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Fr_Probe_02_22-05-05_007_01
% Monkey_Name='Frey';
% ExperimentName='Frey_FLToken_Probe_02';
% SessionName='Fr_Probe_02_22-05-05_007_01';
% LearningModelName='Fr_Probe_02_22-05-05_207_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Fr_Probe_02_22-05-06_008_01
% Monkey_Name='Frey';
% ExperimentName='Frey_FLToken_Probe_02';
% SessionName='Fr_Probe_02_22-05-06_008_01';
% LearningModelName='Fr_Probe_02_22-05-06_208_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Fr_Probe_02_22-05-09_009_01
% Monkey_Name='Frey';
% ExperimentName='Frey_FLToken_Probe_02';
% SessionName='Fr_Probe_02_22-05-09_009_01';
% LearningModelName='Fr_Probe_02_22-05-09_209_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Fr_Probe_02_22-05-10_010_01
% Monkey_Name='Frey';
% ExperimentName='Frey_FLToken_Probe_02';
% SessionName='Fr_Probe_02_22-05-10_010_01';
% LearningModelName='Fr_Probe_02_22-05-10_210_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Fr_Probe_02_22-05-11_011_01
% Monkey_Name='Frey';
% ExperimentName='Frey_FLToken_Probe_02';
% SessionName='Fr_Probe_02_22-05-11_011_01';
% LearningModelName='Fr_Probe_02_22-05-11_211_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Fr_Probe_03_22-06-30_001_02
% Monkey_Name='Frey';
% ExperimentName='Frey_FLToken_Probe_03';
% SessionName='Fr_Probe_03_22-06-30_001_02';
% LearningModelName='Fr_Probe_03_22-06-30_212_02';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Fr_Probe_03_22-07-13_002_01
% Monkey_Name='Frey';
% ExperimentName='Frey_FLToken_Probe_03';
% SessionName='Fr_Probe_03_22-07-13_002_01';
% LearningModelName='Fr_Probe_03_22-07-13_213_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Fr_Probe_03_22-07-15_003_01
% Monkey_Name='Frey';
% ExperimentName='Frey_FLToken_Probe_03';
% SessionName='Fr_Probe_03_22-07-15_003_01';
% LearningModelName='Fr_Probe_03_22-07-15_214_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
% 
% %% Fr_Probe_03_22-07-21_004_01
% Monkey_Name='Frey';
% ExperimentName='Frey_FLToken_Probe_03';
% SessionName='Fr_Probe_03_22-07-21_004_01';
% LearningModelName='Fr_Probe_03_22-07-21_215_01';
% 
% [inputfolder,outdatadir,temporarydir,~] = ...
%     cgg_getBaseFoldersFromSessionInformation(Monkey_Name,...
%     ExperimentName,SessionName);
% 
% this_FieldNum=length(cfg)+1;
% cfg(this_FieldNum).inputfolder=inputfolder;
% cfg(this_FieldNum).outdatadir=outdatadir;
% cfg(this_FieldNum).temporarydir=temporarydir;
% cfg(this_FieldNum).Monkey_Name=Monkey_Name;
% cfg(this_FieldNum).ExperimentName=ExperimentName;
% cfg(this_FieldNum).SessionName=SessionName;
% cfg(this_FieldNum).LearningModelName=LearningModelName;
% cfg(this_FieldNum).SessionFolder=[outdatadir filesep ExperimentName ...
%     filesep SessionName];
%
end
 
