%% DEBUG_kaaRunAllPlots
% Entry point script for running all debug visualization plots.
% Calls individual plotting functions for trial channels and channel correlations.
%
% Author: KAA

clc; clear; close all;

%% =========================================================================
% CONFIGURABLE PARAMETERS - Modify these as needed
% =========================================================================

% Which signal types to plot (options: 'WideBand', 'Raw', 'Notch', 'LFP', 'MUA')
Signal_Types = {'WideBand', 'Raw', 'Notch'};

% Which trials to plot (can be a range like 1:10, or specific numbers like [1, 5, 10])
Trial_Range = 1:5;

% Which plots to generate
Run_TrialChannels = true;       % Plot individual channel time series
Run_ChannelCorrelations = true; % Plot channel-channel correlation heatmaps

% Figure settings for trial channel plots
TrialChannels_Figure_Width = 1920;   % pixels
TrialChannels_Figure_Height = 1080;  % pixels
TrialChannels_Line_Width = 0.5;
TrialChannels_Font_Size = 6;

% Figure settings for correlation plots
Correlation_Figure_Width = 1080;   % pixels (square)
Correlation_Figure_Height = 1080;  % pixels
Correlation_Colormap = 'jet';      % Options: 'jet', 'hot', 'parula', 'turbo', etc.

% Set to true to show figures while processing (slower), false to hide
Show_Figures = false;

% =========================================================================
% END OF CONFIGURABLE PARAMETERS
% =========================================================================

%% Load session configuration
fprintf('Loading session configuration...\n');
[cfg] = DATA_cggAllSessionInformationConfiguration;

%% Run Trial Channels Plot
if Run_TrialChannels
    fprintf('\n========================================\n');
    fprintf('Running Trial Channel Plots\n');
    fprintf('========================================\n');
    
    kaa_plotTrialChannels(cfg, Signal_Types, Trial_Range, ...
        'Figure_Width', TrialChannels_Figure_Width, ...
        'Figure_Height', TrialChannels_Figure_Height, ...
        'Line_Width', TrialChannels_Line_Width, ...
        'Font_Size', TrialChannels_Font_Size, ...
        'Show_Figures', Show_Figures);
end

%% Run Channel Correlations Plot
if Run_ChannelCorrelations
    fprintf('\n========================================\n');
    fprintf('Running Channel Correlation Plots\n');
    fprintf('========================================\n');
    
    kaa_plotChannelCorrelations(cfg, Signal_Types, Trial_Range, ...
        'Figure_Width', Correlation_Figure_Width, ...
        'Figure_Height', Correlation_Figure_Height, ...
        'Colormap', Correlation_Colormap, ...
        'Show_Figures', Show_Figures);
end

%% Done
fprintf('\n========================================\n');
fprintf('All debug plots complete!\n');
fprintf('========================================\n');

