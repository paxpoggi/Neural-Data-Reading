%% TEST_kaa_testPreprocessingWithSyntheticData
% Test preprocessing pipeline with synthetic FieldTrip data
%
% This script generates synthetic data with known properties and tests:
% 1. Notch filtering (removes 60Hz and 120Hz)
% 2. LFP generation (lowpass 300Hz, downsample to 1000Hz)
% 3. MUA generation (bandpass, rectify, lowpass, downsample)
% 4. Artifact detection (DC and high amplitude channels)
%
% Author: kaa

clc; clear; close all;

%% Setup
fprintf('=== Testing Preprocessing Pipeline with Synthetic Data ===\n\n');

% Initialize FieldTrip
evalc('ft_defaults');
ft_notice('off');
ft_info('off');
ft_warning('off');

% Parameters (matching PARAMETERS_cgg_proc_NeuralDataPreparation defaults)
notch_filter_freqs = [60, 120, 180];
notch_filter_bandwidth = 2.0;
lfp_maxfreq = 300;
lfp_samprate = 1000;
spike_minfreq = 100;
rect_bandfreqs = [300, 5000];
rect_lowpassfreq = 500;
rect_samprate = 1000;

%% Generate Synthetic Data
fprintf('1. Generating synthetic FieldTrip data...\n');
data = kaa_generateSyntheticFieldTripData('fsample', 30000, 'duration', 1);
fprintf('   Generated %d channels, %d samples at %.0f Hz\n', ...
    length(data.label), length(data.time{1}), data.fsample);

%% Test 1: Notch Filtering
fprintf('\n2. Testing notch filtering...\n');
predicted_notch = kaa_predictNotchOutput(data, notch_filter_freqs, notch_filter_bandwidth);
fprintf('   Expected to remove frequencies: %s Hz\n', mat2str(notch_filter_freqs));
fprintf('   Expected affected channels: %s\n', mat2str(predicted_notch.channels_affected));

% Apply notch filtering
data_notch = euFT_doBrickNotchRemoval(data, notch_filter_freqs, notch_filter_bandwidth);

% Validate
results_notch = kaa_validateNotchFiltering(data_notch, predicted_notch);
if results_notch.passed
    fprintf('   ✓ Notch filtering test PASSED\n');
else
    fprintf('   ✗ Notch filtering test FAILED\n');
    for i = 1:length(results_notch.errors)
        fprintf('     Error: %s\n', results_notch.errors{i});
    end
end
for i = 1:length(results_notch.warnings)
    fprintf('   Warning: %s\n', results_notch.warnings{i});
end

%% Test 2: LFP Generation
fprintf('\n3. Testing LFP generation...\n');
predicted_lfp = kaa_predictLFPOutput(data, lfp_maxfreq, lfp_samprate);
fprintf('   Expected lowpass: %d Hz\n', lfp_maxfreq);
fprintf('   Expected sampling rate: %d Hz\n', lfp_samprate);
fprintf('   Expected preserved channels: %s\n', mat2str(predicted_lfp.channels_preserved));
fprintf('   Expected removed channels: %s\n', mat2str(predicted_lfp.channels_removed));

% Generate LFP (use wideband data, not notch filtered, as per pipeline)
[data_lfp, ~, ~] = euFT_getDerivedSignals(data, lfp_maxfreq, lfp_samprate, ...
    spike_minfreq, rect_bandfreqs, rect_lowpassfreq, rect_samprate, true);

% Validate
results_lfp = kaa_validateLFPOutput(data_lfp, predicted_lfp);
if results_lfp.passed
    fprintf('   ✓ LFP generation test PASSED\n');
    fprintf('   Actual sampling rate: %.1f Hz\n', data_lfp.fsample);
    fprintf('   Actual samples: %d\n', length(data_lfp.time{1}));
else
    fprintf('   ✗ LFP generation test FAILED\n');
    for i = 1:length(results_lfp.errors)
        fprintf('     Error: %s\n', results_lfp.errors{i});
    end
end
for i = 1:length(results_lfp.warnings)
    fprintf('   Warning: %s\n', results_lfp.warnings{i});
end

%% Test 3: MUA Generation
fprintf('\n4. Testing MUA generation...\n');
predicted_mua = kaa_predictMUAOutput(data, spike_minfreq, rect_bandfreqs, ...
    rect_lowpassfreq, rect_samprate);
fprintf('   Expected bandpass: [%d %d] Hz\n', rect_bandfreqs(1), rect_bandfreqs(2));
fprintf('   Expected lowpass after rectification: %d Hz\n', rect_lowpassfreq);
fprintf('   Expected sampling rate: %d Hz\n', rect_samprate);
fprintf('   Expected preserved channels: %s\n', mat2str(predicted_mua.channels_preserved));
fprintf('   Expected removed channels: %s\n', mat2str(predicted_mua.channels_removed));

% Generate MUA (rectified activity)
[~, ~, data_mua] = euFT_getDerivedSignals(data, lfp_maxfreq, lfp_samprate, ...
    spike_minfreq, rect_bandfreqs, rect_lowpassfreq, rect_samprate, true);

% Validate
results_mua = kaa_validateMUAOutput(data_mua, predicted_mua);
if results_mua.passed
    fprintf('   ✓ MUA generation test PASSED\n');
    fprintf('   Actual sampling rate: %.1f Hz\n', data_mua.fsample);
    fprintf('   Actual samples: %d\n', length(data_mua.time{1}));
    
    % Check rectification
    all_positive = true;
    for ch_idx = 1:length(data_mua.label)
        if any(data_mua.trial{1}(ch_idx, :) < -1e-10)
            all_positive = false;
            break;
        end
    end
    if all_positive
        fprintf('   ✓ Data is rectified (all values >= 0)\n');
    else
        fprintf('   ✗ Data is NOT rectified\n');
    end
else
    fprintf('   ✗ MUA generation test FAILED\n');
    for i = 1:length(results_mua.errors)
        fprintf('     Error: %s\n', results_mua.errors{i});
    end
end
for i = 1:length(results_mua.warnings)
    fprintf('   Warning: %s\n', results_mua.warnings{i});
end

%% Summary
fprintf('\n=== Test Summary ===\n');
all_passed = results_notch.passed && results_lfp.passed && results_mua.passed;

if all_passed
    fprintf('✓ All preprocessing tests PASSED\n');
else
    fprintf('✗ Some preprocessing tests FAILED\n');
end

fprintf('\nTest completed.\n');

