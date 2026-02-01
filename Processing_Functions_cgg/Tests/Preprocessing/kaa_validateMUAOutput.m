function results = kaa_validateMUAOutput(actual_data, predicted, tolerance)
%KAA_VALIDATEMUAOUTPUT Validate MUA output
%
%   results = kaa_validateMUAOutput(actual_data, predicted, tolerance)
%
%   Validates that MUA output has correct sampling rate, rectification, and frequency content.
%
%   Inputs:
%       actual_data  - FieldTrip data structure after MUA processing
%       predicted    - Prediction structure from kaa_predictMUAOutput
%       tolerance    - Tolerance for sampling rate comparison (default: 0.01)
%
%   Output:
%       results      - Structure with validation results
%
%   Author: kaa

if nargin < 3
    tolerance = 0.01;  % 1% tolerance
end

results = struct();
results.passed = true;
results.errors = {};
results.warnings = {};

% Check sampling rate
if abs(actual_data.fsample - predicted.rect_samprate) > tolerance * predicted.rect_samprate
    results.passed = false;
    results.errors{end+1} = sprintf('Sampling rate incorrect: expected %.1f Hz, got %.1f Hz', ...
        predicted.rect_samprate, actual_data.fsample);
end

% Check number of samples (should be downsampled)
actual_nSamples = length(actual_data.time{1});
if abs(actual_nSamples - predicted.expected_nSamples) > tolerance * predicted.expected_nSamples
    results.warnings{end+1} = sprintf('Sample count differs: expected %d, got %d', ...
        predicted.expected_nSamples, actual_nSamples);
end

% Check channel count
if length(actual_data.label) ~= 9
    results.passed = false;
    results.errors{end+1} = sprintf('Channel count changed: expected 9, got %d', ...
        length(actual_data.label));
end

% Check that data is rectified (all values should be >= 0)
for ch_idx = 1:length(actual_data.label)
    ch_data = actual_data.trial{1}(ch_idx, :);
    if any(ch_data < -1e-10)  % Allow small numerical errors
        results.passed = false;
        results.errors{end+1} = sprintf('Channel %d (%s): Data not rectified (contains negative values)', ...
            ch_idx, actual_data.label{ch_idx});
        break;
    end
end

% Check that preserved channels have significant power
fsample = actual_data.fsample;
nSamples = actual_nSamples;

for ch_idx = predicted.channels_preserved
    ch_data = actual_data.trial{1}(ch_idx, :);
    
    % Compute FFT
    Y = fft(ch_data);
    P = abs(Y/nSamples).^2;
    f = fsample*(0:(nSamples/2))/nSamples;
    
    % Find power in bandpass range
    in_band = (f >= predicted.rect_bandfreqs(1)) & (f <= predicted.rect_bandfreqs(2));
    power_in_band = sum(P(in_band));
    total_power = sum(P);
    
    % Should have significant power in the band
    if power_in_band / total_power < 0.5  % Less than 50% in band
        results.warnings{end+1} = sprintf('Channel %d (%s): Low power in bandpass range [%d-%d] Hz', ...
            ch_idx, actual_data.label{ch_idx}, predicted.rect_bandfreqs(1), predicted.rect_bandfreqs(2));
    end
end

end

