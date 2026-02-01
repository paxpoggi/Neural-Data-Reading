%% TEST_kaa_testFullPreprocessingPipeline
% Test full preprocessing pipeline with synthetic data including file I/O
%
% This script tests the end-to-end preprocessing pipeline:
% 1. Creates folder structure
% 2. Saves wideband data to files
% 3. Applies notch filtering
% 4. Generates LFP/MUA
% 5. Tests artifact detection
%
% Author: kaa

% Note: 'clear' removed to avoid clearing parent workspace when called from master test
clc; close all;

%% Setup
fprintf('=== Testing Full Preprocessing Pipeline with Synthetic Data ===\n\n');

% Initialize FieldTrip
evalc('ft_defaults');
ft_notice('off');
ft_info('off');
ft_warning('off');

% Create temporary directory for test output
test_dir = tempname;
mkdir(test_dir);
fprintf('Using temporary directory: %s\n', test_dir);

% Cleanup function
cleanup_obj = onCleanup(@() rmdir(test_dir, 's'));

% Parameters
SessionName = 'Synthetic_Test';
ExperimentName = 'Test_Experiment';
probe_area = 'ACC_001';
trial_index = 1;

notch_filter_freqs = [60, 120, 180];
notch_filter_bandwidth = 2.0;
lfp_maxfreq = 300;
lfp_samprate = 1000;
spike_minfreq = 100;
rect_bandfreqs = [300, 5000];
rect_lowpassfreq = 500;
rect_samprate = 1000;

%% Generate Synthetic Data
fprintf('\n1. Generating synthetic FieldTrip data...\n');
data = kaa_generateSyntheticFieldTripData('fsample', 30000, 'duration', 1);
fprintf('   Generated %d channels, %d samples at %.0f Hz\n', ...
    length(data.label), length(data.time{1}), data.fsample);

% Show input data
fprintf('   Plotting input data...\n');
kaa_plotChannelComparison(data, [1, 4, 6, 7, 9], ...
    'title', 'Input Data: Good Channels (1,4), DC Artifact (6), 60Hz Noise (7), High Amplitude (9)', ...
    'time_range', [0, 0.1], 'freq_range', [0, 200]);
pause(0.5);

%% Create Folder Structure
fprintf('\n2. Creating folder structure...\n');
try
    [outdatadir_WideBand, outdatadir_LFP, outdatadir_Spike, ...
        outdatadir_MUA, outdatadir_Raw, outdatadir_Notch] = ...
        cgg_generateNeuralDataFolders(test_dir, SessionName, ...
        ExperimentName, probe_area, 'keep_raw', true, 'keep_notch', true);
    fprintf('   ✓ Folder structure created\n');
    fprintf('   WideBand: %s\n', outdatadir_WideBand);
    fprintf('   LFP: %s\n', outdatadir_LFP);
    fprintf('   MUA: %s\n', outdatadir_MUA);
catch ME
    fprintf('   ✗ Failed to create folder structure: %s\n', ME.message);
    return;
end

%% Save Wideband Data
fprintf('\n3. Saving wideband data...\n');
wideband_filename = sprintf('%s/WideBand_Trial_%d.mat', outdatadir_WideBand, trial_index);
try
    this_recdata_wideband = data;
    kaa_saveWithRetry(wideband_filename, 'this_recdata_wideband', this_recdata_wideband);
    fprintf('   ✓ Wideband data saved to: %s\n', wideband_filename);
    
    % Verify file exists and can be loaded
    if exist(wideband_filename, 'file')
        m_test = matfile(wideband_filename);
        if isprop(m_test, 'this_recdata_wideband')
            fprintf('   ✓ File verified and readable\n');
        else
            fprintf('   ✗ File exists but variable not found\n');
        end
    else
        fprintf('   ✗ File was not created\n');
    end
catch ME
    fprintf('   ✗ Failed to save wideband data: %s\n', ME.message);
    return;
end

