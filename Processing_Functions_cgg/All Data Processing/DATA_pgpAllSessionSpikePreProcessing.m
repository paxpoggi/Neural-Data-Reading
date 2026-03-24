%% DATA_pgpAllSessionSpikePrePrecessing.m

clc; clear; close all;

[cfg] = DATA_cggAllSessionInformationConfiguration;

%%

for sidx=1:length(cfg)
    
    inputfolder=cfg(sidx).inputfolder;
    outdatadir=cfg(sidx).outdatadir;

[Output,Area_Names] = pgp_proc_EventFrameTrialPreparation(...
    'inputfolder',cfg(sidx).inputfolder,'outdatadir',cfg(sidx).outdatadir);

end