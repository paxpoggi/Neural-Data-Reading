function kaa_plotChannelComparison(data, channel_indices, varargin)
%KAA_PLOTCHANNELCOMPARISON Compare multiple channels side by side
%
%   kaa_plotChannelComparison(data, channel_indices)
%
%   Creates a comparison plot showing time series and frequency spectra for
%   multiple channels, useful for comparing good vs artifact channels.
%
%   Inputs:
%       data           - FieldTrip data structure
%       channel_indices - Vector of channel indices to compare
%
%   Optional Parameters:
%       time_range     - Time range to plot [start end] in seconds (default: [0 0.1])
%       freq_range     - Frequency range for spectra [min max] (default: [0 200])
%       title_str      - Plot title (default: auto-generated)
%       channel_labels - Custom labels for channels (default: use data.label)
%
%   Author: kaa

% Parse optional parameters
time_range = [0, 0.1];
freq_range = [0, 200];
title_str = '';
channel_labels = {};

for i = 1:2:length(varargin)
    if i+1 <= length(varargin)
        switch lower(varargin{i})
            case 'time_range'
                time_range = varargin{i+1};
            case 'freq_range'
                freq_range = varargin{i+1};
            case 'title'
                title_str = varargin{i+1};
            case 'channel_labels'
                channel_labels = varargin{i+1};
        end
    end
end

n_channels = length(channel_indices);
if isempty(channel_labels)
    channel_labels = data.label(channel_indices);
end

% Create figure
fig_handle = figure('Position', [100, 100, 1200, 400*n_channels], ...
    'Name', 'Channel Comparison');

% Plot time series
for i = 1:n_channels
    subplot(n_channels, 2, (i-1)*2 + 1);
    ch_idx = channel_indices(i);
    ch_data = data.trial{1}(ch_idx, :);
    time_vector = data.time{1};
    
    % Set time range
    time_mask = (time_vector >= time_range(1)) & (time_vector <= time_range(2));
    
    % Plot
    plot(time_vector(time_mask), ch_data(time_mask), 'b-', 'LineWidth', 1);
    xlabel('Time (s)');
    ylabel('Amplitude');
    title(sprintf('Time Series: %s', channel_labels{i}));
    grid on;
    
    % Add zero line
    hold on;
    plot(time_vector(time_mask), zeros(sum(time_mask), 1), 'k--', 'LineWidth', 0.5);
    hold off;
end

% Plot frequency spectra
for i = 1:n_channels
    subplot(n_channels, 2, (i-1)*2 + 2);
    ch_idx = channel_indices(i);
    ch_data = data.trial{1}(ch_idx, :);
    fsample = data.fsample;
    nSamples = length(ch_data);
    
    % Compute FFT
    Y = fft(ch_data);
    P = abs(Y/nSamples).^2;
    f = fsample*(0:(nSamples/2))/nSamples;
    P_one_sided = P(1:floor(nSamples/2)+1);
    P_db = 10*log10(P_one_sided + eps);
    
    % Set frequency range
    freq_mask = (f >= freq_range(1)) & (f <= freq_range(2));
    
    % Plot
    plot(f(freq_mask), P_db(freq_mask), 'r-', 'LineWidth', 1.5);
    xlabel('Frequency (Hz)');
    ylabel('Power (dB)');
    title(sprintf('Spectrum: %s', channel_labels{i}));
    grid on;
end

% Set overall title
if isempty(title_str)
    title_str = sprintf('Channel Comparison (%d channels)', n_channels);
end
sgtitle(title_str, 'FontSize', 14, 'FontWeight', 'bold');

end