%% Apply Notch Filtering
fprintf('\n4. Applying notch filtering...\n');
try
    m_wideband = matfile(wideband_filename);
    this_recdata_wideband = m_wideband.this_recdata_wideband;
    
    this_recdata_notch = euFT_doBrickNotchRemoval(this_recdata_wideband, ...
        notch_filter_freqs, notch_filter_bandwidth);
    
    % Save notch filtered data
    notch_filename = sprintf('%s/Notch_Trial_%d.mat', outdatadir_Notch, trial_index);
    kaa_saveWithRetry(notch_filename, 'this_recdata_wideband', this_recdata_notch);
    fprintf('   ✓ Notch filtering applied and saved\n');
    
    % Show notch filtering result
    fprintf('   Plotting notch filtering result...\n');
    kaa_plotBeforeAfter(this_recdata_wideband, this_recdata_notch, 7, ...
        'title', sprintf('Notch Filtering: Channel 7 (60Hz) - Before vs After'), ...
        'freq_range', [40, 80]);
    pause(0.5);
    
    % Validate notch filtering
    predicted_notch = kaa_predictNotchOutput(data, notch_filter_freqs, notch_filter_bandwidth);
    results_notch = kaa_validateNotchFiltering(this_recdata_notch, predicted_notch, -40, 'before_data', this_recdata_wideband);
    if results_notch.passed
        fprintf('   ✓ Notch filtering validation PASSED\n');
    else
        fprintf('   ✗ Notch filtering validation FAILED\n');
        for i = 1:length(results_notch.errors)
            fprintf('     Error: %s\n', results_notch.errors{i});
        end
    end
catch ME
    fprintf('   ✗ Failed to apply notch filtering: %s\n', ME.message);
    return;
end

%% Generate LFP
fprintf('\n5. Generating LFP...\n');
try
    [this_recdata_lfp, ~, ~] = euFT_getDerivedSignals(this_recdata_wideband, ...
        lfp_maxfreq, lfp_samprate, spike_minfreq, rect_bandfreqs, ...
        rect_lowpassfreq, rect_samprate, true);
    
    % Save LFP data
    lfp_filename = sprintf('%s/LFP_Trial_%d.mat', outdatadir_LFP, trial_index);
    kaa_saveWithRetry(lfp_filename, 'this_recdata_lfp', this_recdata_lfp);
    fprintf('   ✓ LFP generated and saved\n');
    
    % Show LFP generation result
    fprintf('   Plotting LFP generation result...\n');
    kaa_plotBeforeAfter(this_recdata_wideband, this_recdata_lfp, 4, ...
        'title', sprintf('LFP Generation: Channel 4 (1000Hz) - Lowpass %dHz, Downsample to %dHz', lfp_maxfreq, lfp_samprate), ...
        'freq_range', [0, 500]);
    pause(0.5);
    
    % Validate LFP
    predicted_lfp = kaa_predictLFPOutput(data, lfp_maxfreq, lfp_samprate);
    results_lfp = kaa_validateLFPOutput(this_recdata_lfp, predicted_lfp, 0.01, 'before_data', this_recdata_wideband);
    if results_lfp.passed
        fprintf('   ✓ LFP validation PASSED\n');
        fprintf('     Sampling rate: %.1f Hz, Samples: %d\n', ...
            this_recdata_lfp.fsample, length(this_recdata_lfp.time{1}));
    else
        fprintf('   ✗ LFP validation FAILED\n');
        for i = 1:length(results_lfp.errors)
            fprintf('     Error: %s\n', results_lfp.errors{i});
        end
    end
catch ME
    fprintf('   ✗ Failed to generate LFP: %s\n', ME.message);
    return;
end

%% Generate MUA
fprintf('\n6. Generating MUA...\n');
try
    [~, ~, this_recdata_mua] = euFT_getDerivedSignals(this_recdata_wideband, ...
        lfp_maxfreq, lfp_samprate, spike_minfreq, rect_bandfreqs, ...
        rect_lowpassfreq, rect_samprate, true);
    
    % Save MUA data
    mua_filename = sprintf('%s/MUA_Trial_%d.mat', outdatadir_MUA, trial_index);
    kaa_saveWithRetry(mua_filename, 'this_recdata_activity', this_recdata_mua);
    fprintf('   ✓ MUA generated and saved\n');
    
    % Show MUA generation result
    fprintf('   Plotting MUA generation result...\n');
    kaa_plotBeforeAfter(this_recdata_wideband, this_recdata_mua, 4, ...
        'title', sprintf('MUA Generation: Channel 4 - Bandpass [%d-%d]Hz, Rectify, Lowpass %dHz', ...
        rect_bandfreqs(1), rect_bandfreqs(2), rect_lowpassfreq), ...
        'freq_range', [0, 1000]);
    pause(0.5);
    
    % Validate MUA
    predicted_mua = kaa_predictMUAOutput(data, spike_minfreq, rect_bandfreqs, ...
        rect_lowpassfreq, rect_samprate);
    results_mua = kaa_validateMUAOutput(this_recdata_mua, predicted_mua, 0.01, 'before_data', this_recdata_wideband);
    if results_mua.passed
        fprintf('   ✓ MUA validation PASSED\n');
        fprintf('     Sampling rate: %.1f Hz, Samples: %d\n', ...
            this_recdata_mua.fsample, length(this_recdata_mua.time{1}));
    else
        fprintf('   ✗ MUA validation FAILED\n');
        for i = 1:length(results_mua.errors)
            fprintf('     Error: %s\n', results_mua.errors{i});
        end
    end
