function data = kaa_generateSyntheticFieldTripData(varargin)
%KAA_GENERATESYNTHETICFIELDTRIPDATA Generate synthetic FieldTrip data for testing
%
%   data = kaa_generateSyntheticFieldTripData()
%   data = kaa_generateSyntheticFieldTripData('fsample', 30000, 'duration', 1)
%
%   Generates a synthetic FieldTrip ft_datatype_raw structure with 9 channels:
%   - CH001-CH005: Good channels with various frequencies (10Hz, 20Hz, 100Hz, 1000Hz, 2000Hz)
%   - CH006: DC offset (constant value) - artifact
%   - CH007: 60Hz power line noise - artifact
%   - CH008: 120Hz power line harmonic - artifact
%   - CH009: High amplitude 50Hz signal (100x normal) - artifact
%
%   Optional Parameters:
%       fsample    - Sampling rate in Hz (default: 30000)
%       duration   - Trial duration in seconds (default: 1)
%
%   Output:
%       data       - FieldTrip ft_datatype_raw structure
%
%   Author: kaa

% Parse input parameters
fsample = CheckVararginPairs('fsample', 30000, varargin{:});
duration = CheckVararginPairs('duration', 1, varargin{:});

% Create time vector
nSamples = round(fsample * duration);
t = (0:(nSamples-1)) / fsample;

% Initialize data structure
data = struct();
data.trial = cell(1, 1);
data.time = cell(1, 1);
data.label = cell(9, 1);
data.fsample = fsample;
data.cfg = struct();
data.cfg.generated_by = 'kaa_generateSyntheticFieldTripData';
data.cfg.fsample = fsample;
data.cfg.duration = duration;

% Create header structure
data.hdr = struct();
data.hdr.Fs = fsample;
data.hdr.nChans = 9;
data.hdr.nSamples = nSamples;
data.hdr.nTrials = 1;
data.hdr.label = cell(9, 1);
data.hdr.chantype = cell(9, 1);

% Initialize trial data matrix [nChannels x nSamples]
trial_data = zeros(9, nSamples);

% Generate channel signals
% CH001: sin(2π·10Hz·t) - Low frequency, should appear in LFP
data.label{1} = 'CH001';
data.hdr.label{1} = 'CH001';
data.hdr.chantype{1} = 'eeg';
trial_data(1, :) = sin(2*pi*10*t);

% CH002: cos(2π·20Hz·t) - Low frequency, should appear in LFP
data.label{2} = 'CH002';
data.hdr.label{2} = 'CH002';
data.hdr.chantype{2} = 'eeg';
trial_data(2, :) = cos(2*pi*20*t);

% CH003: sin(2π·100Hz·t) - Medium frequency, should appear in LFP
data.label{3} = 'CH003';
data.hdr.label{3} = 'CH003';
data.hdr.chantype{3} = 'eeg';
trial_data(3, :) = sin(2*pi*100*t);

% CH004: sin(2π·1000Hz·t) - High frequency, should appear in MUA
data.label{4} = 'CH004';
data.hdr.label{4} = 'CH004';
data.hdr.chantype{4} = 'eeg';
trial_data(4, :) = sin(2*pi*1000*t);

% CH005: sin(2π·2000Hz·t) - High frequency, should appear in MUA
data.label{5} = 'CH005';
data.hdr.label{5} = 'CH005';
data.hdr.chantype{5} = 'eeg';
trial_data(5, :) = sin(2*pi*2000*t);

% CH006: DC offset (constant value) - Should be detected as artifact/disconnected
data.label{6} = 'CH006';
data.hdr.label{6} = 'CH006';
data.hdr.chantype{6} = 'eeg';
trial_data(6, :) = ones(1, nSamples) * 5.0;  % Constant DC offset

% CH007: sin(2π·60Hz·t) - Power line noise, should be removed by notch filter
data.label{7} = 'CH007';
data.hdr.label{7} = 'CH007';
data.hdr.chantype{7} = 'eeg';
trial_data(7, :) = sin(2*pi*60*t);

% CH008: sin(2π·120Hz·t) - Power line harmonic, should be removed by notch filter
data.label{8} = 'CH008';
data.hdr.label{8} = 'CH008';
data.hdr.chantype{8} = 'eeg';
trial_data(8, :) = sin(2*pi*120*t);

% CH009: 100·sin(2π·50Hz·t) - High amplitude signal (100x normal amplitude)
% Should be detected as artifact/disconnected
data.label{9} = 'CH009';
data.hdr.label{9} = 'CH009';
data.hdr.chantype{9} = 'eeg';
trial_data(9, :) = 100 * sin(2*pi*50*t);

% Store trial data and time
data.trial{1} = trial_data;
data.time{1} = t;

% Store metadata about channel types
data.cfg.channel_info = struct();
data.cfg.channel_info.good_channels = 1:5;
data.cfg.channel_info.artifact_channels = 6:9;
data.cfg.channel_info.dc_channel = 6;
data.cfg.channel_info.powerline_channels = [7, 8];
data.cfg.channel_info.high_amplitude_channel = 9;

end

