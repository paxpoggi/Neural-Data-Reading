%% DATA_cggAllSessionProcessing

clc; clear; close all;

[cfg] = DATA_cggAllSessionInformationConfiguration;

Epoch='Decision';

%%
for sidx=1:length(cfg)
    
    inputfolder=cfg(sidx).inputfolder;
    outdatadir=cfg(sidx).outdatadir;
    ExperimentName=cfg(sidx).ExperimentName;
    monkey_name=cfg(sidx).Monkey_Name;

pgp_procProcessingBehaviorOnly(...
    'inputfolder',cfg(sidx).inputfolder,'outdatadir',cfg(sidx).outdatadir,'Epoch',Epoch, 'ExperimentName', ExperimentName, 'monkey_name', monkey_name);

end