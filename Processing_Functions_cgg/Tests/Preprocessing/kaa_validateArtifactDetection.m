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

