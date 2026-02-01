function kaa_plotMultipleChannels(data, channel_indices, varargin)
%KAA_PLOTMULTIPLECHANNELS Plot multiple channels in subplots
%
%   kaa_plotMultipleChannels(data, channel_indices)
%
%   Plots multiple channels in a grid layout.
%
%   Inputs:
%       data           - FieldTrip data structure
%       channel_indices - Vector of channel indices or cell array of labels
%
%   Optional Parameters:
%       plot_type      - 'time' or 'spectrum' (default: 'time')
%       time_range     - Time range for time plots (default: all)
%       freq_range     - Frequency range for spectrum plots (default: [0 200])
%
%   Author: kaa

% Parse optional parameters
plot_type = 'time';
time_range = [];
freq_range = [0 200];

for i = 1:2:length(varargin)
    if i+1 <= length(varargin)
        switch lower(varargin{i})
            case 'plot_type'
                plot_type = varargin{i+1};
            case 'time_range'
                time_range = varargin{i+1};
            case 'freq_range'
                freq_range = varargin{i+1};
        end
    end
end

% Convert channel labels to indices if needed
if iscell(channel_indices)
    ch_indices = [];
    for i = 1:length(channel_indices)
        idx = find(strcmp(data.label, channel_indices{i}));
        if ~isempty(idx)
            ch_indices(end+1) = idx;
        end
    end
    channel_indices = ch_indices;
end

n_channels = length(channel_indices);
n_cols = min(3, n_channels);
n_rows = ceil(n_channels / n_cols);

fig_handle = figure('Position', [100, 100, 1200, 400*n_rows]);

for i = 1:n_channels
    subplot(n_rows, n_cols, i);
    ch_idx = channel_indices(i);
    
    if strcmpi(plot_type, 'time')
        kaa_plotTimeSeries(data, ch_idx, 'figure_handle', fig_handle, ...
            'time_range', time_range);
    else
        kaa_plotFrequencySpectrum(data, ch_idx, 'figure_handle', fig_handle, ...
            'freq_range', freq_range);
    end
end

sgtitle(sprintf('%s: %d Channels', plot_type, n_channels), ...
    'FontSize', 14, 'FontWeight', 'bold');

end

