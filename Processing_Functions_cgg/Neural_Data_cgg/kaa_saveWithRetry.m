function kaa_saveWithRetry(filename, variable_name, data, varargin)
%KAA_SAVEWITHRETRY Save a variable to a MAT file with retry logic
%
%   kaa_saveWithRetry(filename, variable_name, data)
%   kaa_saveWithRetry(filename, variable_name, data, 'MaxRetries', 5, 'RetryDelay', 2)
%
%   This function saves data to a MAT file with retry logic for robustness
%   in cluster/parallel environments where file system operations may
%   transiently fail due to NFS issues, file handle exhaustion, or other
%   filesystem-related problems.
%
%   Parameters:
%       filename      - Full path to the output MAT file
%       variable_name - Name of the variable as it will appear in the MAT file
%       data          - The data to save
%
%   Optional Parameters:
%       MaxRetries    - Maximum number of retry attempts (default: 5)
%       RetryDelay    - Base delay in seconds between retries (default: 2)
%                       Random jitter is added to prevent synchronized retries
%       MatVersion    - MAT file version: '-v7.3', '-v7', '-v6' (default: '-v7.3')
%       Verbose       - Show warning messages on retry (default: true)
%
%   Example:
%       kaa_saveWithRetry('/path/to/file.mat', 'my_data', data_struct);
%       kaa_saveWithRetry('/path/to/file.mat', 'my_data', data_struct, 'MaxRetries', 10);
%
%   See also: save

% Parse optional parameters
max_retries = CheckVararginPairs('MaxRetries', 5, varargin{:});
retry_delay = CheckVararginPairs('RetryDelay', 2, varargin{:});
mat_version = CheckVararginPairs('MatVersion', '-v7.3', varargin{:});
verbose = CheckVararginPairs('Verbose', true, varargin{:});

% Create a temporary struct to hold the data with the specified variable name
temp_struct.(variable_name) = data;

for attempt = 1:max_retries
    try
        % Use save with -struct to save fields of the struct as variables
        save(filename, '-struct', 'temp_struct', mat_version);
        return; % Success, exit function
    catch ME
        if attempt < max_retries
            if verbose
                warning('kaa_saveWithRetry: Attempt %d/%d failed to write %s: %s. Retrying in %.1f seconds...', ...
                    attempt, max_retries, filename, ME.message, retry_delay);
            end
            % Add random jitter to avoid synchronized retries across parallel workers
            pause(retry_delay + rand());
        else
            error('kaa_saveWithRetry:MaxRetriesExceeded', ...
                'Failed to write file after %d attempts: %s\nError: %s', ...
                max_retries, filename, ME.message);
        end
    end
end

end
