%% DATA_cggAllSessionPreProcessing_v2

clc; clear; close all;

[cfg] = DATA_cggAllSessionInformationConfiguration;

%%

for sidx=1:length(cfg)
    
    inputfolder=cfg(sidx).inputfolder;
    outdatadir=cfg(sidx).outdatadir;
    monkey_name=cfg(sidx).Monkey_name;

[Output,Area_Names] = cgg_proc_NeuralDataPreparation(...
    'inputfolder',cfg(sidx).inputfolder,'outdatadir',cfg(sidx).outdatadir,'monkey_name',monkey_name);

end