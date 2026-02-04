function kaa_plotStackedPSD(cfg, Signal_Types, Trial_Range, varargin)
%KAA_PLOTSTACKEDPSD Plot power spectral density for all channels in vertical subplots
%
%   Creates a figure with vertical subplots, one per channel. Each subplot
%   shows the power spectral density (PSD) for that channel. X-axis is frequency,
%   Y-axis is power (independent for each channel). Disconnected channels are
%   marked in red.
%
%   Inputs:
%     cfg          - Session configuration from DATA_cggAllSessionInformationConfiguration
%     Signal_Types - Cell array of signal types (e.g., {'MUA', 'LFP'})
%     Trial_Range  - Array of trial numbers to process (e.g., 1:5)
%
%   Optional Name-Value pairs:
%     'Figure_Width'  - Figure width in pixels (default: 1920)
%     'Figure_Height' - Figure height in pixels (default: 1080)
%     'Line_Width'    - Line width for plots (default: 0.5)
%     'Show_Figures'  - Show figures while processing (default: false)
%     'PSD_Method'    - Method for PSD: 'pwelch' (default) or 'pspectrum'
%     'Window_Length' - Window length for pwelch in samples (default: auto)
%     'Overlap'       - Overlap fraction for pwelch (default: 0.5)
%
%   Author: KAA

% Parse optional parameters
Figure_Width = CheckVararginPairs('Figure_Width', 1920, varargin{:});
Figure_Height = CheckVararginPairs('Figure_Height', 1080, varargin{:});
Line_Width = CheckVararginPairs('Line_Width', 0.5, varargin{:});
Show_Figures = CheckVararginPairs('Show_Figures', false, varargin{:});
PSD_Method = CheckVararginPairs('PSD_Method', 'pwelch', varargin{:});
Window_Length = CheckVararginPairs('Window_Length', [], varargin{:});
Overlap = CheckVararginPairs('Overlap', 0.5, varargin{:});

