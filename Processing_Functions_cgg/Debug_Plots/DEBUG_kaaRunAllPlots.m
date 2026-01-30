%% DEBUG_kaaRunAllPlots
% Entry point script for running all debug visualization plots.
% Calls individual plotting functions for trial channels and channel correlations.
%
% Author: KAA

clc; clear; close all;

%% =========================================================================
% CONFIGURABLE PARAMETERS - Modify these as needed
% =========================================================================

% Data source: 'Activity' (preprocessing output) or 'Epoched' (processing output)
Data_Source = 'Activity';

% For 'Activity': Signal types (options: 'WideBand', 'Raw', 'Notch', 'LFP', 'MUA')
% For 'Epoched': Signal types (options: 'MUA', 'LFP')
Signal_Types = {'WideBand', 'Raw', 'Notch'};

% For 'Epoched' data source only - which epoch to plot
Epoch_Name = 'Decision';

% Which trials to plot (can be a range like 1:10, or specific numbers like [1, 5, 10])
Trial_Range = 1:5;

% Which plots to generate
Run_TrialChannels = true;       % Plot individual channel time series (Activity) or probe heatmaps (Epoched)
Run_ChannelCorrelations = true; % Plot channel-channel correlation heatmaps

% Figure settings for trial channel plots
TrialChannels_Figure_Width = 1920;   % pixels
TrialChannels_Figure_Height = 1080;  % pixels
TrialChannels_Line_Width = 0.5;
TrialChannels_Font_Size = 6;

% Figure settings for correlation plots (side-by-side subplots)
Correlation_Figure_Width = 2000;   % pixels (wide for 2 subplots)
Correlation_Figure_Height = 900;   % pixels
Correlation_Colormap = 'jet';      % Options: 'jet', 'hot', 'parula', 'turbo', etc.

% Figure settings for epoched data plots (3x2 probe grid)
Epoched_Figure_Width = 1800;    % pixels
Epoched_Figure_Height = 1200;   % pixels
Epoched_Colormap = 'parula';    % Options: 'jet', 'hot', 'parula', 'turbo', etc.

% Set to true to show figures while processing (slower), false to hide
Show_Figures = false;

% =========================================================================
% END OF CONFIGURABLE PARAMETERS
% =========================================================================

%% Load session configuration
fprintf('Loading session configuration...\n');
[cfg] = DATA_cggAllSessionInformationConfiguration;

%% Run plots based on Data_Source
switch Data_Source
    case 'Activity'
        %% Activity data (preprocessing output) - per-probe trial files
        
        % Run Trial Channels Plot
        if Run_TrialChannels
            fprintf('\n========================================\n');
            fprintf('Running Trial Channel Plots (Activity)\n');
            fprintf('========================================\n');
            
            kaa_plotTrialChannels(cfg, Signal_Types, Trial_Range, ...
                'Figure_Width', TrialChannels_Figure_Width, ...
                'Figure_Height', TrialChannels_Figure_Height, ...
                'Line_Width', TrialChannels_Line_Width, ...
                'Font_Size', TrialChannels_Font_Size, ...
                'Show_Figures', Show_Figures);
        end
        
        % Run Channel Correlations Plot
        if Run_ChannelCorrelations
            fprintf('\n========================================\n');
            fprintf('Running Channel Correlation Plots (Activity)\n');
            fprintf('========================================\n');
            
            kaa_plotChannelCorrelations(cfg, Signal_Types, Trial_Range, ...
                'Figure_Width', Correlation_Figure_Width, ...
                'Figure_Height', Correlation_Figure_Height, ...
                'Colormap', Correlation_Colormap, ...
                'Show_Figures', Show_Figures);
        end
        
    case 'Epoched'
        %% Epoched data (processing output) - 3D matrix with all probes
        
        if Run_TrialChannels
            fprintf('\n========================================\n');
            fprintf('Running Epoched Trial Plots (%s)\n', Epoch_Name);
            fprintf('========================================\n');
            
            kaa_plotEpochedTrials(cfg, Signal_Types, Trial_Range, Epoch_Name, ...
                'Figure_Width', Epoched_Figure_Width, ...
                'Figure_Height', Epoched_Figure_Height, ...
                'Colormap', Epoched_Colormap, ...
                'Show_Figures', Show_Figures);
        end
        
        % Channel correlations for epoched data (if needed in future)
        if Run_ChannelCorrelations
            fprintf('\n[INFO] Channel correlations for Epoched data not yet implemented.\n');
            fprintf('       Use Data_Source = ''Activity'' for correlation plots.\n');
        end
        
    otherwise
        error('Unknown Data_Source: %s. Use ''Activity'' or ''Epoched''.', Data_Source);
end

%% Done
fprintf('\n========================================\n');
fprintf('All debug plots complete!\n');
fprintf('========================================\n');

