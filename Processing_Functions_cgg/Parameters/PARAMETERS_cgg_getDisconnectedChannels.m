function cfg = PARAMETERS_cgg_getDisconnectedChannels(varargin)
%PARAMETERS_CGG_GETDISCONNECTEDCHANNELS Summary of this function goes here
%   Detailed explanation goes here



Start_Group=2;
End_Group=35;
NumReplicates=10; %10
InDistance='sqeuclidean';
NumIterations=20;
% Disconnected_Channels_GT=[30,60:64];
Disconnected_Channels_GT=[];
Disconnected_Threshold=0.5;

w = whos;
for a = 1:length(w) 
cfg.(w(a).name) = eval(w(a).name); 
end




end

