function foldermeta = nlIntan_probeFolder( indir )

% function foldermeta = nlIntan_probeFolder( indir )
%
% This checks for the existence of Intan-format data files in the specified
% folder, and constructs a folder metadata structure if data is found.
%
% If no data is found, an empty structure is returned.
%
% "indir" is the directory to search.
%
% "foldermeta" is a folder metadata structure, per FOLDERMETA.txt.


% Initialize.

foldermeta = struct();


% Get file lists.
% We want all files (for per-type and per-channel files) and RHS/RHD files
% (for metadata and monolithic files).

dirfiles = {};
metafilelist = {};

if isdir(indir)

  dirfiles = dir(indir);
  dirfiles = { dirfiles.name };

  scratchrec = dir([ indir '/*.rhd' ]);
  scratchrec = { scratchrec.name };
  scratchstim = dir([ indir '/*.rhs' ]);
  scratchstim = { scratchstim.name };
  % Skip macOS resource-fork files (._filename) created when copying from Mac.
  scratchrec  = scratchrec(~startsWith(scratchrec,  '._'));
  scratchstim = scratchstim(~startsWith(scratchstim, '._'));

  metafilelist = [ scratchrec scratchstim ];
  metafilelist = strcat([ indir filesep ], metafilelist);

end


% If we have metadata files, choose the first one.
% FIXME - Not handling the "multiple files" case!
% This can happen if the user saves monolithic data in N-minute blocks.

metafile = '';
devtype = 'none';

if ~isempty(metafilelist)
  metafilelist = sort(metafilelist);
  metafile = metafilelist{1};
  devtype = 'intan';
end


% Proceed if we have a metadata file.

if ~isempty(metafile)

  % This returns an empty structure array on failure.
  nativemeta = vIntan_readHeader(metafile);

  if isempty(nativemeta)
    % FIXME - Diagnostics.
    disp(sprintf( '###  Couldn''t read Intan metadata from "%s".', metafile ));
  else

    % Copy selected metadata elements.

    freq_params = nativemeta.frequency_parameters;
    samprate_ephys = freq_params.amplifier_sample_rate;
    samprate_aux = freq_params.aux_input_sample_rate;
    samprate_supply = freq_params.supply_voltage_sample_rate;
    samprate_ain = freq_params.board_adc_sample_rate;
    samprate_din = freq_params.board_dig_in_sample_rate;

    voltages = nativemeta.voltage_parameters;

    stim_step_size = 0;
    if isfield(nativemeta, 'stim_parameters')
      stim_step_size = nativemeta.stim_parameters.stim_step_size;
    end

    % Build flag metadata, in case we need it.
    noflags = struct([]);
    flagdefs = struct( 'fastsettle', uint16(2^13), ...
      'chargerecover', uint16(2^14), 'compliancelimit', uint16(2^15) );


    % Initialize output.
    foldermeta = struct( 'path', indir, 'devicetype', devtype, ...
      'banks', struct(), 'nativemeta', nativemeta );

    % Initialize handle metadata.
    % NOTE - Monolithic format does not have a separate time file.
    format = 'bogus';
    timefile = [ indir, filesep, 'time.dat' ];


    %
    % Monolithic data.

% FIXME - Monolithic NYI!
    if nativemeta.num_data_blocks > 0
      format = 'monolithic';

      % Examine the header to see which types of bank exist.

      % Amplifier banks.
      chanlist = { nativemeta.amplifier_channels.native_channel_name };
      chanbanks = { nativemeta.amplifier_channels.port_prefix };
      uniquebanks = unique(chanbanks);
      for bidx = 1:length(uniquebanks)
        thisbank = uniquebanks{bidx};
        banklabel = [ 'Amp', thisbank ];

        selectmask = strcmp(chanbanks, thisbank);
        chansubset = chanlist(selectmask);

        thishandle = struct( 'format', 'monolithic', ...
          'fname', [ indir, filesep, metafile ] );
