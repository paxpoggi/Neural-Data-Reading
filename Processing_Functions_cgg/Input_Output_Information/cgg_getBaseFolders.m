function [inputfolder_base,outputfolder_base,temporaryfolder_base,...
    Current_System] = cgg_getBaseFolders(varargin)
%CGG_GETBASEFOLDERS Summary of this function goes here
%   Detailed explanation goes here

isfunction=exist('varargin','var');

if isfunction
WantTEBA = CheckVararginPairs('WantTEBA', false, varargin{:});
else
if ~(exist('WantTEBA','var'))
WantTEBA=false;
end
end


[~,Environment_Variables]=system('env');
Environment_Variables=splitlines(Environment_Variables);
Root_Directory=split(Environment_Variables(startsWith(Environment_Variables,"PATH")),'/');
Root_Directory=Root_Directory{2};
Current_User=split(Environment_Variables(startsWith(Environment_Variables,"USER")),'=');
Current_User=Current_User{2};

if strcmp(Root_Directory,'Users')
Root_Directory = 'usr';
end

switch Root_Directory
    case "usr"
        Current_System="Personal Computer";
        % If not me I'm not sure how someone will want to access the files.
        % Add a new case here for a new user
        switch Current_User
            case 'cgerrity'
                if cgg_checkACCREMounted('/Users/cgerrity/Documents') && ~WantTEBA
        inputfolder_base='/Users/cgerrity/Documents/ACCRE';
        outputfolder_base='/Users/cgerrity/Documents/ACCRE';
        temporaryfolder_base='/Users/cgerrity/Documents/ACCRE_DATA';
        % temporaryfolder_base='/Users/cgerrity/Documents/ACCRE_NoBackup';
                else
        inputfolder_base='/Volumes/Womelsdorf Lab';
        outputfolder_base='/Volumes/gerritcg''s home';
        temporaryfolder_base='/Volumes/gerritcg''s home';
                end
            case 'newuser'
        inputfolder_base='/Volumes/Womelsdorf Lab'; 
        % Folder where 'Data_neural' is accessed from your computer
        outputfolder_base='/Volumes/gerritcg''s home';
        % Folder where you would like all of the processing to go
        temporaryfolder_base='/Volumes/gerritcg''s home';   
        % Folder where any temporary files should go
            case 'paxpoggi'
        inputfolder_base='/Volumes/Womelsdorf Lab'; 
        % Folder where 'Data_neural' is accessed from your computer
        outputfolder_base='/Volumes/Extreme SSD/Womelsdorf/Preprocessed Data';
        % folder where the processing output goes
        temporaryfolder_base='/Volumes/Extreme SSD/Womelsdorf/Preprocessed Data';
        % temporary files
        end
    case "data"
        Current_System="TEBA";
        inputfolder_base='/data';
        outputfolder_base=['/data/users/',Current_User];
        temporaryfolder_base=['/data/users/',Current_User];
    % case {"accre","panfs"}
    %     Current_System="ACCRE";
    %     inputfolder_base=['/home/',Current_User];
    %     outputfolder_base=['/home/',Current_User];
    %     temporaryfolder_base=['/data/womelsdorf_lab/',Current_User];
    %     % temporaryfolder_base=['/nobackup/user/',Current_User];
    % modified accre case to pull from /data/womelsdorf_lab and to store
    % processed data there
    case {"accre","panfs"}
        Current_System="ACCRE";
        inputfolder_base='/data/womelsdorf_lab/poggigp';
        outputfolder_base='/data/womelsdorf_lab/poggigp/processed_data';
        temporaryfolder_base='/data/womelsdorf_lab/poggigp/processed_data';
    % print root directory if cases aren't entered for debugging
    otherwise
        error("Unrecognized Root_Directory='%s'. Please add a case for this system.", Root_Directory);
end

end

