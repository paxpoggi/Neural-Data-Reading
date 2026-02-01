function results = kaa_validateLFPOutput(actual_data, predicted, tolerance)
%KAA_VALIDATELFPOUTPUT Validate LFP output
%
%   results = kaa_validateLFPOutput(actual_data, predicted, tolerance)
%
%   Validates that LFP output has correct sampling rate and frequency content.
%
%   Inputs:
%       actual_data  - FieldTrip data structure after LFP processing
%       predicted    - Prediction structure from kaa_predictLFPOutput
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
if abs(actual_data.fsample - predicted.lfp_samprate) > tolerance * predicted.lfp_samprate
    results.passed = false;
    results.errors{end+1} = sprintf('Sampling rate incorrect: expected %.1f Hz, got %.1f Hz', ...
        predicted.lfp_samprate, actual_data.fsample);
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

% Check that high frequency channels are attenuated
fsample = actual_data.fsample;
nSamples = actual_nSamples;

for ch_idx = predicted.channels_removed
    ch_data = actual_data.trial{1}(ch_idx, :);
    
    % Compute FFT
    Y = fft(ch_data);
    P = abs(Y/nSamples).^2;
    f = fsample*(0:(nSamples/2))/nSamples;
    
    % Find power above cutoff frequency
    above_cutoff = f > predicted.lfp_maxfreq;
    power_above_cutoff = sum(P(above_cutoff));
    total_power = sum(P);
    
    % High frequency power should be significantly reduced
    if power_above_cutoff / total_power > 0.1  % More than 10% above cutoff
        results.warnings{end+1} = sprintf('Channel %d (%s): Significant power above %d Hz cutoff', ...
            ch_idx, actual_data.label{ch_idx}, predicted.lfp_maxfreq);
    end
end

end