%        foldermeta.banks.(banklabel) = struct( ...
%          'channels', chansubset, 'samprate', samprate_ephys, ...
%          'banktype', 'analog', 'handle', thishandle, ...
%          'nativemeta', nativemeta );
      end
    end


    %
    % Banks stored in NeuroScope format.

    % NOTE - Files are all saved at the ephys rate, even if sampled at
    % lower rates.

    if ismember('amplifier.dat', dirfiles)
      % FIXME - Neuroscope NYI.
    end

    if ismember('auxiliary.dat', dirfiles)
      % FIXME - Neuroscope NYI.
    end

    if ismember('dcamplifier.dat', dirfiles)
      % FIXME - Neuroscope NYI.
    end

    if ismember('analogin.dat', dirfiles)
      % FIXME - Neuroscope NYI.
    end

    if ismember('analogout.dat', dirfiles)
      % FIXME - Neuroscope NYI.
    end

    if ismember('digitalin.dat', dirfiles)
      % FIXME - Neuroscope NYI.
    end

    if ismember('digitalout.dat', dirfiles)
      % FIXME - Neuroscope NYI.
    end

    if ismember('stim.dat', dirfiles)
      % FIXME - Neuroscope NYI.
    end

    if ismember('supply.dat', dirfiles)
      % FIXME - Neuroscope NYI.
    end


    %
    % Banks stored in per-channel format.

    % NOTE - Files are all saved at the ephys rate, even if sampled at
    % lower rates.
    % FIXME - The filename prefix is saved as "port_prefix" in the metadata.
    % We don't need to probe for all possible files if we check that.


    % Amplifier channels are "amp-A-000.dat" .. "amp-H-127.dat".
    % This is the only signal file with signed data.

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'amp-(\w+)-(\d+)\.dat', 'Amp', '', samprate_ephys, 'analog', ...
      'int16', 0, voltages.amplifier_scale, 'uV', '', noflags );


    % Headstage auxiliary channels are "amp-A-AUX1.dat" .. "amp-H-AUX6.dat".

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'amp-(\w+)-AUX(\d+)\.dat', 'Aux', '', samprate_ephys, 'analog', ...
      'uint16', 0, voltages.aux_scale, 'V', '', noflags );


    % Amplifier low-gain DC-coupled channels are
    % "dc-A-000.dat" .. "dc-H-127.dat".

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'dc-(\w+)-(\d+)\.dat', 'Dc', '', samprate_ephys, 'analog', ...
      'uint16', voltages.dcamp_zerolevel, voltages.dcamp_scale, 'V', ...
      '', noflags );


    % Controller analog inputs are "board-ADC-00.dat" .. "board-ADC-07.dat"
    % or "board-ANALOG-IN-00.dat" .. "board-ANALOG-IN-07.dat".
    % FIXME - Saved as 1..8, not 0..7!

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'board-(ADC)-(\d+)\.dat', '', 'Ain', samprate_ephys, 'analog', ...
      'uint16', voltages.board_analog_zerolevel, ...
      voltages.board_analog_scale, 'V', '', noflags );

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'board-(ANALOG-IN)-(\d+)\.dat', '', 'Ain', samprate_ephys, 'analog', ...
      'uint16', voltages.board_analog_zerolevel, ...
      voltages.board_analog_scale, 'V', '', noflags );


    % Controller analog outputs are
    % "board-ANALOG-OUT-00.dat" .. "board-ANALOG-OUT-07.dat".
    % FIXME - Saved as 1..8, not 0..7!

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'board-(ANALOG-OUT)-(\d+)\.dat', '', 'Aout', samprate_ephys, ...
      'analog', 'uint16', voltages.board_analog_zerolevel, ...
      voltages.board_analog_scale, 'V', '', noflags );


    % Controller digital inputs are "board-DIN-00.dat" .. "board-DIN-15.dat"
    % or "board-DIGITAL-IN-00.dat" .. "board-DIGITAL-IN-15.dat".
    % FIXME - Saved as 1..16, not 0..15!

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'board-(DIN)-(\d+)\.dat', '', 'Din', samprate_ephys, 'boolean', ...
      'uint16', 0, 1, '', '', noflags );

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'board-(DIGITAL-IN)-(\d+)\.dat', '', 'Din', samprate_ephys, 'boolean', ...
      'uint16', 0, 1, '', '', noflags );


    % Digital outputs are "board-DOUT-00.dat" .. "board-DOUT-15.dat".
    % or "board-DIGITAL-OUT-00.dat" .. "board-DIGITAL-OUT-15.dat".
    % FIXME - Saved as 1..16, not 0..15!

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'board-(DOUT)-(\d+)\.dat', '', 'Dout', samprate_ephys, 'boolean', ...
      'uint16', 0, 1, '', '', noflags );

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'board-(DIGITAL-OUT)-(\d+)\.dat', '', 'Dout', ...
      samprate_ephys, 'boolean', ...
      'uint16', 0, 1, '', '', noflags );


    % Stimulation outputs and flags are "stim-A-000.dat" .. "stim-H-127.dat".
    % Probably actually maxes out at "stim-D-031.dat".
    % NOTE - This is encoded as uint16, but we're splitting it into signed
    % int16 and uint16.
    % NOTE - Stimulation step size units are amperes; convert to uA.

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'stim-(\w+)-(\d+)\.dat', 'Stim', '', samprate_ephys, 'analog', ...
      'int16', 0, stim_step_size * 1e+6, 'uA', 'stimcurrent', noflags );

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'stim-(\w+)-(\d+)\.dat', 'Flags', '', samprate_ephys, 'flagvector', ...
      'uint16', 0, 1, '', 'stimflags', flagdefs );


    % Power supply voltages are "vdd-A-VDD1.dat" .. "vdd-H-VDD2.dat".

    foldermeta.banks = helper_addChannelFileBanks( ...
      foldermeta.banks, indir, dirfiles, timefile, ...
      'vdd-(\w+)-VDD(\d+)\.dat', 'Vdd', '', samprate_ephys, 'analog', ...
      'uint16', 0, voltages.supply_scale, 'V', '', noflags );

  end

