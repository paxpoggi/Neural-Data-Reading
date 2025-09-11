function cfg = PARAMETERS_cgg_proc_NeuralDataPreparation(varargin)


% This script includes the Parameters for cgg_proc_NeuralDataPreparation.
% The parameters are explained and default values are included.

%% Trial Cutting Information

% This string determines what the 0 point will be when aligning the trials.
% It willl only affect the time vectors for each trial. It will not affect
% how long a trial is or what the cut events are.
trial_align_evcode = 'FixCentralCueStart';

% This is how much padding we want before 'TrlStart' and after 'TrlEnd'.
% The default is 1 second because information will be included in the
% following and preceding trials and overlap isn't necessary
padtime = 1; % Time in seconds

%% Data Processing Information

% Narrow-band frequencies to filter out.

% We have power line peaks at 60 Hz and its harmonics, and also often
% have a peak at around 600 Hz and its harmonics.

notch_filter_freqs = [ 60, 120, 180 ];
notch_filter_bandwidth = 2.0;

% Frequency cutoffs for getting the LFP, spike, and rectified signals.

% The LFP signal is low-pass filtered and downsampled. Typical features are
% in the range of 2 Hz to 200 Hz.

lfp_maxfreq = 300;
lfp_samprate = 1000;

% The spike signal is high-pass filtered. Typical features have a time scale
% of 1 ms or less, but there's often a broad tail lasting several ms.

spike_minfreq = 100;

% The rectified signal is a measure of spiking activity. The signal is
% band-pass filtered, then rectified (absolute value), then low-pass filtered
% at a frequency well below the lower corner, then downsampled.

rect_bandfreqs = [ 300 5000 ];
rect_lowpassfreq = 500;
rect_samprate = lfp_samprate;


% Nominal frequency for reading gaze data.

% As long as this is higher than the device's sampling rate (300-600 Hz),
% it doesn't really matter what it is.
% The gaze data itself is non-uniformly sampled.

gaze_samprate = lfp_samprate;

% This boolean determines whether rereferencing is wanted. This will
% calculate a reference from selected channels and subtract that from the
% signal in each channel. This should remove noise that is common across
% all channels

want_rereference = true; % true, false

% This string determines the type of rereferencing that is done.
% Typicalling this will be set to 'avg' for common average referencing or
% 'median' for median referencing. Median rereferecning will be less
% sensitive to large excursions such as spikes.

rereference_type='median'; %'avg', 'median', 'rest', 'bipolar' or 
% 'laplace' (default = 'avg') [Directly from FieldTrip Documentation]

% This scalar determines the number of trials that are used when
% automatically getting the channels that are disconnected. A higher number
% will increase the time to calculate but will include more data in the
% calculation of which channels are disconnected. The value must be less
% than the number of trials in the session.

clustering_trial_count=30;


%% Probe Information

% Probe Mapping. This will determine what the reference mapping is for the
% following sections. The options are unmapped, mapped, and recorded.
% unmapped is the probe channels with no mapping applied. Mapped is the
% probe channels with the channel mapping selected in the folder applied.
% This mapping can be added later and marked with "_correct" to be used as
% this mapping. Lastly, recorded can be chosen which uses the mapping that
% was used when the recording took place. As long as channel mapping is
% active it will remap this channel to the mapped position. Probe mapping
% will not have an effect if all the contacts for a probe are selected
% since they will all be remapped together.

probe_mapping='mapped'; %unmapped, mapped, recorded

SessionName = CheckVararginPairs('SessionName', 'None', varargin{:});

[probe_area,probe_selection] = ...
    PARAMETERS_cgg_getSessionProbeInformation(SessionName);

% probe_disconnected={[30,60:64],[30,39,60:64],[30,60:64],[14,30,60:64],[30,60:64]};


%% Boolean Decision Section


% This boolean determines whether the channels will be remapped. If the
% channels are already recorded in the proper order than this should be set
% to false. If the channel mapping is correct for the recording and the
% value is set to true it will still remain correct. The channel mapping
% that is used is the one with "*correct*" or the first channel mapping
% listed.
want_channel_remap = true;

% This boolean determines whether the artifact rejection UI will appear.
% This uses the FieldTrip function "ft_rejectvisual". For this function it
% will likely not be necessary so it should be set to false.

want_artifact_rejection = false;

% This boolean determines which of the different derivative activities are
% wanted. If the value is true then the function will process the data to
% obtain the given activity if it does not already exist.

want_LFP = true;
want_MUA = true;
want_Spike = false;

% This boolean determines whether to keep the wideband data saved after
% processing the different derivative activities. Keeping this to false
% will GREATLY reduce the amount of data that has to be saved to hard
% drive.

keep_wideband=false;

% For visualizing processing steps this boolean determines whether to save
% the raw wideband and notch filtered. Regular wideband is rereferenced as
% well

keep_raw = false;
keep_notch = false;

%%

w = whos;
for a = 1:length(w) 
cfg.(w(a).name) = eval(w(a).name); 
end


end

%
% This is the end of the file.