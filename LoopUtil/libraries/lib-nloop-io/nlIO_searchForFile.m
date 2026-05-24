function [ fnames_found paths_found ] = ...
  nlIO_searchForFile( startdir, targetname )

% function [ fnames_found paths_found ] = ...
%   nlIO_searchForFile( startdir, targetname )
%
% This searches a directory tree for files that match the specified name.
% This wraps "dir", so filenames can contain wildcards.
%
% "startdir" is the top-level folder to look in.
% "targetname" is the file name to match. This is passed to "dir", so it can
%   contain wildcards.
%
% "fnames_found" is a cell array containing the names of files found, without
%   paths.
% "paths_found" is a cell array containing the paths of files found, without
%   filenames.


fnames_found = {};
paths_found = {};

dirlist = dir([ startdir filesep '**' filesep targetname ]);

for didx = 1:length(dirlist)
  thisentry = dirlist(didx);
  thisfullname = [ thisentry.folder filesep thisentry.name ];

  % Skip macOS resource-fork files (._filename) created when copying from Mac.
  if startsWith(thisentry.name, '._')
    continue;
  end

  if ~isdir(thisfullname)
    fnames_found = [ fnames_found { thisentry.name } ];
    paths_found = [ paths_found { thisentry.folder } ];
  end
end

% NOTE - If we had multiple matching files in a folder, we'll have duplicate
% entries in "paths_found". This is acceptable.


% Done.

end


%
% This is the end of the file.
