function kaa_plotTimeSeries(data, channel_idx, varargin)
%KAA_PLOTTIMESERIES Plot time series of a channel
%
%   kaa_plotTimeSeries(data, channel_idx)
%   kaa_plotTimeSeries(data, channel_idx, 'time_range', [0 0.1])
%
%   Plots the time series of a specific channel.
%
%   Inputs:
%       data        - FieldTrip data structure
%       channel_idx - Channel index (1-based) or channel label
%
%   Optional Parameters:
%       title       - Plot title (default: auto-generated)
%       time_range  - Time range to plot [start end] in seconds (default: all)
%       figure_handle - Figure handle to plot in (default: new figure)
%
%   Author: kaa

% Parse optional parameters
title_str = '';
time_range = [];
fig_handle = [];

for i = 1:2:length(varargin)
    if i+1 <= length(varargin)
        switch lower(varargin{i})
            case 'title'
                title_str = varargin{i+1};
            case 'time_range'
                time_range = varargin{i+1};
            case 'figure_handle'
                fig_handle = varargin{i+1};
        end
    end
end

% Get channel data
if isnumeric(channel_idx)
    ch_data = data.trial{1}(channel_idx, :);
    ch_label = data.label{channel_idx};
else
    ch_idx = find(strcmp(data.label, channel_idx));
    if isempty(ch_idx)
        error('Channel %s not found', channel_idx);
    end
    ch_data = data.trial{1}(ch_idx, :);
    ch_label = data.label{ch_idx};
end

time_vector = data.time{1};

% Set time range
if isempty(time_range)
    time_mask = true(size(time_vector));
else
    time_mask = (time_vector >= time_range(1)) & (time_vector <= time_range(2));
end

% Create or use figure
if isempty(fig_handle)
    fig_handle = figure;
else
    figure(fig_handle);
end

% Plot
plot(time_vector(time_mask), ch_data(time_mask), 'b-', 'LineWidth', 1);
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

% Set title
if isempty(title_str)
    title_str = sprintf('Time Series: %s', ch_label);
end
title(title_str);

% Add zero line
hold on;
plot(time_vector(time_mask), zeros(sum(time_mask), 1), 'k--', 'LineWidth', 0.5);
hold off;

end

