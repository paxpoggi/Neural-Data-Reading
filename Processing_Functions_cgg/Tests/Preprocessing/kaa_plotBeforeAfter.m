function kaa_plotBeforeAfter(before_data, after_data, channel_idx, varargin)
%KAA_PLOTBEFOREAFTER Plot before/after comparison for filtering operations
%
%   kaa_plotBeforeAfter(before_data, after_data, channel_idx)
%
%   Creates a 2x2 subplot showing:
%   - Before time series
%   - After time series
%   - Before frequency spectrum
%   - After frequency spectrum
%
%   Inputs:
%       before_data - FieldTrip data structure (before processing)
%       after_data  - FieldTrip data structure (after processing)
%       channel_idx - Channel index (1-based) or channel label
%
%   Optional Parameters:
%       title       - Overall title (default: auto-generated)
%       freq_range  - Frequency range for spectrum plots (default: [0 200])
%
%   Author: kaa

% Parse optional parameters
title_str = '';
freq_range = [0 200];

for i = 1:2:length(varargin)
    if i+1 <= length(varargin)
        switch lower(varargin{i})
            case 'title'
                title_str = varargin{i+1};
            case 'freq_range'
                freq_range = varargin{i+1};
        end
    end
end

% Get channel label
if isnumeric(channel_idx)
    ch_label = before_data.label{channel_idx};
else
    ch_idx = find(strcmp(before_data.label, channel_idx));
    if isempty(ch_idx)
        error('Channel %s not found', channel_idx);
    end
    ch_label = before_data.label{ch_idx};
    channel_idx = ch_idx;
end

% Create figure
fig_handle = figure('Position', [100, 100, 1200, 800]);

% Plot 1: Before time series
subplot(2, 2, 1);
kaa_plotTimeSeries(before_data, channel_idx, 'figure_handle', fig_handle, ...
    'title', sprintf('Before: %s', ch_label));

% Plot 2: After time series
subplot(2, 2, 2);
kaa_plotTimeSeries(after_data, channel_idx, 'figure_handle', fig_handle, ...
    'title', sprintf('After: %s', ch_label));

% Plot 3: Before frequency spectrum
subplot(2, 2, 3);
kaa_plotFrequencySpectrum(before_data, channel_idx, 'figure_handle', fig_handle, ...
    'title', sprintf('Before: %s Spectrum', ch_label), 'freq_range', freq_range);

% Plot 4: After frequency spectrum
subplot(2, 2, 4);
kaa_plotFrequencySpectrum(after_data, channel_idx, 'figure_handle', fig_handle, ...
    'title', sprintf('After: %s Spectrum', ch_label), 'freq_range', freq_range);

% Set overall title
if ~isempty(title_str)
    sgtitle(title_str, 'FontSize', 14, 'FontWeight', 'bold');
end

end

