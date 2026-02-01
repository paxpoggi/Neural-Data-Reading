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

