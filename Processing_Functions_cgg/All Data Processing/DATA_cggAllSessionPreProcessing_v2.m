%% DATA_cggAllSessionPreProcessing_v2

clc; clear; close all;

[cfg] = DATA_cggAllSessionInformationConfiguration;

%% Code to run on ACCRE with arrays
% If running under Slurm array, select a single cfg entry per array.
% Otherwise (no env var), process all entries locally.
slurm_array = getenv('SLURM_ARRAY_TASK_ID');
if ~isempty(slurm_array)
    idxs = str2double(slurm_array);   % 
else
    idxs = 1:length(cfg);
end

for sidx=idxs
    
    inputfolder=cfg(sidx).inputfolder;
    outdatadir=cfg(sidx).outdatadir;
    ExperimentName=cfg(sidx).ExperimentName;

[Output,Area_Names] = cgg_proc_NeuralDataPreparation(...
    'inputfolder',inputfolder,'outdatadir', outdatadir,'ExperimentName',ExperimentName);

end