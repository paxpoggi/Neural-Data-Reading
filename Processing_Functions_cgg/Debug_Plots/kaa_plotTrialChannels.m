function kaa_plotTrialChannels(cfg, Signal_Types, Trial_Range, varargin)
%KAA_PLOTTRIALACHANNELS Plot all channels for each trial across signal types
%
%   kaa_plotTrialChannels(cfg, Signal_Types, Trial_Range)
%   kaa_plotTrialChannels(cfg, Signal_Types, Trial_Range, 'Name', Value, ...)
%
%   Generates subplot figures showing each channel's time series and saves as PNG.
%
%   Output folder structure mirrors input but under 'debug_plots' instead of 'Data_Neural':
%     Input:  processed_data/Data_Neural/Experiment/Session/Activity/ProbeArea/SignalType/
%     Output: processed_data/debug_plots/Experiment/Session/Activity/ProbeArea/SignalType/
%
%   Inputs:
%     cfg          - Session configuration from DATA_cggAllSessionInformationConfiguration
%     Signal_Types - Cell array of signal types (e.g., {'WideBand', 'Raw', 'Notch'})
%     Trial_Range  - Array of trial numbers to process (e.g., 1:5)
%
%   Optional Name-Value pairs:
%     'Figure_Width'  - Figure width in pixels (default: 1920)
%     'Figure_Height' - Figure height in pixels (default: 1080)
%     'Line_Width'    - Line width for plots (default: 0.5)
%     'Font_Size'     - Font size for labels (default: 6)
%     'Show_Figures'  - Show figures while processing (default: false)
%
%   Author: KAA

% Parse optional parameters
Figure_Width = CheckVararginPairs('Figure_Width', 1920, varargin{:});
Figure_Height = CheckVararginPairs('Figure_Height', 1080, varargin{:});
Line_Width = CheckVararginPairs('Line_Width', 0.5, varargin{:});
Font_Size = CheckVararginPairs('Font_Size', 6, varargin{:});
Show_Figures = CheckVararginPairs('Show_Figures', false, varargin{:});

%% Process each session
for sidx = 1:length(cfg)
    
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
                        fprintf('        [INFO] Time vector not found, using sample indices (1:%d)\n', nSamples);
                        time_vec = 1:nSamples;
                    end
                    
                    % Use original matrix order (no sorting by labels)
                    % Channel 1 = index 1 in matrix, Channel 2 = index 2, etc.
                    % Label remapping has already been applied upstream
                    
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
                    
                    % Plot each channel in original matrix order
                    for ch_idx = 1:nChannels
                        subplot(nRows, nCols, ch_idx);
                        
                        plot(time_vec, data_matrix(ch_idx, :), 'LineWidth', Line_Width);
                        
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
            
        end % signal type loop
        
    end % probe area loop
    
end % session loop

fprintf('\n=== Trial channel plotting complete ===\n');

end

