function kaa_plotChannelCorrelations(cfg, Signal_Types, Trial_Range, varargin)
%KAA_PLOTCHANNELCORRELATIONS Plot channel-channel correlation heatmaps for each trial
%
%   kaa_plotChannelCorrelations(cfg, Signal_Types, Trial_Range)
%   kaa_plotChannelCorrelations(cfg, Signal_Types, Trial_Range, 'Name', Value, ...)
%
%   Computes correlation between all channel pairs over time and saves as heatmap PNG.
%   The correlation matrix is computed using Pearson correlation between each pair
%   of channels across all time samples within a trial.
%
%   Generates 2 subplots per trial:
%     Left:  Channels sorted by numeric label (from ft_struct.label)
%     Right: Channels in original matrix order (index 1, 2, 3, ...)
%
%   Output folder structure:
%     debug_plots/Experiment/Session/Activity/ProbeArea/Channels_Correlation/
%
%   Inputs:
%     cfg          - Session configuration from DATA_cggAllSessionInformationConfiguration
%     Signal_Types - Cell array of signal types (e.g., {'WideBand', 'Raw', 'Notch'})
%     Trial_Range  - Array of trial numbers to process (e.g., 1:5)
%
%   Optional Name-Value pairs:
%     'Figure_Width'  - Figure width in pixels (default: 2000, for side-by-side)
%     'Figure_Height' - Figure height in pixels (default: 900)
%     'Colormap'      - Colormap to use (default: 'jet')
%     'Show_Figures'  - Show figures while processing (default: false)
%
%   Author: KAA

% Parse optional parameters
Figure_Width = CheckVararginPairs('Figure_Width', 2000, varargin{:});
Figure_Height = CheckVararginPairs('Figure_Height', 900, varargin{:});
Colormap_Name = CheckVararginPairs('Colormap', 'jet', varargin{:});
Show_Figures = CheckVararginPairs('Show_Figures', false, varargin{:});

%% Process each session
for sidx = 1:length(cfg)
    
    outdatadir = cfg(sidx).outdatadir;
    ExperimentName = cfg(sidx).ExperimentName;
    SessionName = cfg(sidx).SessionName;
    
    fprintf('\n=== Processing Session: %s (Correlations) ===\n', SessionName);
    
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
            
            % Create output folder for correlations
            output_base = strrep(outdatadir, 'Data_Neural', 'debug_plots');
            output_path = fullfile(output_base, ExperimentName, SessionName, 'Activity', this_probe_area, 'Channels_Correlation');
            
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
                
                fprintf('      Computing correlations for Trial %d...\n', trial_num);
                
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
                    [nChannels, ~] = size(data_matrix);
                    
                    % Get channel labels if available
                    if isfield(ft_struct, 'label')
                        channel_labels = ft_struct.label;
                    else
                        channel_labels = arrayfun(@(x) sprintf('Ch%d', x), 1:nChannels, 'UniformOutput', false);
                    end
                    
                    % Sort channels by numeric order
                    channel_nums = zeros(1, nChannels);
                    for ch_idx = 1:nChannels
                        if iscell(channel_labels)
                            label_str = channel_labels{ch_idx};
                        else
                            label_str = sprintf('%d', ch_idx);
                        end
                        num_tokens = regexp(label_str, '(\d+)', 'tokens');
                        if ~isempty(num_tokens)
                            channel_nums(ch_idx) = str2double(num_tokens{end}{1});
                        else
                            channel_nums(ch_idx) = ch_idx;
                        end
                    end
                    [~, sort_order] = sort(channel_nums);
                    
                    % Reorder data by channel number (sorted)
                    data_matrix_sorted = data_matrix(sort_order, :);
                    
                    % Compute correlation matrices
                    % corr() computes correlation between columns, so transpose
                    corr_matrix_sorted = corr(data_matrix_sorted');   % Sorted by label
                    corr_matrix_original = corr(data_matrix');        % Original matrix order
                    
                    % Create figure with 2 subplots
                    if Show_Figures
                        fig = figure('Position', [100, 100, Figure_Width, Figure_Height]);
                    else
                        fig = figure('Position', [100, 100, Figure_Width, Figure_Height], 'Visible', 'off');
                    end
                    
                    % Overall title
                    sgtitle(sprintf('%s - %s - %s - Trial %d', ...
                        SessionName, this_probe_area, this_signal_type, trial_num), ...
                        'FontSize', 12, 'Interpreter', 'none');
                    
                    % --- Left subplot: Sorted by channel label ---
                    subplot(1, 2, 1);
                    imagesc(corr_matrix_sorted);
                    colormap(Colormap_Name);
                    cb1 = colorbar;
                    cb1.Label.String = 'Correlation';
                    caxis([-1, 1]);
                    
                    title('Sorted by Channel Label', 'FontSize', 11);
                    xlabel('Channel (sorted)', 'FontSize', 10);
                    ylabel('Channel (sorted)', 'FontSize', 10);
                    
                    axis square;
                    set(gca, 'FontSize', 8);
                    
                    if nChannels > 32
                        tick_interval = ceil(nChannels / 16);
                        tick_positions = 1:tick_interval:nChannels;
                        set(gca, 'XTick', tick_positions, 'YTick', tick_positions);
                    end
                    
                    % --- Right subplot: Original matrix order ---
                    subplot(1, 2, 2);
                    imagesc(corr_matrix_original);
                    colormap(Colormap_Name);
                    cb2 = colorbar;
                    cb2.Label.String = 'Correlation';
                    caxis([-1, 1]);
                    
                    title('Original Matrix Order', 'FontSize', 11);
                    xlabel('Channel (index)', 'FontSize', 10);
                    ylabel('Channel (index)', 'FontSize', 10);
                    
                    axis square;
                    set(gca, 'FontSize', 8);
                    
                    if nChannels > 32
                        tick_interval = ceil(nChannels / 16);
                        tick_positions = 1:tick_interval:nChannels;
                        set(gca, 'XTick', tick_positions, 'YTick', tick_positions);
                    end
                    
                    % Save figure as PNG
                    output_file_name = sprintf('%s_Correlation_Trial_%d.png', this_signal_type, trial_num);
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

fprintf('\n=== Channel correlation plotting complete ===\n');

end

