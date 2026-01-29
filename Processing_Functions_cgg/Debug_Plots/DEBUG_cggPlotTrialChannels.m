%% DEBUG_cggPlotTrialChannels
% Debug script to visualize all channels for each trial across signal types.
% Generates subplot figures showing each channel's time series and saves as PNG.
%
% Output folder structure mirrors input but under 'debug_plots' instead of 'Data_Neural':
%   Input:  processed_data/Data_Neural/Experiment/Session/Activity/ProbeArea/SignalType/
%   Output: processed_data/debug_plots/Experiment/Session/Activity/ProbeArea/SignalType/
%
% Outputs per signal type:
%   - Individual trial plots: SignalType_Trial_X.png
%   - Average across trials: SignalType_Average_Trials_X-Y.png

clc; clear; close all;

%% =========================================================================
% CONFIGURABLE PARAMETERS - Modify these as needed
% =========================================================================

% Which signal types to plot (options: 'WideBand', 'Raw', 'Notch', 'LFP', 'MUA')
Signal_Types = {'WideBand', 'Raw', 'Notch'};

% Which trials to plot (can be a range like 1:10, or specific numbers like [1, 5, 10])
Trial_Range = 1:5;

% Figure settings
Figure_Width = 1920;   % pixels
Figure_Height = 1080;  % pixels

% Plot settings
Line_Width = 0.5;
Font_Size = 6;

% Set to true to show figures while processing (slower), false to hide
Show_Figures = false;

% =========================================================================
% END OF CONFIGURABLE PARAMETERS
% =========================================================================

%% Load session configuration
[cfg] = DATA_cggAllSessionInformationConfiguration;

