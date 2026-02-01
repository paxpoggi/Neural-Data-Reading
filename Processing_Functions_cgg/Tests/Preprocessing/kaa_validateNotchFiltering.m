function results = kaa_validateNotchFiltering(actual_data, predicted, tolerance_db)
%KAA_VALIDATENOTCHFILTERING Validate notch filter output
%
%   results = kaa_validateNotchFiltering(actual_data, predicted, tolerance_db)
%
%   Validates that notch filtering removed expected frequency components.
%
%   Inputs:
%       actual_data  - FieldTrip data structure after notch filtering
%       predicted    - Prediction structure from kaa_predictNotchOutput
%       tolerance_db - Tolerance in dB for frequency domain comparison (default: -40)
%
%   Output:
%       results      - Structure with validation results
%
%   Author: kaa

if nargin < 3
    tolerance_db = -40;  % 40 dB attenuation expected
end

results = struct();
results.passed = true;
results.errors = {};
results.warnings = {};

fsample = actual_data.fsample;
nSamples = length(actual_data.time{1});

% Check sampling rate is preserved
if actual_data.fsample ~= predicted.original_fsample
    results.passed = false;
    results.errors{end+1} = sprintf('Sampling rate changed: expected %d, got %d', ...
        predicted.original_fsample, actual_data.fsample);
end

% Check channel count is preserved
if length(actual_data.label) ~= 9
    results.passed = false;
    results.errors{end+1} = sprintf('Channel count changed: expected 9, got %d', ...
        length(actual_data.label));
end

% Check that 60Hz and 120Hz channels are attenuated
for ch_idx = predicted.channels_affected
    ch_data = actual_data.trial{1}(ch_idx, :);
    
    % Compute FFT
    Y = fft(ch_data);
    P = abs(Y/nSamples).^2;
    f = fsample*(0:(nSamples/2))/nSamples;
    
    % Find peak frequency
    [~, peak_idx] = max(P(1:floor(nSamples/2)+1));
    peak_freq = f(peak_idx);
    peak_power_db = 10*log10(P(peak_idx) + eps);
    
    % Check if the expected frequency is significantly attenuated
    % For 60Hz channel, check 60Hz component
    % For 120Hz channel, check 120Hz component
    expected_freq = predicted.frequencies_removed(predicted.channels_affected == ch_idx);
    
    % Find power at expected frequency
    freq_idx = find(abs(f - expected_freq) < 1, 1);
    if ~isempty(freq_idx)
        freq_power_db = 10*log10(P(freq_idx) + eps);
        
        % Check if attenuated by at least tolerance_db
        if freq_power_db > tolerance_db
            results.passed = false;
            results.errors{end+1} = sprintf('Channel %d (%s): %d Hz component not sufficiently attenuated (%.1f dB)', ...
                ch_idx, actual_data.label{ch_idx}, expected_freq, freq_power_db);
        end
    end
end

end

