function kaa_plotPreprocessingPipeline(data_raw, data_wideband, data_notch, data_lfp, data_mua, varargin)
%KAA_PLOTPREPROCESSINGPIPELINE Plot the complete preprocessing pipeline progression
%
%   kaa_plotPreprocessingPipeline(data_raw, data_wideband, data_notch, data_lfp, data_mua)
%
%   Creates a comprehensive visualization showing the progression through preprocessing steps.
%   Shows time series and frequency spectra for key channels at each stage.
%
%   Inputs:
%       data_raw      - Original raw data (can be empty)
%       data_wideband - Wideband data (after initial processing)
%       data_notch    - Notch filtered data (can be empty)
%       data_lfp      - LFP data (can be empty)
%       data_mua      - MUA data (can be empty)
%
%   Optional Parameters:
%       channels      - Channel indices to plot (default: [1, 4, 7] - good, high-freq, artifact)
%       time_range    - Time range to plot [start end] in seconds (default: [0 0.1])
%       freq_range    - Frequency range for spectra [min max] (default: [0 200])
%       title_str     - Overall title (default: 'Preprocessing Pipeline Progression')
%
%   Author: kaa

% Parse optional parameters
channels = [1, 4, 7];  % Good channel (10Hz), High-freq channel (1000Hz), Artifact (60Hz)
time_range = [0, 0.1];
freq_range = [0, 200];
title_str = 'Preprocessing Pipeline Progression';

for i = 1:2:length(varargin)
    if i+1 <= length(varargin)
        switch lower(varargin{i})
            case 'channels'
                channels = varargin{i+1};
            case 'time_range'
                time_range = varargin{i+1};
            case 'freq_range'
                freq_range = varargin{i+1};
            case 'title'
                title_str = varargin{i+1};
        end
    end
end

% Determine which stages are available
stages = {};
stage_data = {};
stage_names = {};

if ~isempty(data_raw)
    stages{end+1} = 'Raw';
    stage_data{end+1} = data_raw;
    stage_names{end+1} = 'Raw Input';
end

if ~isempty(data_wideband)
    stages{end+1} = 'Wideband';
    stage_data{end+1} = data_wideband;
    stage_names{end+1} = 'Wideband';
end

if ~isempty(data_notch)
    stages{end+1} = 'Notch';
    stage_data{end+1} = data_notch;
    stage_names{end+1} = 'Notch Filtered';
end

if ~isempty(data_lfp)
    stages{end+1} = 'LFP';
    stage_data{end+1} = data_lfp;
    stage_names{end+1} = 'LFP (Lowpass 300Hz)';
end

if ~isempty(data_mua)
    stages{end+1} = 'MUA';
    stage_data{end+1} = data_mua;
    stage_names{end+1} = 'MUA (Rectified)';
end

n_stages = length(stages);
n_channels = length(channels);

if n_stages == 0
    warning('No data provided for plotting');
    return;
end

% Create figure with subplots: rows = channels, cols = 2*stages (time + spectrum)
fig_handle = figure('Position', [50, 50, 400*n_stages, 300*n_channels], ...
    'Name', 'Preprocessing Pipeline Visualization');

% Plot each channel
for ch_plot_idx = 1:n_channels
    ch_idx = channels(ch_plot_idx);
    
    % Plot time series for each stage
    for stage_idx = 1:n_stages
        subplot(n_channels, n_stages*2, (ch_plot_idx-1)*n_stages*2 + stage_idx);
        
        data = stage_data{stage_idx};
        stage_name = stages{stage_idx};
        
        % Get channel data
        if ch_idx <= length(data.label)
            ch_data = data.trial{1}(ch_idx, :);
            ch_label = data.label{ch_idx};
            time_vector = data.time{1};
            
            % Set time range
            time_mask = (time_vector >= time_range(1)) & (time_vector <= time_range(2));
            
            % Plot time series
            plot(time_vector(time_mask), ch_data(time_mask), 'b-', 'LineWidth', 1);
            xlabel('Time (s)');
            ylabel('Amplitude');
            grid on;
            
            % Title
            if ch_plot_idx == 1
                title(sprintf('%s: %s', stage_names{stage_idx}, ch_label));
            else
                title(ch_label);
            end
            
            % Add zero line
            hold on;
            plot(time_vector(time_mask), zeros(sum(time_mask), 1), 'k--', 'LineWidth', 0.5);
            hold off;
        else
            text(0.5, 0.5, 'Channel not available', 'HorizontalAlignment', 'center');
            axis off;
        end
    end
    
    % Plot frequency spectrum for each stage
    for stage_idx = 1:n_stages
        subplot(n_channels, n_stages*2, (ch_plot_idx-1)*n_stages*2 + n_stages + stage_idx);
        
        data = stage_data{stage_idx};
        stage_name = stages{stage_idx};
        
        % Get channel data
        if ch_idx <= length(data.label)
            ch_data = data.trial{1}(ch_idx, :);
            ch_label = data.label{ch_idx};
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
            
            % Plot spectrum
            plot(f(freq_mask), P_db(freq_mask), 'r-', 'LineWidth', 1.5);
            xlabel('Frequency (Hz)');
            ylabel('Power (dB)');
            grid on;
            
            % Title
            if ch_plot_idx == 1
                title(sprintf('%s Spectrum', stage_names{stage_idx}));
            else
                title('Spectrum');
            end
        else
            text(0.5, 0.5, 'Channel not available', 'HorizontalAlignment', 'center');
            axis off;
        end
    end
end

% Set overall title
sgtitle(title_str, 'FontSize', 16, 'FontWeight', 'bold');

end

