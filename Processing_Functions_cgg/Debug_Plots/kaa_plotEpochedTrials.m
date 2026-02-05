function kaa_plotEpochedTrials(cfg, Signal_Types, Trial_Range, Epoch_Name, varargin)
%KAA_PLOTEPOCHEDTRIALS Plot epoched trial data with all probes in a 3x2 grid
%
%   kaa_plotEpochedTrials(cfg, Signal_Types, Trial_Range, Epoch_Name)
%   kaa_plotEpochedTrials(cfg, Signal_Types, Trial_Range, Epoch_Name, 'Name', Value, ...)
%
%   Generates figures showing heatmaps for each probe (3x2 grid) and saves as PNG.
%
%   Input folder structure:
%     processed_data/Data_Neural/Experiment/Session/Epoched_Data/{Epoch}/{Signal}/Data/
%
%   Output folder structure:
%     processed_data/debug_plots/Experiment/Session/Epoched_Data/{Epoch}/{Signal}/Data/
%
%   Inputs:
%     cfg          - Session configuration from DATA_cggAllSessionInformationConfiguration
%     Signal_Types - Cell array of signal types (e.g., {'MUA', 'LFP'})
%     Trial_Range  - Array of trial numbers to process (e.g., 1:5)
%     Epoch_Name   - Name of epoch (e.g., 'Decision')
%
%   Optional Name-Value pairs:
%     'Figure_Width'  - Figure width in pixels (default: 1800)
%     'Figure_Height' - Figure height in pixels (default: 1200)
%     'Colormap'      - Colormap name (default: 'parula')
%     'Show_Figures'  - Show figures while processing (default: false)
%
%   Author: KAA

% Parse optional parameters
Figure_Width = CheckVararginPairs('Figure_Width', 1800, varargin{:});
Figure_Height = CheckVararginPairs('Figure_Height', 1200, varargin{:});
Colormap_Name = CheckVararginPairs('Colormap', 'parula', varargin{:});
Show_Figures = CheckVararginPairs('Show_Figures', false, varargin{:});

