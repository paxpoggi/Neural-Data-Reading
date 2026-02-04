function kaa_plotStackedChannels(cfg, Signal_Types, Trial_Range, varargin)
%KAA_PLOTSTACKEDCHANNELS Plot all channels stacked vertically (waterfall style)
%
%   Creates a stacked line plot where each channel is offset vertically
%   but lines can overlap based on amplitude. X-axis is time (full width),
%   Y-axis shows stacked channel values.
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
%     'Y_Offset_Range' - Vertical spacing between channels (default: auto)
%
%   Author: KAA

% Parse optional parameters
Figure_Width = CheckVararginPairs('Figure_Width', 1920, varargin{:});
Figure_Height = CheckVararginPairs('Figure_Height', 1080, varargin{:});
Line_Width = CheckVararginPairs('Line_Width', 0.5, varargin{:});
Show_Figures = CheckVararginPairs('Show_Figures', false, varargin{:});
Y_Offset_Range = CheckVararginPairs('Y_Offset_Range', [], varargin{:});

%% Process each session
for sidx = 1:length(cfg)
    
    outdatadir = cfg(sidx).outdatadir;
    ExperimentName = cfg(sidx).ExperimentName;
    SessionName = cfg(sidx).SessionName;
    
    fprintf('\n=== Processing Session: %s (Stacked Plots) ===\n', SessionName);
    
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
                warning('Failed to load disconnected channels: %s', ME.message);
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
            
            % Create output folder (same as trial channels)
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
                    
                    % Get time vector if available
                    if isfield(ft_struct, 'time') && ~isempty(ft_struct.time)
                        time_vec = ft_struct.time{1};
                    else
                        time_vec = 1:nSamples;
                    end
                    
                    % Calculate Y offset range (spacing between channels)
                    % Use the range of the data to determine spacing
                    data_range = max(data_matrix(:)) - min(data_matrix(:));
                    if isempty(Y_Offset_Range)
                        y_offset = data_range * 1.2; % 20% spacing between channels
                    else
                        y_offset = Y_Offset_Range;
                    end
                    
                    % Create figure
                    if Show_Figures
                        fig = figure('Position', [100, 100, Figure_Width, Figure_Height]);
                    else
                        fig = figure('Position', [100, 100, Figure_Width, Figure_Height], 'Visible', 'off');
                    end
                    
                    hold on;
                    
                    % Plot each channel stacked vertically
                    for ch_idx = 1:nChannels
                        % Calculate vertical offset (channels stacked from bottom to top)
                        y_offset_value = (nChannels - ch_idx) * y_offset;
                        
                        % Offset the data
                        stacked_data = data_matrix(ch_idx, :) + y_offset_value;
                        
                        % Check if this channel is disconnected
                        is_disconnected = ~isempty(Disconnected_Channels) && ismember(ch_idx, Disconnected_Channels);
                        
                        if is_disconnected
                            % Plot disconnected channels in red with alpha
                            try
                                plot(time_vec, stacked_data, 'LineWidth', Line_Width, ...
                                    'Color', [1, 0, 0, 0.6]);
                            catch
                                plot(time_vec, stacked_data, 'LineWidth', Line_Width, ...
                                    'Color', [1, 0, 0]);
                            end
                        else
                            % Plot normal channels in default color
                            plot(time_vec, stacked_data, 'LineWidth', Line_Width);
                        end
                    end
                    
                    hold off;
                    
                    % Set labels and title
                    xlabel('Time', 'FontSize', 12);
                    ylabel('Channel (stacked)', 'FontSize', 12);
                    title(sprintf('%s - %s - %s - Trial %d (Stacked, %d channels)', ...
                        SessionName, this_probe_area, this_signal_type, trial_num, nChannels), ...
                        'FontSize', 10, 'Interpreter', 'none');
                    
                    % Set Y-axis ticks to show channel numbers
                    y_ticks = (nChannels:-1:1) * y_offset;
                    y_tick_labels = arrayfun(@(x) sprintf('Ch %d', x), nChannels:-1:1, 'UniformOutput', false);
                    set(gca, 'YTick', y_ticks, 'YTickLabel', y_tick_labels);
                    
                    % Set X-axis to use full width
                    xlim([time_vec(1), time_vec(end)]);
                    
                    grid on;
                    set(gca, 'FontSize', 8);
                    
                    % Save figure as PNG
                    output_file_name = sprintf('%s_Stacked_Trial_%d.png', this_signal_type, trial_num);
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

fprintf('\n=== Stacked channel plotting complete ===\n');

end

