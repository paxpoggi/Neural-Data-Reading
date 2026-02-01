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

