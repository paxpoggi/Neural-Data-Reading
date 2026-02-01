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

function results = kaa_validateArtifactDetection(connected_channels, disconnected_channels, expected_disconnected)
%KAA_VALIDATEARTIFACTDETECTION Validate artifact channel detection
%
%   results = kaa_validateArtifactDetection(connected_channels, disconnected_channels, expected_disconnected)
%
%   Validates that artifact channels (DC, high amplitude) are correctly detected.
%
%   Inputs:
%       connected_channels    - Vector of connected channel indices
%       disconnected_channels  - Vector of disconnected channel indices
%       expected_disconnected  - Vector of expected disconnected channel indices (default: [6, 9])
%
%   Output:
%       results               - Structure with validation results
%
%   Author: kaa

if nargin < 3
    expected_disconnected = [6, 9];  % CH006 (DC) and CH009 (high amplitude)
end

results = struct();
results.passed = true;
results.errors = {};
results.warnings = {};

% Check that expected disconnected channels are in disconnected list
for ch_idx = expected_disconnected
    if ~ismember(ch_idx, disconnected_channels)
        results.passed = false;
        results.errors{end+1} = sprintf('Channel %d (expected to be disconnected) not detected as disconnected', ch_idx);
    end
end

% Check that good channels are not in disconnected list
expected_connected = setdiff(1:9, expected_disconnected);
for ch_idx = expected_connected
    if ismember(ch_idx, disconnected_channels)
        results.warnings{end+1} = sprintf('Channel %d (expected to be connected) detected as disconnected', ch_idx);
    end
end

% Verify no overlap between connected and disconnected
overlap = intersect(connected_channels, disconnected_channels);
if ~isempty(overlap)
    results.passed = false;
    results.errors{end+1} = sprintf('Overlap between connected and disconnected channels: %s', mat2str(overlap));
end

% Verify all channels are accounted for
all_channels = union(connected_channels, disconnected_channels);
if length(all_channels) ~= 9 || ~isequal(sort(all_channels), 1:9)
    results.passed = false;
    results.errors{end+1} = 'Not all channels accounted for in connected/disconnected lists';
end

end

