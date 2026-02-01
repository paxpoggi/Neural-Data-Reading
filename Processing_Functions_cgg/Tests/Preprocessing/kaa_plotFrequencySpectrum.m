function kaa_plotFrequencySpectrum(data, channel_idx, varargin)
%KAA_PLOTFREQUENCYSPECTRUM Plot frequency spectrum of a channel
%
%   kaa_plotFrequencySpectrum(data, channel_idx)
%   kaa_plotFrequencySpectrum(data, channel_idx, 'title', 'Custom Title')
%
%   Plots the power spectral density of a specific channel.
%
%   Inputs:
%       data        - FieldTrip data structure
%       channel_idx - Channel index (1-based) or channel label
%   
%   Optional Parameters:
%       title       - Plot title (default: auto-generated)
%       freq_range  - Frequency range to plot [min max] (default: [0 fsample/2])
%       yscale      - Y-axis scale: 'linear' or 'log' (default: 'log')
%       figure_handle - Figure handle to plot in (default: new figure)
%
%   Author: kaa

% Parse optional parameters
title_str = '';
freq_range = [];
yscale = 'log';
fig_handle = [];

for i = 1:2:length(varargin)
    if i+1 <= length(varargin)
        switch lower(varargin{i})
            case 'title'
                title_str = varargin{i+1};
            case 'freq_range'
                freq_range = varargin{i+1};
            case 'yscale'
                yscale = varargin{i+1};
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

fsample = data.fsample;
nSamples = length(ch_data);

% Compute FFT
Y = fft(ch_data);
P = abs(Y/nSamples).^2;
f = fsample*(0:(nSamples/2))/nSamples;
P_one_sided = P(1:floor(nSamples/2)+1);

% Convert to dB
P_db = 10*log10(P_one_sided + eps);

% Set frequency range
if isempty(freq_range)
    freq_range = [0, fsample/2];
end
freq_mask = (f >= freq_range(1)) & (f <= freq_range(2));

% Create or use figure
if isempty(fig_handle)
    fig_handle = figure;
else
    figure(fig_handle);
end

% Plot
plot(f(freq_mask), P_db(freq_mask), 'b-', 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('Power Spectral Density (dB)');
grid on;

% Set title
if isempty(title_str)
    title_str = sprintf('Frequency Spectrum: %s (fs=%.0f Hz)', ch_label, fsample);
end
title(title_str);

% Set y-axis scale
if ~strcmpi(yscale, 'log')
    ylabel('Power Spectral Density');
    semilogy(f(freq_mask), P_one_sided(freq_mask) + eps);
end

end

