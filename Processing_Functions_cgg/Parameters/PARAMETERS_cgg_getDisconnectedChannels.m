function cfg = PARAMETERS_cgg_getDisconnectedChannels(varargin)
%PARAMETERS_CGG_GETDISCONNECTEDCHANNELS Returns parameters for disconnected channel detection
%
%   cfg = PARAMETERS_cgg_getDisconnectedChannels('NumChannels', N, 'SessionName', S, 'probe_area', P)
%
%   This function returns configuration parameters for the disconnected
%   channel detection algorithm. It supports session and probe-area specific
%   annotations for known bad channels that serve as "seeds" for the
%   clustering algorithm.
%
%   Parameters:
%       NumChannels - Number of channels in the recording (e.g., 64, 128)
%       SessionName - Name of the session (e.g., 'Ig_VU595_03_2023-03-08_A')
%       probe_area  - Name of the probe area (e.g., 'ACC_001', 'ACC_002')
%
%   The Disconnected_Channels_GT (ground truth) are used as seed channels
%   to identify other bad channels that cluster with them.
%
%   IMPORTANT: Bad channels are specific to BOTH session AND probe_area.
%   Channel 1 in ACC_001 is completely independent from channel 1 in ACC_002.
%
%   To add annotations, add a new case in the nested switch statements below.

NumChannels = CheckVararginPairs('NumChannels', NaN, varargin{:});
SessionName = CheckVararginPairs('SessionName', '', varargin{:});
probe_area = CheckVararginPairs('probe_area', '', varargin{:});

% =========================================================================
% SESSION AND PROBE-AREA SPECIFIC ANNOTATIONS
% =========================================================================
% Add session and probe-area specific bad channel annotations here.
% These channels will be used as "seeds" to find other bad channels
% that have similar noise characteristics.
%
% IMPORTANT: Annotations must specify BOTH SessionName AND probe_area
% because channel numbers are only meaningful within a specific probe.
%
% Structure:
%   switch SessionName
%       case 'YourSessionName'
%           switch probe_area
%               case 'ACC_001'
%                   Disconnected_Channels_GT = [list of bad channels];
%                   annotation_found = true;
%               case 'ACC_002'
%                   ...
%           end
%   end
% =========================================================================

annotation_found = false;

switch SessionName
    % =====================================================================
    % ADD YOUR SESSION-SPECIFIC ANNOTATIONS BELOW
    % =====================================================================

    % Example session annotation (uncomment and modify as needed):
    % case 'Ig_VU595_03_2023-03-08_A'
    %     switch probe_area
    %         case 'ACC_001'
    %             Disconnected_Channels_GT = [5, 10, 32, 64, 100, 128];
    %             annotation_found = true;
    %         case 'ACC_002'
    %             Disconnected_Channels_GT = [1, 15, 45, 90];
    %             annotation_found = true;
    %         case 'PFC_001'
    %             Disconnected_Channels_GT = [];
    %             annotation_found = true;
    %         otherwise
    %             annotation_found = false;
    %     end

    % case 'Another_Session_Name'
    %     switch probe_area
    %         case 'ACC_001'
    %             Disconnected_Channels_GT = [1, 2, 3];
    %             annotation_found = true;
    %         otherwise
    %             annotation_found = false;
    %     end

    % =====================================================================
    % END OF SESSION-SPECIFIC ANNOTATIONS
    % =====================================================================

    case 'Ig_VU595_03_2023-03-08_A'
        switch probe_area
            case 'ACC_001'
                Disconnected_Channels_GT = [1, 3, 5, 7, 8, 9, 11, 13, 15, 17];
                annotation_found = true;
            case 'ACC_002'
                Disconnected_Channels_GT = [1, 3, 5, 7, 8, 9, 11, 13, 15, 17, 19];
                annotation_found = true;
            otherwise
                % Probe area not annotated for this session - use defaults
                annotation_found = false;
        end

    otherwise
        annotation_found = false;
end

% Fall back to generic defaults based on NumChannels if no annotation found
if ~annotation_found
    switch NumChannels
        case 64
            Disconnected_Channels_GT=[30,60:64];
        case 128
            Disconnected_Channels_GT=[];
        otherwise
            Disconnected_Channels_GT=[30,60:64];
    end
end

% Log whether annotation was used or defaults were applied
if annotation_found
    fprintf('.. Using session-specific bad channel seeds for %s / %s: [%s]\n', ...
        SessionName, probe_area, num2str(Disconnected_Channels_GT));
else
    fprintf('.. No annotation found for %s / %s. Using default based on NumChannels=%d: [%s]\n', ...
        SessionName, probe_area, NumChannels, num2str(Disconnected_Channels_GT));
end

NumDisconnected = numel(Disconnected_Channels_GT);

End_Group = round((NumChannels - NumDisconnected)/2) + NumDisconnected;

Start_Group=2;
End_Group = max([Start_Group,End_Group]);
% End_Group=35;
NumReplicates=10; %10
InDistance='sqeuclidean';
NumIterations=20;
Disconnected_Threshold=0.5;
Wideband_Threshold=3500; % Channels with absolute wideband values exceeding this threshold will be added to seed list

w = whos;
for a = 1:length(w)
cfg.(w(a).name) = eval(w(a).name);
end




end