%% Process each session
for sidx = 1:length(cfg)
    
    outdatadir = cfg(sidx).outdatadir;
    ExperimentName = cfg(sidx).ExperimentName;
    SessionName = cfg(sidx).SessionName;
    
    fprintf('\n=== Processing Session: %s ===\n', SessionName);
    
    % Base path for epoched data
    epoched_base_path = fullfile(outdatadir, ExperimentName, SessionName, 'Epoched_Data', Epoch_Name);
    
    % Check if epoch path exists
    if ~exist(epoched_base_path, 'dir')
        warning('Epoched data path does not exist: %s. Skipping.', epoched_base_path);
        continue;
    end
    
    %% Loop through signal types (MUA, LFP)
    for stidx = 1:length(Signal_Types)
        this_signal_type = Signal_Types{stidx};
        signal_data_path = fullfile(epoched_base_path, this_signal_type, 'Data');
        processing_path = fullfile(epoched_base_path, this_signal_type, 'Processing');
        
        % Check if signal type folder exists
        if ~exist(signal_data_path, 'dir')
            fprintf('  Signal type folder not found: %s. Skipping.\n', signal_data_path);
            continue;
        end
        
        fprintf('  Processing Signal Type: %s\n', this_signal_type);
        
        % Load disconnected channel info for each probe area
        % We'll store method-specific channel lists per probe area
        ProbeArea_MethodInfo = struct();
        
        % Try to read Probe_Order from Parameters_Processing.yaml
        yaml_file = fullfile(processing_path, 'Parameters_Processing.yaml');
        Probe_Order = {'ACC_001', 'ACC_002', 'PFC_001', 'PFC_002', 'CD_001', 'CD_002'}; % Default
        
        if exist(yaml_file, 'file')
            try
                params = ReadYaml(yaml_file, 0, true);
                if isfield(params, 'Probe_Order')
                    if iscell(params.Probe_Order)
                        Probe_Order = params.Probe_Order;
                    end
                    fprintf('    [INFO] Loaded Probe_Order from YAML: %s\n', strjoin(Probe_Order, ', '));
                else
                    fprintf('    [INFO] Probe_Order not in YAML, using default: %s\n', strjoin(Probe_Order, ', '));
                end
            catch ME
                fprintf('    [INFO] Could not read YAML (%s), using default Probe_Order\n', ME.message);
            end
        else
            fprintf('    [INFO] Parameters_Processing.yaml not found, using default Probe_Order\n');
        end
        
        nProbes = length(Probe_Order);
        
        % Load Debugging_Info for each probe area
        % Probe areas are in the Activity folder structure
        activity_base_path = fullfile(outdatadir, ExperimentName, SessionName, 'Activity');
        for pidx = 1:length(Probe_Order)
            probe_area_name = Probe_Order{pidx};
            clustering_file_path = fullfile(activity_base_path, probe_area_name, 'Connected', 'Clustering_Results.mat');
            
            ProbeArea_MethodInfo.(probe_area_name).Method_i_Channels = [];
            ProbeArea_MethodInfo.(probe_area_name).Method_ii_Channels = [];
            ProbeArea_MethodInfo.(probe_area_name).Method_iii_Channels = [];
            ProbeArea_MethodInfo.(probe_area_name).Disconnected_Channels = [];
            
            if exist(clustering_file_path, 'file')
                try
                    clustering_data = load(clustering_file_path);
                    if isfield(clustering_data, 'Disconnected_Channels')
                        ProbeArea_MethodInfo.(probe_area_name).Disconnected_Channels = clustering_data.Disconnected_Channels(:);
                    end
                    
                    if isfield(clustering_data, 'Debugging_Info')
                        Debugging_Info = clustering_data.Debugging_Info;
                        
                        if isfield(Debugging_Info, 'Method_i_WidebandThreshold') && ...
                                isfield(Debugging_Info.Method_i_WidebandThreshold, 'Channels')
                            ProbeArea_MethodInfo.(probe_area_name).Method_i_Channels = ...
                                Debugging_Info.Method_i_WidebandThreshold.Channels(:);
                        end
                        
                        if isfield(Debugging_Info, 'Method_iii_ZScore') && ...
                                isfield(Debugging_Info.Method_iii_ZScore, 'Channels')
                            ProbeArea_MethodInfo.(probe_area_name).Method_iii_Channels = ...
                                Debugging_Info.Method_iii_ZScore.Channels(:);
                        end
                        
                        % Method ii channels = Disconnected_Channels minus Method_iii
                        if ~isempty(ProbeArea_MethodInfo.(probe_area_name).Method_iii_Channels)
                            ProbeArea_MethodInfo.(probe_area_name).Method_ii_Channels = ...
                                setdiff(ProbeArea_MethodInfo.(probe_area_name).Disconnected_Channels, ...
                                ProbeArea_MethodInfo.(probe_area_name).Method_iii_Channels);
                        else
                            ProbeArea_MethodInfo.(probe_area_name).Method_ii_Channels = ...
                                ProbeArea_MethodInfo.(probe_area_name).Disconnected_Channels;
                        end
                    end
                catch ME
                    fprintf('    [WARN] Failed to load clustering data for %s: %s\n', probe_area_name, ME.message);
                end
            end
        end
        
        % Create output folder (replace Data_Neural with debug_plots)
        output_base = strrep(outdatadir, 'Data_Neural', 'debug_plots');
        output_path = fullfile(output_base, ExperimentName, SessionName, 'Epoched_Data', Epoch_Name, this_signal_type, 'Data');
        
        if ~exist(output_path, 'dir')
            mkdir(output_path);
        end
        
        % Find all trial files
        % File naming: {Epoch}_Data_{trial_number:06d}.mat
        trial_files = dir(fullfile(signal_data_path, [Epoch_Name '_Data_*.mat']));
        
        if isempty(trial_files)
            fprintf('    No trial files found. Skipping.\n');
            continue;
        end
        
        % Extract trial numbers from filenames
        trial_numbers = zeros(1, length(trial_files));
        for tidx = 1:length(trial_files)
            tokens = regexp(trial_files(tidx).name, '_Data_(\d+)\.mat', 'tokens');
            if ~isempty(tokens)
                trial_numbers(tidx) = str2double(tokens{1}{1});
            end
        end
        
        % Filter to only requested trials
        trials_to_process = intersect(trial_numbers, Trial_Range);
        trials_to_process = sort(trials_to_process);
        
        if isempty(trials_to_process)
            fprintf('    No matching trials in Trial_Range. Skipping.\n');
            continue;
        end
        
        fprintf('    Found %d trials to process.\n', length(trials_to_process));
        
        %% Process each trial
        for trial_idx = 1:length(trials_to_process)
            trial_num = trials_to_process(trial_idx);
            trial_file_name = sprintf('%s_Data_%06d.mat', Epoch_Name, trial_num);
            trial_file_path = fullfile(signal_data_path, trial_file_name);
            
            if ~exist(trial_file_path, 'file')
                warning('Trial file not found: %s', trial_file_path);
                continue;
            end
            
            fprintf('    Processing Trial %d...\n', trial_num);
            
            try
                % Load the trial file - contains 'Data' variable [nChannels x nSamples x nProbes]
                trial_data = load(trial_file_path);
                
                if ~isfield(trial_data, 'Data')
                    warning('No ''Data'' variable found in: %s', trial_file_path);
                    continue;
                end
                
                data_3d = trial_data.Data;
                [nChannels, nSamples, nProbesInFile] = size(data_3d);
                
                fprintf('      Data shape: [%d channels x %d samples x %d probes]\n', nChannels, nSamples, nProbesInFile);
                
                % Create figure with 3x2 subplot grid
                if Show_Figures
                    fig = figure('Position', [100, 100, Figure_Width, Figure_Height]);
                else
                    fig = figure('Position', [100, 100, Figure_Width, Figure_Height], 'Visible', 'off');
                end
                
                % Set figure title
                sgtitle(sprintf('%s - %s - %s - Trial %d', ...
                    SessionName, Epoch_Name, this_signal_type, trial_num), ...
                    'FontSize', 12, 'Interpreter', 'none');
                
                % Plot each probe in 3x2 grid
                nRows = 3;
                nCols = 2;
                
                for pidx = 1:min(nProbesInFile, nProbes)
                    subplot(nRows, nCols, pidx);
                    
                    % Get data for this probe [nChannels x nSamples]
                    probe_data = data_3d(:, :, pidx);
                    
                    % Check for all-NaN probe (not processed)
                    if all(isnan(probe_data(:)))
                        % Show empty plot with message
                        text(0.5, 0.5, 'No data (all NaN)', ...
                            'HorizontalAlignment', 'center', ...
                            'FontSize', 10);
                        axis off;
                        if pidx <= length(Probe_Order)
                            title(sprintf('%s (no data)', Probe_Order{pidx}), 'FontSize', 10);
                        else
                            title(sprintf('Probe %d (no data)', pidx), 'FontSize', 10);
                        end
                        continue;
                    end
                    
                    % Get probe area name and method info
                    probe_area_name = '';
                    Method_i_Channels = [];
                    Method_ii_Channels = [];
                    Method_iii_Channels = [];
                    Disconnected_Channels = [];
                    
                    if pidx <= length(Probe_Order)
                        probe_area_name = Probe_Order{pidx};
                        if isfield(ProbeArea_MethodInfo, probe_area_name)
                            Method_i_Channels = ProbeArea_MethodInfo.(probe_area_name).Method_i_Channels;
                            Method_ii_Channels = ProbeArea_MethodInfo.(probe_area_name).Method_ii_Channels;
                            Method_iii_Channels = ProbeArea_MethodInfo.(probe_area_name).Method_iii_Channels;
                            Disconnected_Channels = ProbeArea_MethodInfo.(probe_area_name).Disconnected_Channels;
                        end
                    end
                    
                    % Plot heatmap
                    imagesc(probe_data);
                    colormap(gca, Colormap_Name);
                    colorbar;
                    
                    % Labels
                    xlabel('Time (samples)', 'FontSize', 8);
                    ylabel('Channel', 'FontSize', 8);
                    
                    % Build title with probe name and method indicators for disconnected channels
                    if pidx <= length(Probe_Order)
                        title_str = Probe_Order{pidx};
                        
                        % Add method indicators if there are disconnected channels
                        if ~isempty(Disconnected_Channels) && ~isempty(Disconnected_Channels(Disconnected_Channels <= nChannels))
                            % Count how many disconnected channels are in this probe's range
                            disconnected_in_range = sum(Disconnected_Channels <= nChannels);
                            if disconnected_in_range > 0
                                % Build compact summary: show first few with method tags
                                method_summary_parts = {};
                                shown_count = 0;
                                max_show = 3; % Show up to 3 channels in title
                                
                                for ch_idx = 1:min(nChannels, max(Disconnected_Channels))
                                    if ismember(ch_idx, Disconnected_Channels)
                                        method_tags = {};
                                        if ismember(ch_idx, Method_i_Channels)
                                            method_tags{end+1} = 'i';
                                        end
                                        if ismember(ch_idx, Method_ii_Channels)
                                            method_tags{end+1} = 'ii';
                                        end
                                        if ismember(ch_idx, Method_iii_Channels)
                                            method_tags{end+1} = 'iii';
                                        end
                                        
                                        if ~isempty(method_tags)
                                            method_summary_parts{end+1} = sprintf('%d[%s]', ch_idx, strjoin(method_tags, ','));
                                            shown_count = shown_count + 1;
                                            if shown_count >= max_show
                                                break;
                                            end
                                        end
                                    end
                                end
                                
                                if ~isempty(method_summary_parts)
                                    if disconnected_in_range > max_show
                                        title_str = sprintf('%s (%s +%d)', title_str, strjoin(method_summary_parts, ','), disconnected_in_range - max_show);
                                    else
                                        title_str = sprintf('%s (%s)', title_str, strjoin(method_summary_parts, ','));
                                    end
                                end
                            end
                        end
                        
                        title(title_str, 'FontSize', 10);
                    else
                        title(sprintf('Probe %d', pidx), 'FontSize', 10);
                    end
                    
                    % Modify y-axis tick labels to show method indicators for disconnected channels
                    if ~isempty(Disconnected_Channels)
                        ytick_labels = get(gca, 'YTickLabel');
                        if ischar(ytick_labels)
                            ytick_labels = cellstr(ytick_labels);
                        end
                        ytick_positions = get(gca, 'YTick');
                        
                        % Update labels for disconnected channels
                        for ch_idx = 1:nChannels
                            if ismember(ch_idx, Disconnected_Channels)
                                % Find which tick corresponds to this channel
                                % Y-axis is inverted for imagesc, so we need to account for that
                                % Channel 1 is at the top (y = nChannels), channel nChannels is at bottom (y = 1)
                                y_pos = nChannels - ch_idx + 1;
                                
                                % Find closest tick position
                                [~, tick_idx] = min(abs(ytick_positions - y_pos));
                                
                                if tick_idx <= length(ytick_labels)
                                    % Build method tags
                                    method_tags = {};
                                    if ismember(ch_idx, Method_i_Channels)
                                        method_tags{end+1} = 'i';
                                    end
                                    if ismember(ch_idx, Method_ii_Channels)
                                        method_tags{end+1} = 'ii';
                                    end
                                    if ismember(ch_idx, Method_iii_Channels)
                                        method_tags{end+1} = 'iii';
                                    end
                                    
                                    if ~isempty(method_tags)
                                        ytick_labels{tick_idx} = sprintf('%s [%s]', ytick_labels{tick_idx}, strjoin(method_tags, ','));
                                    end
                                end
                            end
                        end
                        
                        set(gca, 'YTickLabel', ytick_labels);
                    end
                    
                    % Adjust axis
                    axis tight;
                    set(gca, 'FontSize', 8);
                end
                
                % Save figure as PNG
                output_file_name = sprintf('%s_Data_%06d.png', Epoch_Name, trial_num);
                output_file_path = fullfile(output_path, output_file_name);
                
                % Use print for better quality
                print(fig, output_file_path, '-dpng', '-r150');
                
                % Close figure to free memory
                close(fig);
                
                fprintf('      Saved: %s\n', output_file_name);
                
            catch ME
                warning('Error processing trial %d: %s', trial_num, ME.message);
                if exist('fig', 'var') && ishandle(fig)
                    close(fig);
                end
            end
            
        end % trial loop
        
    end % signal type loop
    
end % session loop

fprintf('\n=== Epoched trial plotting complete ===\n');

end

