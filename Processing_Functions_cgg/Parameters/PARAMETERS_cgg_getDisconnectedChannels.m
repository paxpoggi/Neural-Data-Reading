function cfg = PARAMETERS_cgg_getDisconnectedChannels(varargin)
%PARAMETERS_CGG_GETDISCONNECTEDCHANNELS Summary of this function goes here
%   Detailed explanation goes here
monkey_name = CheckVararginPairs('monkey_name', '', varargin{:});

switch monkey_name
    case 'Frey'

        Start_Group=2;
        End_Group=35;
        NumReplicates=10; %10
        InDistance='sqeuclidean';
        NumIterations=20;
        Disconnected_Channels_GT=[30,60:64];
        Disconnected_Threshold=0.5;
    case {'Igor', 'Wotan'}
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

