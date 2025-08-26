%% DATA_cggAllSessionPreProcessing_v2

clc; clear; close all;

[cfg] = DATA_cggAllSessionInformationConfiguration;

%% Code to run on ACCRE with arrays
% If running under Slurm array, select a single cfg entry per array.
% Otherwise (no env var), process all entries locally.
sa = getenv('SLURM_ARRAY_TASK_ID');
if ~isempty(sa)
    idxs = str2double(sa) + 1;   % map 0->1, 1->2 etc for MATLAB 1-based
else
    idxs = 1:length(cfg);
end

for sidx=1:length(cfg)
    
    inputfolder=cfg(sidx).inputfolder;
    outdatadir=cfg(sidx).outdatadir;
    ExperimentName=cfg(sidx).ExperimentName;

[Output,Area_Names] = cgg_proc_NeuralDataPreparation(...
    'inputfolder',inputfolder,'outdatadir', outdatadir,'ExperimentName',ExperimentName);

end