%% Process each session
for sidx = 1:length(cfg)
    
    inputfolder = cfg(sidx).inputfolder;
    outdatadir = cfg(sidx).outdatadir;
    ExperimentName = cfg(sidx).ExperimentName;
    SessionName = cfg(sidx).SessionName;
    
    fprintf('\n=== Processing Session: %s ===\n', SessionName);
    
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
            
            % Create output folder (replace Data_Neural with debug_plots)
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
            trials_to_process = sort(trials_to_process);  % Ensure sorted order
            
            if isempty(trials_to_process)
                fprintf('      No matching trials in Trial_Range. Skipping.\n');
                continue;
            end
            
            fprintf('      Found %d trials to process.\n', length(trials_to_process));
            
            % Storage for computing average across trials
            all_trials_data = {};
            common_time_vec = [];
            common_nChannels = 0;
            channel_order = [];
            ordered_labels = {};
            
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
                    
                    % Get channel labels if available
                    if isfield(ft_struct, 'label')
                        channel_labels = ft_struct.label;
                    else
                        channel_labels = arrayfun(@(x) sprintf('Ch%d', x), 1:nChannels, 'UniformOutput', false);
                    end
                    
                    % Sort channels by numeric order (Channel 1, 2, 3, ...)
                    % Extract numeric part from labels for sorting
                    channel_nums = zeros(1, nChannels);
                    for ch_idx = 1:nChannels
                        if iscell(channel_labels)
                            label_str = channel_labels{ch_idx};
                        else
                            label_str = sprintf('%d', ch_idx);
                        end
                        % Extract number from label (e.g., 'Chan001' -> 1, 'Ch_32' -> 32)
                        num_tokens = regexp(label_str, '(\d+)', 'tokens');
                        if ~isempty(num_tokens)
                            channel_nums(ch_idx) = str2double(num_tokens{end}{1});
                        else
                            channel_nums(ch_idx) = ch_idx;
                        end
                    end
                    
                    % Get sorting order
                    [~, sort_order] = sort(channel_nums);
                    
                    % Reorder data and labels
                    data_matrix_ordered = data_matrix(sort_order, :);
                    if iscell(channel_labels)
                        channel_labels_ordered = channel_labels(sort_order);
                    else
                        channel_labels_ordered = arrayfun(@(x) sprintf('Ch%d', x), sort_order, 'UniformOutput', false);
                    end
                    
                    % Store for averaging
                    all_trials_data{end+1} = data_matrix_ordered;
                    if isempty(common_time_vec)
                        common_time_vec = time_vec;
                        common_nChannels = nChannels;
                        channel_order = sort_order;
                        ordered_labels = channel_labels_ordered;
                    end
                    
                    % Calculate subplot grid (square-ish)
                    nCols = ceil(sqrt(nChannels));
                    nRows = ceil(nChannels / nCols);
                    
                    % Create figure
                    if Show_Figures
                        fig = figure('Position', [100, 100, Figure_Width, Figure_Height]);
                    else
                        fig = figure('Position', [100, 100, Figure_Width, Figure_Height], 'Visible', 'off');
                    end
                    
                    % Set figure title
                    sgtitle(sprintf('%s - %s - %s - Trial %d (%d channels)', ...
                        SessionName, this_probe_area, this_signal_type, trial_num, nChannels), ...
                        'FontSize', 10, 'Interpreter', 'none');
                    
                    % Plot each channel in sorted order
                    for ch_idx = 1:nChannels
                        subplot(nRows, nCols, ch_idx);
                        
                        plot(time_vec, data_matrix_ordered(ch_idx, :), 'LineWidth', Line_Width);
                        
                        % Channel label as title (show channel number)
                        title(sprintf('Ch %d', ch_idx), 'FontSize', Font_Size);
                        
                        set(gca, 'FontSize', Font_Size);
                        axis tight;
                        
                        % Keep y-axis values visible for all subplots
                        % (no hiding of YTickLabel)
                    end
                    
                    % Save figure as PNG
                    output_file_name = sprintf('%s_Trial_%d.png', this_signal_type, trial_num);
                    output_file_path = fullfile(output_path, output_file_name);
                    
                    % Use print for better quality
                    print(fig, output_file_path, '-dpng', '-r150');
                    
                    % Close figure to free memory
                    close(fig);
                    
                    fprintf('        Saved: %s\n', output_file_name);
                    
                catch ME
                    warning('Error processing trial %d: %s', trial_num, ME.message);
                    if exist('fig', 'var') && ishandle(fig)
                        close(fig);
                    end
                end
                
            end % trial loop
            
            %% Create average across trials plot
            if length(all_trials_data) >= 2
                fprintf('      Creating average across trials plot...\n');
                
                try
                    % Find minimum number of samples across trials
                    min_samples = min(cellfun(@(x) size(x, 2), all_trials_data));
                    
                    % Stack all trials and compute mean
                    stacked_data = zeros(common_nChannels, min_samples, length(all_trials_data));
                    for t_idx = 1:length(all_trials_data)
                        stacked_data(:, :, t_idx) = all_trials_data{t_idx}(:, 1:min_samples);
                    end
                    avg_data = mean(stacked_data, 3);
                    
                    % Truncate time vector if needed
                    time_vec_avg = common_time_vec(1:min_samples);
                    
                    % Calculate subplot grid
                    nCols = ceil(sqrt(common_nChannels));
                    nRows = ceil(common_nChannels / nCols);
                    
                    % Create figure
                    if Show_Figures
                        fig = figure('Position', [100, 100, Figure_Width, Figure_Height]);
                    else
                        fig = figure('Position', [100, 100, Figure_Width, Figure_Height], 'Visible', 'off');
                    end
                    
                    % Set figure title
                    trial_range_str = sprintf('%d-%d', min(trials_to_process), max(trials_to_process));
                    sgtitle(sprintf('%s - %s - %s - AVERAGE (Trials %s, n=%d)', ...
                        SessionName, this_probe_area, this_signal_type, trial_range_str, length(all_trials_data)), ...
                        'FontSize', 10, 'Interpreter', 'none');
                    
                    % Plot each channel
                    for ch_idx = 1:common_nChannels
                        subplot(nRows, nCols, ch_idx);
                        
                        plot(time_vec_avg, avg_data(ch_idx, :), 'LineWidth', Line_Width, 'Color', [0.8 0.2 0.2]);
                        
                        % Channel label as title
                        title(sprintf('Ch %d', ch_idx), 'FontSize', Font_Size);
                        
                        set(gca, 'FontSize', Font_Size);
                        axis tight;
                    end
                    
                    % Save figure as PNG
                    output_file_name = sprintf('%s_Average_Trials_%s.png', this_signal_type, trial_range_str);
                    output_file_path = fullfile(output_path, output_file_name);
                    
                    print(fig, output_file_path, '-dpng', '-r150');
                    close(fig);
                    
                    fprintf('        Saved: %s\n', output_file_name);
                    
                catch ME
                    warning('Error creating average plot: %s', ME.message);
                    if exist('fig', 'var') && ishandle(fig)
                        close(fig);
                    end
                end
            end
            
        end % signal type loop
        
    end % probe area loop
    
end % session loop

fprintf('\n=== Debug plotting complete ===\n');
