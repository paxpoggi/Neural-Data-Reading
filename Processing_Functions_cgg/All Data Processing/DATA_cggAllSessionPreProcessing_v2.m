%% DATA_cggAllSessionPreProcessing_v2

clc; clear; close all;

[cfg] = DATA_cggAllSessionInformationConfiguration;

%%

for sidx=1:length(cfg)
    
    inputfolder=cfg(sidx).inputfolder;
    outdatadir=cfg(sidx).outdatadir;
    ExperimentName=cfg(sidx).ExperimentName;

[Output,Area_Names] = cgg_proc_NeuralDataPreparation(...
    'inputfolder',cfg(sidx).inputfolder,'outdatadir',cfg(sidx).outdatadir,'ExperimentName',ExperimentName);

end