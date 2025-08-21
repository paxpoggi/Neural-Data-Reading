function cfg = PARAMETERS_cgg_getDisconnectedChannels(varargin)
%PARAMETERS_CGG_GETDISCONNECTEDCHANNELS Summary of this function goes here
%   Detailed explanation goes here
monkey_name = CheckVararginPairs('ExperimentName', 'IDED_DBC_AH_AN/VU595_DBC', varargin{:});

switch monkey_name
    case 'Wotan_FLToken_Probe_01'

        Start_Group=2;
        End_Group=35;
        NumReplicates=10; %10
        InDistance='sqeuclidean';
        NumIterations=20;
        Disconnected_Channels_GT=[30,60:64];
        Disconnected_Threshold=0.5;
    case 'IDED_DBC_AH_AN/VU595_DBC'
        Start_Group=2;
        End_Group=35;
        NumReplicates=10; %10
        InDistance='sqeuclidean';
        NumIterations=20;
        Disconnected_Channels_GT=[];
        Disconnected_Threshold=0.5;
end

w = whos;
for a = 1:length(w) 
cfg.(w(a).name) = eval(w(a).name); 
end




end

