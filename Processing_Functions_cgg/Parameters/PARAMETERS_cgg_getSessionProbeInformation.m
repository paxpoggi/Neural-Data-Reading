function [probe_area,probe_selection] = PARAMETERS_cgg_getSessionProbeInformation(SessionName)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here


% This vector will determine what the probes that are being used are. Here
% the probes are 64 channel NeuroNexus probes and there are only 2 of them.
% The first 64 channels are one probe and the second 64 channels are
% another probe. If a single channel is desired then single_channel will 
% select the channel that will be used for analysis. The function should be
% run using each of the probes and can save them separately depending on
% which area they represent.
% first_probe=1:64;
% second_probe=65:128;
% single_channel=1;
single_channel=1;

% This variable determines which probe will be used for analysis. Use a
% cell array with all the probe locations that are being looked at.
probe_selection={single_channel};

% This variable determines what the probe area is and uses it for saving
% the data and organizing it by area. For the naming choose an area then a
% three digit number. (ACC_###, CD_###, PFC_###)

% first_probe_area='ACC_001';
% second_probe_area='CD_001';
single_channel_area='SINGLE_001';

% Use a cell array with all the probe locations that are being looked at.
probe_area={single_channel_area};

switch SessionName
    case 'Wo_VU595_01_2023-05-22_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        probe_selection={first_probe,second_probe,third_probe,...
            fourth_probe};
        first_probe_area = 'ACC_001';
        second_probe_area = 'ACC_002';
        third_probe_area = 'CD_001';
        fourth_probe_area = 'CD_002';
        probe_area = {first_probe_area,second_probe_area,...
            third_probe_area,fourth_probe_area};
     case 'Wo_VU595_02_2023-05-23_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        probe_selection={first_probe,second_probe,third_probe,...
            fourth_probe};
        first_probe_area = 'ACC_001';
        second_probe_area = 'ACC_002';
        third_probe_area = 'CD_001';
        fourth_probe_area = 'CD_002';
        probe_area = {first_probe_area,second_probe_area,...
            third_probe_area,fourth_probe_area};    
    case 'Wo_VU595_04_2023-05-25_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        probe_selection={first_probe,second_probe,third_probe,...
            fourth_probe};
        first_probe_area = 'ACC_001';
        second_probe_area = 'ACC_002';
        third_probe_area = 'CD_001';
        fourth_probe_area = 'CD_002';
        probe_area = {first_probe_area,second_probe_area,...
            third_probe_area,fourth_probe_area}; 
    case 'Wo_VU595_05_2023-05-26_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        probe_selection={first_probe,second_probe,third_probe,...
            fourth_probe};
        first_probe_area = 'ACC_001';
        second_probe_area = 'ACC_002';
        third_probe_area = 'CD_001';
        fourth_probe_area = 'CD_002';
        probe_area = {first_probe_area,second_probe_area,...
            third_probe_area,fourth_probe_area}; 
    case 'Wo_VU595_06_2023-05-29_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        probe_selection={first_probe,second_probe,third_probe,...
            fourth_probe};
        first_probe_area = 'ACC_001';
        second_probe_area = 'ACC_002';
        third_probe_area = 'CD_001';
        fourth_probe_area = 'CD_002';
        probe_area = {first_probe_area,second_probe_area,...
            third_probe_area,fourth_probe_area}; 
    case 'Wo_VU595_07_2023-05-30_A'
            first_probe=1:128;
            second_probe=129:256;
            third_probe=257:384;
            fourth_probe=385:512;
            probe_selection={first_probe,second_probe,third_probe,...
                fourth_probe};
            first_probe_area = 'ACC_001';
            second_probe_area = 'ACC_002';
            third_probe_area = 'CD_001';
            fourth_probe_area = 'CD_002';
            probe_area = {first_probe_area,second_probe_area,...
                third_probe_area,fourth_probe_area}; 
    case 'Wo_VU595_09_2023-06-01_A'
            first_probe=1:128;
            second_probe=129:256;
            third_probe=257:384;
            fourth_probe=385:512;
            probe_selection={first_probe,second_probe,third_probe,...
                fourth_probe};
            first_probe_area = 'ACC_001';
            second_probe_area = 'ACC_002';
            third_probe_area = 'CD_001';
            fourth_probe_area = 'CD_002';
            probe_area = {first_probe_area,second_probe_area,...
                third_probe_area,fourth_probe_area}; 
    case 'Wo_VU595_10_2023-06-02_A'
            first_probe=1:128;
            second_probe=129:256;
            third_probe=257:384;
            fourth_probe=385:512;
            probe_selection={first_probe,second_probe,third_probe,...
                fourth_probe};
            first_probe_area = 'ACC_001';
            second_probe_area = 'ACC_002';
            third_probe_area = 'CD_001';
            fourth_probe_area = 'CD_002';
            probe_area = {first_probe_area,second_probe_area,...
                third_probe_area,fourth_probe_area}; 
    case 'Wo_VU595_11_2023-06-05_A'
            first_probe=1:128;
            second_probe=129:256;
            third_probe=257:384;
            fourth_probe=385:512;
            probe_selection={first_probe,second_probe,third_probe,...
                fourth_probe};
            first_probe_area = 'ACC_001';
            second_probe_area = 'ACC_002';
            third_probe_area = 'CD_001';
            fourth_probe_area = 'CD_002';
            probe_area = {first_probe_area,second_probe_area,...
                third_probe_area,fourth_probe_area}; 
    case 'Wo_VU595_12_2023-06-06_A'
            first_probe=1:128;
            second_probe=129:256;
            third_probe=257:384;
            fourth_probe=385:512;
            probe_selection={first_probe,second_probe,third_probe,...
                fourth_probe};
            first_probe_area = 'ACC_001';
            second_probe_area = 'ACC_002';
            third_probe_area = 'CD_001';
            fourth_probe_area = 'CD_002';
            probe_area = {first_probe_area,second_probe_area,...
                third_probe_area,fourth_probe_area}; 

    case 'Wo_VU595_14_2023-06-08_A'
            first_probe=1:128;
            second_probe=129:256;
            third_probe=257:384;
            fourth_probe=385:512;
            probe_selection={first_probe,second_probe,third_probe,...
                fourth_probe};
            first_probe_area = 'ACC_001';
            second_probe_area = 'ACC_002';
            third_probe_area = 'CD_001';
            fourth_probe_area = 'CD_002';
            probe_area = {first_probe_area,second_probe_area,...
                third_probe_area,fourth_probe_area}; 
     case 'Wo_VU595_15_2023-06-09_A'
            first_probe=1:128;
            second_probe=129:256;
            third_probe=257:384;
            fourth_probe=385:512;
            probe_selection={first_probe,second_probe,third_probe,...
                fourth_probe};
            first_probe_area = 'ACC_001';
            second_probe_area = 'ACC_002';
            third_probe_area = 'CD_001';
            fourth_probe_area = 'CD_002';
            probe_area = {first_probe_area,second_probe_area,...
                third_probe_area,fourth_probe_area};         
    case 'Ig_VU595_01_2023-03-06_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_02_2023-03-07_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_03_2023-03-08_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_04_2023-03-09_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_05_2023-03-10_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_06_2023-03-13_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_07_2023-03-14_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe, second_probe, third_probe,...
            fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
  	    probe_area={first_probe_area, second_probe_area, third_probe_area,...
            fourth_probe_area, fifth_probe_area, sixth_probe_area};
    case 'Ig_VU595_08_2023-03-15_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_09_2023-03-16_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_10_2023-03-17_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_11_2023-03-20_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
     case 'Ig_VU595_12_2023-03-21_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_13_2023-03-22_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_14_2023-03-23_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
     case 'Ig_VU595_15_2023-03-24_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
     case 'Ig_VU595_16_2023-03-27_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
     case 'Ig_VU595_17_2023-03-28_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
     case 'Ig_VU595_18_2023-03-29_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
     case 'Ig_VU595_19_2023-03-30_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_20_2023-03-31_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_21_2023-03-03_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_22_2023-03-04_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_23_2023-03-05_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_24_2023-03-06_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    case 'Ig_VU595_25_2023-03-07_A'
        first_probe=1:128;
        second_probe=129:256;
        third_probe=257:384;
        fourth_probe=385:512;
        fifth_probe=513:640;
        sixth_probe=641:768;
        probe_selection={first_probe,second_probe,third_probe,...
        fourth_probe,fifth_probe,sixth_probe};
        first_probe_area='ACC_001';
        second_probe_area='ACC_002';
        third_probe_area='PFC_001';
        fourth_probe_area='PFC_002';
        fifth_probe_area='CD_001';
        sixth_probe_area='CD_002';
	        probe_area={first_probe_area,second_probe_area,...
		        third_probe_area,fourth_probe_area,fifth_probe_area,...
		        sixth_probe_area};
    % case 'Wo_Probe_01_23-02-13_003_01'
    %     first_probe=65:128;
    %     second_probe=1:64;
    %     third_probe=193:256;
    %     fourth_probe=129:192;
    %     fifth_probe=321:384;
    %     sixth_probe=257:320;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe,sixth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='PFC_002';
    %     fifth_probe_area='CD_001';
    %     sixth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area,...
    %         sixth_probe_area};
    % case 'Wo_Probe_01_23-02-21_006_01'
    %     first_probe=65:128;
    %     second_probe=1:64;
    %     third_probe=193:256;
    %     fourth_probe=321:384;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area};
    % case 'Wo_Probe_01_23-02-22_007_01'
    %     first_probe=65:128;
    %     second_probe=1:64;
    %     third_probe=193:256;
    %     fourth_probe=321:384;
    %     fifth_probe=257:320;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     fifth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area};
    % case 'Wo_Probe_01_23-02-23_008_01'
    %     first_probe=65:128;
    %     second_probe=1:64;
    %     third_probe=193:256;
    %     fourth_probe=321:384;
    %     fifth_probe=257:320;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     fifth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area};
    % case 'Wo_Probe_01_23-02-24_009_01'
    %     first_probe=65:128;
    %     second_probe=1:64;
    %     third_probe=193:256;
    %     fourth_probe=321:384;
    %     fifth_probe=257:320;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     fifth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area};
    % case 'Wo_Probe_01_23-02-27_010_01'
    %     first_probe=65:128;
    %     second_probe=1:64;
    %     third_probe=193:256;
    %     fourth_probe=321:384;
    %     fifth_probe=257:320;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     fifth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area};
    % case 'Wo_Probe_01_23-02-28_011_01'
    %     first_probe=65:128;
    %     second_probe=1:64;
    %     third_probe=193:256;
    %     fourth_probe=321:384;
    %     fifth_probe=257:320;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     fifth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area};
    % case 'Wo_Probe_01_23-03-01_012_01'
    %     first_probe=65:128;
    %     second_probe=1:64;
    %     third_probe=193:256;
    %     fourth_probe=321:384;
    %     fifth_probe=257:320;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     fifth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area};
    % case 'Wo_Probe_01_23-03-02_013_01'
    %     first_probe=65:128;
    %     second_probe=1:64;
    %     third_probe=193:256;
    %     fourth_probe=321:384;
    %     fifth_probe=257:320;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     fifth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area};
    % case 'Wo_Probe_01_23-03-03_014_01'
    %     first_probe=65:128;
    %     second_probe=1:64;
    %     third_probe=193:256;
    %     fourth_probe=321:384;
    %     fifth_probe=257:320;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     fifth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area};
    % case 'Wo_Probe_01_23-03-07_016_01'
    %     first_probe=65:128;
    %     second_probe=129:192;
    %     third_probe=321:384;
    %     fourth_probe=449:512;
    %     fifth_probe=385:448;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     fifth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area};
    % case 'Wo_Probe_01_23-03-08_017_01'
    %     first_probe=65:128;
    %     second_probe=129:192;
    %     third_probe=321:384;
    %     fourth_probe=449:512;
    %     fifth_probe=385:448;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     fifth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area};
    % case 'Wo_Probe_01_23-03-09_018_01'
    %     first_probe=65:128;
    %     second_probe=129:192;
    %     third_probe=321:384;
    %     fourth_probe=449:512;
    %     fifth_probe=385:448;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     fifth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area};
    % case 'Fr_Probe_02_22-04-27_003_01'
    %     first_probe=65:128;
    %     probe_selection={first_probe};
    %     first_probe_area='ACC_001';
    %     probe_area={first_probe_area};
    % case 'Fr_Probe_02_22-05-02_004_01'
    %     first_probe=1:64;
    %     second_probe=65:128;
    %     probe_selection={first_probe,second_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='CD_001';
    %     probe_area={first_probe_area,second_probe_area};
    % case 'Fr_Probe_02_22-05-03_005_01'
    %     first_probe=1:64;
    %     second_probe=65:128;
    %     probe_selection={first_probe,second_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='CD_001';
    %     probe_area={first_probe_area,second_probe_area};
    % case 'Fr_Probe_02_22-05-04_006_01'
    %     first_probe=1:64;
    %     second_probe=65:128;
    %     probe_selection={first_probe,second_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='CD_001';
    %     probe_area={first_probe_area,second_probe_area};
    % case 'Fr_Probe_02_22-05-05_007_01'
    %     first_probe=1:64;
    %     second_probe=65:128;
    %     probe_selection={first_probe,second_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='CD_001';
    %     probe_area={first_probe_area,second_probe_area};
    % case 'Fr_Probe_02_22-05-06_008_01'
    %     first_probe=1:64;
    %     second_probe=65:128;
    %     probe_selection={first_probe,second_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='CD_001';
    %     probe_area={first_probe_area,second_probe_area};
    % case 'Fr_Probe_02_22-05-09_009_01'
    %     first_probe=1:64;
    %     second_probe=65:128;
    %     probe_selection={first_probe,second_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='CD_001';
    %     probe_area={first_probe_area,second_probe_area};
    % case 'Fr_Probe_02_22-05-10_010_01'
    %     first_probe=1:64;
    %     second_probe=65:128;
    %     probe_selection={first_probe,second_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='CD_001';
    %     probe_area={first_probe_area,second_probe_area};
    % case 'Fr_Probe_02_22-05-11_011_01'
    %     first_probe=1:64;
    %     second_probe=65:128;
    %     probe_selection={first_probe,second_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='CD_001';
    %     probe_area={first_probe_area,second_probe_area};
    % case 'Fr_Probe_03_22-06-30_001_02'
    %     first_probe=65:128;
    %     second_probe=1:64;
    %     probe_selection={first_probe,second_probe};
    %     first_probe_area='CD_001';
    %     second_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area};
    % case 'Fr_Probe_03_22-07-13_002_01'
    %     first_probe=257:320;
    %     second_probe=321:384;
    %     third_probe=1:64;
    %     fourth_probe=65:128;
    %     fifth_probe=129:192;
    %     sixth_probe=193:256;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe,sixth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='PFC_002';
    %     fifth_probe_area='CD_001';
    %     sixth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area,...
    %         sixth_probe_area};
    % case 'Fr_Probe_03_22-07-15_003_01'
    %     first_probe=257:320;
    %     second_probe=321:384;
    %     third_probe=1:64;
    %     fourth_probe=129:192;
    %     fifth_probe=193:256;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe,fifth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     fifth_probe_area='CD_002';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area,fifth_probe_area};
    % case 'Fr_Probe_03_22-07-21_004_01'
    %     first_probe=257:320;
    %     second_probe=321:384;
    %     third_probe=1:64;
    %     fourth_probe=129:192;
    %     probe_selection={first_probe,second_probe,third_probe,...
    %         fourth_probe};
    %     first_probe_area='ACC_001';
    %     second_probe_area='ACC_002';
    %     third_probe_area='PFC_001';
    %     fourth_probe_area='CD_001';
    %     probe_area={first_probe_area,second_probe_area,...
    %         third_probe_area,fourth_probe_area};
    case 'none'
        probe_selection={};
        probe_area={};
    otherwise
        disp('!!!No Matching Session Name - Selecting Default!!!');
        disp(['!!![see top of '...
            'PARAMETERS_cgg_getSessionProbeInformation]!!!']);
end
end