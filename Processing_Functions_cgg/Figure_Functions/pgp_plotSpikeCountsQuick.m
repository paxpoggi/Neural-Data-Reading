% pgp_plotSpikeCountsQuick.m
%
% Quick visualization of SpikeCounts.mat output from pgp_spikeTrialAlignment_v4.
% Set session_name and spike_counts_dir below, then run.
%
% Output variables in SpikeCounts.mat:
%   TrialId : [nTrials x 1]
%   X       : {nTrials x 1} cell; X{t} = [nUnits x nBins_data] int16  (1ms bins)
%   X_base  : {nTrials x 1} cell; X_base{t} = [nUnits x nBins_base] int16
%   Meta    : struct with t_ms, t_ms_base, params, UnitInfo

%% ---- Configure here ----
% session_name     = 'Fr_Probe_02_22-05-02_004_01';
session_name     = 'Fr_Probe_03_22-07-13_002_01';
spike_counts_dir = '/data/womelsdorf_lab/kazezew/Old_Dataset_Related/processed_data';

% Unit to inspect in single-unit plots (1-indexed)
unit_idx = 1;

%% ---- Load ----
pattern  = fullfile(spike_counts_dir, '**', [session_name '*SpikeCounts_Stable.mat']);
flist    = dir(pattern);
assert(~isempty(flist), 'No SpikeCounts.mat found for session: %s', session_name);

fpath = fullfile(flist(1).folder, flist(1).name);
fprintf('Loading: %s\n', fpath);
S = load(fpath, 'X', 'X_base', 'Meta', 'TrialId');

X    = S.X;
t    = double(S.Meta.t_ms);       % [1 x nBins_data] ms
nT   = length(X);
nU   = size(X{1}, 1);

fprintf('Loaded: %d trials, %d units, %d bins\n', nT, nU, length(t));

% Stack into [nUnits x nBins x nTrials] and cast to double for arithmetic
Xmat = double(cat(3, X{:}));     % [nUnits x nBins x nTrials]

%% ---- Plot 1: Population heatmap ----
meanFR = mean(Xmat, 3, 'omitnan') * 1000;   % sp/s; omitnan handles NaN trials

figure('Name', sprintf('%s — Population heatmap', session_name));
imagesc(t, 1:nU, meanFR);
colorbar; colormap(hot);
xlabel('Time from event (ms)'); ylabel('Unit #');
title(sprintf('%s  —  Population mean firing rate', session_name), 'Interpreter','none');
xline(0, 'w--', 'LineWidth', 1.5);

%% ---- Plot 2: Single unit PSTH ----
fr      = squeeze(Xmat(unit_idx,:,:))' * 1000;  % [nTrials x nBins] sp/s
mu      = mean(fr, 1, 'omitnan');
nValid  = sum(~isnan(fr(:,1)));                 % trials with valid data
sem     = std(fr, 0, 1, 'omitnan') / sqrt(nValid);

figure('Name', sprintf('%s — Unit %d PSTH', session_name, unit_idx));
patch([t fliplr(t)], [mu+sem fliplr(mu-sem)], [0.7 0.7 1], 'EdgeColor','none');
hold on;
plot(t, mu, 'b', 'LineWidth', 1.5);
xline(0, 'k--');
xlabel('Time (ms)'); ylabel('Firing rate (sp/s)');
title(sprintf('%s  —  Unit %d PSTH  (n=%d trials)', session_name, unit_idx, nT), ...
    'Interpreter','none');

%% ---- Plot 3: All-units raster grid ----
ncols = ceil(sqrt(nU));
nrows = ceil(nU / ncols);

figure('Name', sprintf('%s — All units raster', session_name), ...
    'Units','normalized', 'Position',[0 0 1 1]);

for uid = 1:nU
    subplot(nrows, ncols, uid);
    hold on;
    for tr = 1:nT
        spk_ms = t(Xmat(uid,:,tr) > 0);
        plot(spk_ms, tr * ones(size(spk_ms)), 'k.', 'MarkerSize', 1);
    end
    xline(0, 'r--', 'LineWidth', 0.8);
    xlim([t(1) t(end)]);
    ylim([0 nT+1]);
    title(sprintf('U%d', uid), 'FontSize', 7);
    if uid == 1
        xlabel('Time (ms)'); ylabel('Trial');
    else
        set(gca, 'XTickLabel',[], 'YTickLabel',[]);
    end
end
sgtitle(sprintf('%s  —  Raster per unit', session_name), 'Interpreter','none');
