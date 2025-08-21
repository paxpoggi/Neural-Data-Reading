%% DATA_cggAllSessionProcessing

clc; clear; close all;

[cfg] = DATA_cggAllSessionInformationConfiguration;

Epoch='Decision';

%%

for sidx=1:length(cfg)
    
    inputfolder=cfg(sidx).inputfolder;
    outdatadir=cfg(sidx).outdatadir;
    monkey_name=cfg(sidx).Monkey_Name;
    ExperimentName=cfg(sidx).ExperimentName;


% the input folder is expected to be the session folder!
cgg_procFullTrialPreparation_v3(...
    'inputfolder',inputfolder,'outdatadir',outdatadir,...
    'Epoch',Epoch, 'monkey_name',monkey_name, 'ExperimentName', ExperimentName);

end