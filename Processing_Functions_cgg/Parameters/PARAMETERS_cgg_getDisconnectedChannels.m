function cfg = PARAMETERS_cgg_getDisconnectedChannels(varargin)
%PARAMETERS_CGG_GETDISCONNECTEDCHANNELS Summary of this function goes here
%   Detailed explanation goes here



NumChannels = CheckVararginPairs('NumChannels', NaN, varargin{:});

switch NumChannels
    case 64
        Disconnected_Channels_GT=[30,60:64];
    case 128
        Disconnected_Channels_GT=[];
    otherwise
        Disconnected_Channels_GT=[30,60:64];
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

w = whos;
for a = 1:length(w) 
cfg.(w(a).name) = eval(w(a).name); 
end




end