end


% Done.

end



%
% Helper functions.


% This gets a list of channels and banks matching a filename pattern.
% Channel filenames have the form "(prefix)-(bank)-(number).dat".
% We're assuming we're passed a pattern with two tokens, the first of which
% returns character array data and the second of which returns numeric data.

function [ chanlist chanbanks chanfiles ] = ...
  helper_getChannelFiles(indir, dirfiles, pattern)

  chanlist = [];
  chanbanks = {};
  chanfiles = {};

  outcount = 0;

  for fidx = 1:length(dirfiles)

    thisfile = dirfiles{fidx};
    tokenlist = regexp( thisfile, pattern, 'tokens' );

    if ~isempty(tokenlist)
      thisbank = tokenlist{1}{1};
      thischan = str2double(tokenlist{1}{2});

      outcount = outcount + 1;
      chanlist(outcount) = thischan;
      chanbanks{outcount} = thisbank;
      chanfiles{outcount} = [ indir, filesep, thisfile ];
    end

  end
end



% This gets a list of channels and banks matching a filename pattern and
% adds the resulting bank metadata to the metadata structure.
% If "singlelabel" is non-empty, it's the new bank label. If it's empty,
% the native metadata's bank label is appended to "multiprefix" to make a
% bank label.
% If "flagdefs" is non-empty, it's added to the bank metadata as "flagdefs".

function newbanks = helper_addChannelFileBanks( ...
  oldbanks, indir, dirfiles, timefile, ...
  pattern, multiprefix, singlelabel, samprate, sigtype, ...
  nativetype, zerolevel, scale, units, specialtype, flagdefs )

  newbanks = oldbanks;

  [ chanlist chanbanks chanfiles ] = ...
    helper_getChannelFiles(indir, dirfiles, pattern);

  if ~isempty(chanlist)
    % FIXME - Get the sample count from the time file, since all channels
    % and banks use the same sampling rate with one-file-per-channel.
    % We know that the time file is int32.
    timestats = dir(timefile);
    sampcount = round(timestats.bytes / 4);

    uniquebanks = unique(chanbanks);
    for bidx = 1:length(uniquebanks)
      thisbank = uniquebanks{bidx};

      banklabel = singlelabel;
      if isempty(singlelabel)
        banklabel = [ multiprefix, thisbank ];
      end

      selectmask = strcmp(chanbanks, thisbank);
      chansubset = chanlist(selectmask);
      filesubset = chanfiles(selectmask);

      thishandle = struct( 'format', 'onefileperchan', ...
        'special', specialtype, ...
        'chanfilechans', chansubset, 'chanfilenames', { filesubset }, ...
        'timefile', timefile );
      newbanks.(banklabel) = struct( ...
        'channels', chansubset, 'samprate', samprate, ...
        'sampcount', sampcount, 'banktype', sigtype, ...
        'nativetimetype', 'int32', 'nativedatatype', nativetype, ...
        'nativezerolevel', zerolevel, 'nativescale', scale, ...
        'fpunits', units, 'handle', thishandle );
      if ~isempty(flagdefs)
        newbanks.(banklabel).flagdefs = flagdefs;
      end
    end
  end
end


%
% This is the end of the file.