%% Process each session
for sidx = 1:length(cfg)
    
    outdatadir = cfg(sidx).outdatadir;
    ExperimentName = cfg(sidx).ExperimentName;
    SessionName = cfg(sidx).SessionName;
    
    fprintf('\n=== Processing Session: %s (PSD Plots) ===\n', SessionName);
    
    % Get the session output folder path
    session_path = fullfile(outdatadir, ExperimentName, SessionName, 'Activity');
    
    % Check if session path exists
    if ~exist(session_path, 'dir')
        warning('Session path does not exist: %s. Skipping.', session_path);
        continue;
    end
    
    % Get all probe areas for this session
    probe_area_folders = dir(session_path);
    probe_area_folders = probe_area_folders([probe_area_folders.isdir]);
    probe_area_folders = probe_area_folders(~ismember({probe_area_folders.name}, {'.', '..'}));
    
    if isempty(probe_area_folders)
        warning('No probe areas found in: %s. Skipping.', session_path);
        continue;
    end
    
    %% Loop through probe areas
    for pidx = 1:length(probe_area_folders)
        this_probe_area = probe_area_folders(pidx).name;
        probe_area_path = fullfile(session_path, this_probe_area);
        
        fprintf('  Processing Probe Area: %s\n', this_probe_area);
        
        % Load disconnected channels for this probe area
        clustering_file_path = fullfile(probe_area_path, 'Connected', 'Clustering_Results.mat');
        Disconnected_Channels = [];
        if exist(clustering_file_path, 'file')
            try
                clustering_data = load(clustering_file_path);
                if isfield(clustering_data, 'Disconnected_Channels')
                    Disconnected_Channels = clustering_data.Disconnected_Channels(:);
                    fprintf('    Loaded %d disconnected channels: [%s]\n', ...
                        numel(Disconnected_Channels), num2str(Disconnected_Channels'));
                end
            catch ME
                warning(ME.identifier, 'Failed to load disconnected channels: %s', ME.message);
            end
        end
        
        %% Loop through signal types
        for stidx = 1:length(Signal_Types)
            this_signal_type = Signal_Types{stidx};
            signal_type_path = fullfile(probe_area_path, this_signal_type);
            
            % Check if signal type folder exists
            if ~exist(signal_type_path, 'dir')
                fprintf('    Signal type folder not found: %s. Skipping.\n', this_signal_type);
                continue;
            end
            
            fprintf('    Processing Signal Type: %s\n', this_signal_type);
            
            % Create output folder
            output_base = strrep(outdatadir, 'Data_Neural', 'debug_plots');
            output_path = fullfile(output_base, ExperimentName, SessionName, 'Activity', this_probe_area, this_signal_type);
            
            if ~exist(output_path, 'dir')
                mkdir(output_path);
            end
            
            % Find all trial files
            trial_files = dir(fullfile(signal_type_path, [this_signal_type '_Trial_*.mat']));
            
            if isempty(trial_files)
                fprintf('      No trial files found. Skipping.\n');
                continue;
            end
            
            % Extract trial numbers from filenames
            trial_numbers = zeros(1, length(trial_files));
            for tidx = 1:length(trial_files)
                tokens = regexp(trial_files(tidx).name, '_Trial_(\d+)\.mat', 'tokens');
                if ~isempty(tokens)
                    trial_numbers(tidx) = str2double(tokens{1}{1});
                end
            end
            
            % Filter to only requested trials
            trials_to_process = intersect(trial_numbers, Trial_Range);
            trials_to_process = sort(trials_to_process);
            
            if isempty(trials_to_process)
                fprintf('      No matching trials in Trial_Range. Skipping.\n');
                continue;
            end
            
            fprintf('      Found %d trials to process.\n', length(trials_to_process));
            
            %% Process each trial
            for trial_idx = 1:length(trials_to_process)
                trial_num = trials_to_process(trial_idx);
                trial_file_name = sprintf('%s_Trial_%d.mat', this_signal_type, trial_num);
                trial_file_path = fullfile(signal_type_path, trial_file_name);
                
                if ~exist(trial_file_path, 'file')
                    warning('Trial file not found: %s', trial_file_path);
                    continue;
                end
                
                fprintf('      Processing Trial %d...\n', trial_num);
                
                try
                    % Load the trial file
                    trial_data = load(trial_file_path);
                    
                    % Find the FieldTrip structure variable
                    field_names = fieldnames(trial_data);
                    ft_struct = [];
                    
                    for fn_idx = 1:length(field_names)
                        candidate = trial_data.(field_names{fn_idx});
                        if isstruct(candidate) && isfield(candidate, 'trial') && isfield(candidate, 'label')
                            ft_struct = candidate;
                            break;
                        end
                    end
                    
                    if isempty(ft_struct)
                        warning('No FieldTrip structure found in: %s', trial_file_path);
                        continue;
                    end
                    
                    % Extract data matrix [nChannels x nSamples]
                    data_matrix = ft_struct.trial{1};
                    [nChannels, nSamples] = size(data_matrix);
                    
                    % Get sampling rate
                    if isfield(ft_struct, 'fsample') && ~isempty(ft_struct.fsample)
                        fs = ft_struct.fsample;
                    elseif isfield(ft_struct, 'hdr') && isfield(ft_struct.hdr, 'Fs')
                        fs = ft_struct.hdr.Fs;
                    else
                        % Try to infer from time vector
                        if isfield(ft_struct, 'time') && ~isempty(ft_struct.time)
                            time_vec = ft_struct.time{1};
                            if length(time_vec) > 1
                                fs = 1 / (time_vec(2) - time_vec(1));
                            else
                                warning('Cannot determine sampling rate. Using default 30000 Hz.');
                                fs = 30000;
                            end
                        else
                            warning('Cannot determine sampling rate. Using default 30000 Hz.');
                            fs = 30000;
                        end
                    end
                    
                    % Calculate expanded figure height
                    height_per_channel = 200;
                    expanded_height = height_per_channel * nChannels;
                    max_height = 50000;
                    expanded_height = min(expanded_height, max_height);
                    
                    % Create figure with vertical subplots (one per channel)
                    if Show_Figures
                        fig = figure('Position', [100, 100, Figure_Width, expanded_height]);
                    else
                        fig = figure('Position', [100, 100, Figure_Width, expanded_height], 'Visible', 'off');
                    end
                    
                    % Set paper size for printing large figures
                    fig.PaperUnits = 'points';
                    fig.PaperSize = [Figure_Width, expanded_height];
                    fig.PaperPosition = [0, 0, Figure_Width, expanded_height];
                    
                    % Set overall title
                    sgtitle(sprintf('%s - %s - %s - Trial %d PSD (%d channels, fs=%.1f Hz)', ...
                        SessionName, this_probe_area, this_signal_type, trial_num, nChannels, fs), ...
                        'FontSize', 14, 'Interpreter', 'none');
                    
                    % Determine window length for pwelch if not specified
                    if isempty(Window_Length)
                        % Use a reasonable window length (e.g., 1/8 of the data length)
                        Window_Length = max(256, round(nSamples / 8));
                    end
                    
                    % Create vertical subplots with increased spacing
                    for ch_idx = 1:nChannels
                        % Calculate subplot position with spacing
                        subplot_height = 0.9 / nChannels;
                        subplot_bottom = 0.05 + (nChannels - ch_idx) * (0.9 / nChannels);
                        
                        % Create subplot with specific position
                        subplot('Position', [0.1, subplot_bottom, 0.85, subplot_height]);
                        
                        % Compute PSD for this channel
                        channel_data = data_matrix(ch_idx, :);
                        
                        % Remove NaN and Inf values
                        valid_idx = isfinite(channel_data);
                        if sum(valid_idx) < Window_Length
                            warning('Channel %d has insufficient valid samples for PSD', ch_idx);
                            continue;
                        end
                        channel_data = channel_data(valid_idx);
                        
                        % Compute PSD
                        if strcmpi(PSD_Method, 'pspectrum')
                            % Use pspectrum (requires Signal Processing Toolbox)
                            try
                                [pxx, f] = pspectrum(channel_data, fs);
                            catch
                                % Fallback to pwelch if pspectrum fails
                                [pxx, f] = pwelch(channel_data, Window_Length, round(Window_Length * Overlap), [], fs);
                            end
                        else
                            % Use pwelch (default)
                            [pxx, f] = pwelch(channel_data, Window_Length, round(Window_Length * Overlap), [], fs);
                        end
                        
                        % Check if this channel is disconnected
                        is_disconnected = ~isempty(Disconnected_Channels) && ismember(ch_idx, Disconnected_Channels);
                        
                        if is_disconnected
                            % Plot disconnected channels in red with alpha
                            try
                                semilogy(f, pxx, 'LineWidth', Line_Width, 'Color', [1, 0, 0, 0.6]);
                            catch
                                semilogy(f, pxx, 'LineWidth', Line_Width, 'Color', [1, 0, 0]);
                            end
                            title(sprintf('Ch %d', ch_idx), 'FontSize', 12, 'Color', [0.8, 0, 0]);
                        else
                            % Plot normal channels in default color
                            semilogy(f, pxx, 'LineWidth', Line_Width);
                            title(sprintf('Ch %d', ch_idx), 'FontSize', 12);
                        end
                        
                        % Set axis properties
                        axis tight;
                        set(gca, 'FontSize', 10);
                        grid on;
                        
                        % Only show xlabel on bottom subplot
                        if ch_idx == nChannels
                            xlabel('Frequency (Hz)', 'FontSize', 12);
                        else
                            set(gca, 'XTickLabel', []);
                        end
                        
                        % Y-axis is independent for each subplot (not shared)
                        ylabel(sprintf('PSD Ch %d', ch_idx), 'FontSize', 10);
                    end
                    
                    % Save figure as PNG
                    output_file_name = sprintf('%s_PSD_Trial_%d.png', this_signal_type, trial_num);
                    output_file_path = fullfile(output_path, output_file_name);
                    
                    print(fig, output_file_path, '-dpng', '-r150');
                    close(fig);
                    
                    fprintf('        Saved: %s\n', output_file_name);
                    
                catch ME
                    warning('Error processing trial %d: %s', trial_num, ME.message);
                    if exist('fig', 'var') && ishandle(fig)
                        close(fig);
                    end
                end
                
            end % trial loop
            
        end % signal type loop
        
    end % probe area loop
    
end % session loop

fprintf('\n=== Stacked PSD plotting complete ===\n');

end