catch ME
    fprintf('   ✗ Failed to generate MUA: %s\n', ME.message);
    return;
end

%% Test Artifact Detection (Simplified)
fprintf('\n7. Testing artifact detection...\n');
try
    % Load wideband data for artifact detection
    m_wideband = matfile(wideband_filename);
    this_recdata_wideband = m_wideband.this_recdata_wideband;
    
    % Simulate artifact detection using z-scoring approach
    % (Similar to what's done in cgg_proc_NeuralDataPreparation.m lines 926-960)
    labels = this_recdata_wideband.label;
    X = this_recdata_wideband.trial{1};  % [nChannels x nSamples]
    
    % Use all channels as reference candidates
    refIdx = 1:size(X, 1);
    Xcat = X(refIdx, :);
    
    % Robust per-channel stats
    medc = median(Xcat, 2);
    madc = mad(Xcat, 1, 2);
    rZ = (Xcat - medc) ./ max(madc, eps);
    
    % Find channels with excessive z-scores
    fracHi = mean(abs(rZ) > 7, 2);  % threshold 7 robust SDs
    keep = isfinite(medc) & isfinite(madc) & fracHi < 0.01;
    
    connected_channels = find(keep)';
    disconnected_channels = find(~keep)';
    
    fprintf('   Connected channels: %s\n', mat2str(connected_channels));
    fprintf('   Disconnected channels: %s\n', mat2str(disconnected_channels));
    
    % Validate artifact detection
    expected_disconnected = [6, 9];  % CH006 (DC) and CH009 (high amplitude)
    results_artifact = kaa_validateArtifactDetection(connected_channels, ...
        disconnected_channels, expected_disconnected);
    
    if results_artifact.passed
        fprintf('   ✓ Artifact detection validation PASSED\n');
    else
        fprintf('   ✗ Artifact detection validation FAILED\n');
        for i = 1:length(results_artifact.errors)
            fprintf('     Error: %s\n', results_artifact.errors{i});
        end
    end
    for i = 1:length(results_artifact.warnings)
        fprintf('   Warning: %s\n', results_artifact.warnings{i});
    end
catch ME
    fprintf('   ✗ Failed artifact detection test: %s\n', ME.message);
    fprintf('   Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('     %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

%% Summary
fprintf('\n=== Test Summary ===\n');
fprintf('All preprocessing pipeline tests completed.\n');

% Show complete pipeline progression
fprintf('Plotting complete preprocessing pipeline progression...\n');
try
    m_wideband = matfile(wideband_filename);
    m_notch = matfile(notch_filename);
    m_lfp = matfile(lfp_filename);
    m_mua = matfile(mua_filename);
    
    this_recdata_wideband = m_wideband.this_recdata_wideband;
    this_recdata_notch = m_notch.this_recdata_wideband;
    this_recdata_lfp = m_lfp.this_recdata_lfp;
    this_recdata_mua = m_mua.this_recdata_activity;
    
    kaa_plotPreprocessingPipeline([], this_recdata_wideband, this_recdata_notch, ...
        this_recdata_lfp, this_recdata_mua, ...
        'channels', [1, 4, 7], ...
        'title', 'Complete Preprocessing Pipeline: Wideband → Notch → LFP → MUA', ...
        'time_range', [0, 0.1], ...
        'freq_range', [0, 200]);
catch ME
    fprintf('   Warning: Could not plot pipeline progression: %s\n', ME.message);
end

fprintf('Temporary directory will be cleaned up automatically.\n');
fprintf('\nTest completed.\n');

