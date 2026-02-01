function predicted = kaa_predictNotchOutput(data, notch_freqs, notch_bw)
%KAA_PREDICTNOTCHOUTPUT Predict notch filter output
%
%   predicted = kaa_predictNotchOutput(data, notch_freqs, notch_bw)
%
%   Predicts which frequency components should be removed by notch filtering.
%   Note: This is a simplified prediction - actual brick-wall filters cause
%   ringing artifacts that are difficult to predict exactly.
%
%   Inputs:
%       data        - FieldTrip data structure
%       notch_freqs - Vector of notch center frequencies (default: [60, 120, 180])
%       notch_bw    - Notch bandwidth (default: 2.0)
%
%   Output:
%       predicted   - Structure with prediction information
%
%   Author: kaa

if nargin < 2
    notch_freqs = [60, 120, 180];
end
if nargin < 3
    notch_bw = 2.0;
end

predicted = struct();
predicted.channels_affected = [];
predicted.frequencies_removed = notch_freqs;
predicted.bandwidth = notch_bw;
predicted.original_fsample = data.fsample;

% Identify channels that contain frequencies in the notch range
% CH007: 60Hz - should be removed
% CH008: 120Hz - should be removed
predicted.channels_affected = [7, 8];  % CH007 and CH008

% Note: CH009 has 50Hz which is close to 60Hz but outside the notch band
% It should remain but may have some attenuation

end

function predicted = kaa_predictLFPOutput(data, lfp_maxfreq, lfp_samprate)
%KAA_PREDICTLFPOUTPUT Predict LFP filter output
%
%   predicted = kaa_predictLFPOutput(data, lfp_maxfreq, lfp_samprate)
%
%   Predicts which channels should be preserved in LFP output after lowpass
%   filtering at lfp_maxfreq and downsampling to lfp_samprate.
%
%   Inputs:
%       data         - FieldTrip data structure
%       lfp_maxfreq  - Lowpass corner frequency (default: 300)
%       lfp_samprate - Target sampling rate (default: 1000)
%
%   Output:
%       predicted    - Structure with prediction information
%
%   Author: kaa

if nargin < 2
    lfp_maxfreq = 300;
end
if nargin < 3
    lfp_samprate = 1000;
end

predicted = struct();
predicted.lfp_maxfreq = lfp_maxfreq;
predicted.lfp_samprate = lfp_samprate;
predicted.original_fsample = data.fsample;
predicted.downsample_factor = data.fsample / lfp_samprate;

% Channel frequencies:
% CH001: 10Hz  - < 300Hz, should be preserved
% CH002: 20Hz  - < 300Hz, should be preserved
% CH003: 100Hz - < 300Hz, should be preserved
% CH004: 1000Hz - > 300Hz, should be removed
% CH005: 2000Hz - > 300Hz, should be removed
% CH006: DC (0Hz) - should be preserved
% CH007: 60Hz - < 300Hz but already notched, may be removed
% CH008: 120Hz - < 300Hz but already notched, may be removed
% CH009: 50Hz - < 300Hz, should be preserved

predicted.channels_preserved = [1, 2, 3, 6, 9];  % Frequencies < 300Hz
predicted.channels_removed = [4, 5];  % Frequencies > 300Hz
predicted.channels_maybe_removed = [7, 8];  % Already notched

predicted.expected_nSamples = round(length(data.time{1}) / predicted.downsample_factor);

end

function predicted = kaa_predictMUAOutput(data, spike_minfreq, rect_bandfreqs, rect_lowpassfreq, rect_samprate)
%KAA_PREDICTMUAOUTPUT Predict MUA (rectified activity) output
%
%   predicted = kaa_predictMUAOutput(data, spike_minfreq, rect_bandfreqs, ...
%                                     rect_lowpassfreq, rect_samprate)
%
%   Predicts which channels should be preserved in MUA output after bandpass
%   filtering, rectification, lowpass filtering, and downsampling.
%
%   Inputs:
%       data            - FieldTrip data structure
%       spike_minfreq   - Highpass corner frequency (default: 100)
%       rect_bandfreqs  - Bandpass frequencies [low high] (default: [300 5000])
%       rect_lowpassfreq - Lowpass corner after rectification (default: 500)
%       rect_samprate   - Target sampling rate (default: 1000)
%
%   Output:
%       predicted       - Structure with prediction information
%
%   Author: kaa

if nargin < 2
    spike_minfreq = 100;
end
if nargin < 3
    rect_bandfreqs = [300, 5000];
end
if nargin < 4
    rect_lowpassfreq = 500;
end
if nargin < 5
    rect_samprate = 1000;
end

predicted = struct();
predicted.spike_minfreq = spike_minfreq;
predicted.rect_bandfreqs = rect_bandfreqs;
predicted.rect_lowpassfreq = rect_lowpassfreq;
predicted.rect_samprate = rect_samprate;
predicted.original_fsample = data.fsample;
predicted.downsample_factor = data.fsample / rect_samprate;

% MUA processing: bandpass 300-5000Hz, then rectify, then lowpass 500Hz
% Channel frequencies:
% CH001: 10Hz  - < 300Hz, should be removed
% CH002: 20Hz  - < 300Hz, should be removed
% CH003: 100Hz - < 300Hz, should be removed
% CH004: 1000Hz - in 300-5000Hz range, should be preserved and rectified
% CH005: 2000Hz - in 300-5000Hz range, should be preserved and rectified
% CH006: DC (0Hz) - < 300Hz, should be removed
% CH007: 60Hz - < 300Hz, should be removed
% CH008: 120Hz - < 300Hz, should be removed
% CH009: 50Hz - < 300Hz, should be removed

predicted.channels_preserved = [4, 5];  % Frequencies in 300-5000Hz range
predicted.channels_removed = [1, 2, 3, 6, 7, 8, 9];  % Frequencies outside band

predicted.will_be_rectified = true;  % MUA is rectified (absolute value)
predicted.expected_nSamples = round(length(data.time{1}) / predicted.downsample_factor);

end

