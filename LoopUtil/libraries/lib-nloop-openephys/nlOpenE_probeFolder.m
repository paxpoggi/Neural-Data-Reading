function foldermeta = nlOpenE_probeFolder( indir )

% function foldermeta = nlOpenE_probeFolder( indir )
%
% This checks for the existence of Open Ephys format data files in the
% specified folder, and constructs a folder metadata structure if data is
% found.
%
% If no data is found, an empty structure is returned.
%
% "indir" is the directory to search.
%
% "foldermeta" is a folder metadata structure, per FOLDERMETA.txt.


% Initialize.

foldermeta = struct();


% We're looking for either "structure.oebin" or "settings.xml".

fileperchan = [ indir filesep 'settings.xml' ];
filemonolithic = [ indir filesep 'structure.oebin' ];


% Process what we can find. Give priority to monolithic data.

if isfile(filemonolithic)

  bankscontinuous = list_open_ephys_binary(filemonolithic, 'continuous');
  banksevents = list_open_ephys_binary(filemonolithic, 'events');
  banksspikes = list_open_ephys_binary(filemonolithic, 'spikes');


  allbanks = struct();

  % We're storing the native order of continuous channels only.
  nativechans = struct([]);


  % FIXME - Keep track of the maximum sample count from continuous banks,
  % and assume that the sample range for event banks is the same.
  maxsampcount = 0;
  firsttimelist = [];


  % Process continuous banks.
  % FIXME - Using black magic to separate merged channel types.

  for bidx = 1:length(bankscontinuous)

    % Open the data file without loading it into memory, to get header data.
    % Also check to see if data was actually recorded (nonzero sample count).
    % continuous.dat may be absent (e.g., not uploaded to ACCRE); skip gracefully
    % so that event bank processing (phase 2, below) still runs.
    try
      thisdata = ...
        load_open_ephys_binary(filemonolithic, 'continuous', bidx, 'mmap');
    catch
      continue;
    end
    thisdataheader = thisdata.Header;
    thisdatasize = length(thisdata.Timestamps);
    thisdatatimetype = class(thisdata.Timestamps);
    thisdatanativetype = thisdata.Data.Format{1};
    thisfirsttime = min(thisdata.Timestamps);

    % FIXME - We can't explicitly close the memmapfile object.
    % FIXME - Matlab's documentation says the memmapfile object can be
    % cleared to release it, but this doesn't seem to work in my tests.
    % FIXME - Count on it vanishing when "thisdata" is reassigned and when
    % exiting function scope. This is an ugly kludge!


    % Update the maximum sample count and first timestamp list.
    maxsampcount = max(maxsampcount, thisdatasize);
    firsttimelist = [ firsttimelist thisfirsttime ];


    % If we have data, split the real bank into multiple virtual banks.
    if thisdatasize > 0
      % Store common template information.
      thisbankcommon = struct( 'samprate', thisdataheader.sample_rate, ...
        'sampcount', thisdatasize, 'nativetimetype', thisdatatimetype, ...
        'nativedatatype', thisdatanativetype, 'firsttime', thisfirsttime, ...
        'nativemeta', thisdataheader );

      % Split this bank into sub-banks by black magic.
      % Record the native order in case the caller needs it.
      [ thisbankmetaset thisorderbanks thisorderchans ] = ...
        helper_splitContinuousBank( ...
        thisbankcommon, 'monolithic', filemonolithic, bidx, thisdataheader );

      % Update metadata.
      thisbanknamelist = fieldnames(thisbankmetaset);
      for nidx = 1:length(thisbanknamelist)
        thisname = thisbanknamelist{nidx};
        thisbankmeta = thisbankmetaset.(thisname);

        % Rename duplicates. This will look ugly but should rarely happen.
        if isfield(allbanks, thisname)
          oldname = thisname;
          thisname = sprintf('b%d%s', bidx, thisname);

          % Rename this bank in the native channel order list too.
          thisorderbanks(strcmp(thisorderbanks, oldname)) = { thisname };
        end

        allbanks.(thisname) = thisbankmeta;
      end

      % Save the native channel order.
      thisnativechans = ...
        struct( 'bank', thisorderbanks, 'channel', thisorderchans );
      if isempty(nativechans)
        nativechans = thisnativechans;
      else
        nativechans = vertcat(nativechans, thisnativechans);
      end
    end
  end


  % Process event banks. This is where TTL data ends up.

  % OpenEphys uses "TTL_N" and "TEXT_group_N" as magic strings, with a
  % prefix indicating which device they came from.

  ttlcount = 0;

  for bidx = 1:length(banksevents)

    % Open this bank, to get header information and sample count.
    % FIXME - Blithely assuming we can fit event data in memory.

    thisdata = ...
      load_open_ephys_binary(filemonolithic, 'events', bidx);
    thisdataheader = thisdata.Header;
    thisdatasize = length(thisdata.Timestamps);
    thisdatachans = thisdata.Header.num_channels;

    if (thisdatasize > 0) && (thisdatachans > 0)
      % Figure out if we're dealing with TTL data or text data.
      % FIXME - Not parsing text data, as npy doesn't read it!

      thisdataname = banksevents{bidx};
      % The "description" and "channel_name" fields both exist, with similar
      % content, for OE events. "channel_name" is more readable.
      thisdatadesc = thisdataheader.channel_name;

      if contains( thisdataname, 'ttl', 'IgnoreCase', true )

        % Common components.

        % Compute the letter before incrementing, so the first is 'A' + 0.
        thisbankletter = char('A' + ttlcount);
        ttlcount = ttlcount + 1;

        thisdatatimetype = class(thisdata.Timestamps);
        thisfirsttime = min(thisdata.Timestamps);

        % Metadata template.
        commonmeta = struct( 'samprate', thisdataheader.sample_rate, ...
          'nativetimetype', thisdatatimetype, 'firsttime', thisfirsttime, ...
          'nativezerolevel', 0, 'nativescale', 1, 'fpunits', '', ...
          'nativemeta', thisdataheader );

        % Nonstandard metadata that we still want.
        commonmeta.nativedesc = thisdatadesc;

        % Handle.
        commonmeta.handle = struct( ...
          'format', 'monolithic', 'type', 'events', ...
          'oefile', filemonolithic, 'oebank', bidx );

        % Update the first timestamp list.
        firsttimelist = [ firsttimelist thisfirsttime ];

        % Save two banks - one for individual channels, and one for words.


        % Full data words.

        thisbankname = [ 'DigWords' thisbankletter ];

        thisbankmeta = commonmeta;
        % FIXME - Record the maximum sample count, not the number of events.
        thisbankmeta.sampcount = maxsampcount;
        thisbankmeta.channels = [ 0 ];
        thisbankmeta.banktype = 'eventwords';
        % FIXME - Assuming a maximum of 64 TTL lines in the bank.
        thisbankmeta.nativedatatype = 'uint64';

        % Store this bank.
        allbanks.(thisbankname) = thisbankmeta;


        % Individual boolean signals.

        % FIXME - These have a common time series!
        % This means that within each bit, you'll get strings of repeated
        % 0s and 1s, representing times when _other_ bits changed.

        % FIXME - Including all channels, whether they had events or not.
        % Channels all implicitly start with a data value of "0".

        % Open Ephys numbers TTL lines starting at 1.
        thisbankchans = 1:thisdataheader.num_channels;

        thisbankname = [ 'DigBits' thisbankletter ];

        thisbankmeta = commonmeta;
        % FIXME - Record the maximum sample count, not the number of events.
        thisbankmeta.sampcount = maxsampcount;
        thisbankmeta.channels = thisbankchans;
        thisbankmeta.banktype = 'eventbool';
        thisbankmeta.nativedatatype = 'logical';

        % Store this bank.
        allbanks.(thisbankname) = thisbankmeta;

      end
    end

  end


  % FIXME - Spikes NYI.


  % Assemble the folder metadata structure.
  % FIXME - No native metadata to store, since we can't read settings.xml.

  thisfirsttime = 0;
  if ~isempty(firsttimelist)
    thisfirsttime = min(firsttimelist);
  end

  foldermeta = struct( 'path', indir, 'devicetype', 'openephys', ...
    'banks', allbanks, 'firsttime', thisfirsttime );

  if ~isempty(nativechans)
    foldermeta.nativeorder = nativechans;
  end

elseif isfile(fileperchan)

  % FIXME - Per-channel Open Ephys format NYI!

end


% Done.

end



%
% Helper functions.


% This examines channel metadata within Open Ephys continuous data and
% splits it into banks based on content.
% We need to add "channels", "banktype", "nativezerolevel", "nativescale",
% "fpunits", and "handle".

function [ bankmetaset nativeorderbanks nativeorderchans ] = ...
  helper_splitContinuousBank( ...
    metacommon, oeformat, oefile, oebankindex, dataheader )

  % Initialize output.
  bankmetaset = struct();

  % Get metadata.
  channelmeta = dataheader.channels;
  channelnames = { channelmeta.channel_name };


  % Extract metadata that we expect to be consistent within banks.

  channeldescs = { channelmeta.description };
  channelscales = [ channelmeta.bit_volts ];
  channelunits = { channelmeta.units };

  % Get prefixes from names. These should also be consistent within banks.
  % We'll get Open Ephys's annotated channel numbers too.

  % Tolerate the "name does not end in a number" case.
  alltokens = regexp( channelnames, '^(.*?)_?(\d*)$', 'tokens' );

  % There's probably a one-line way to do this, but I'm having trouble
  % finding it.
  % Indexing is alltokens{channelnum}{matchnum}{tokennum}.
  % Since any possible string will match exactly once, "matchnum" is 1.
  channelnamebanks = {};
  channelnamenumbers = [];
  for cidx = 1:length(alltokens)
    channelnamebanks{cidx} = alltokens{cidx}{1}{1};
    thisnum = str2num(alltokens{cidx}{1}{2});
    if isempty(thisnum)
      thisnum = 0;
    end
    channelnamenumbers(cidx) = thisnum;
  end

  % Store the native order of bank and channel tuples as column cell arrays.

  nativeorderbanks = channelnamebanks;
  if ~iscolumn(nativeorderbanks)
    nativeorderbanks = transpose(nativeorderbanks);
  end

  nativeorderchans = num2cell(channelnamenumbers);
  if ~iscolumn(nativeorderchans)
    nativeorderchans = transpose(nativeorderchans);
  end


  % Walk through the unique names in the outer loop, and other parts in the
  % inner loop.

  uniquenames = unique(channelnamebanks);
  uniquedescs = unique(channeldescs);
  uniquescales = unique(channelscales);
  uniqueunits = unique(channelunits);

  for nidx = 1:length(uniquenames)

    % Get this prospective bank name and its selection mask.

    thisname = uniquenames{nidx};
    namemask = strcmp(channelnamebanks, thisname);

    % Walk through the other token permutations and build their masks as well.

    casecount = 0;
    casedescs = {};
    casescales = [];
    caseunits = {};
    casemasks = {};

    for didx = 1:length(uniquedescs)
      thisdesc = uniquedescs{didx};
      descmask = strcmp(channeldescs, thisdesc);
      for sidx = 1:length(uniquescales)
        thisscale = uniquescales(sidx);
        scalemask = (channelscales == thisscale);
        for uidx = 1:length(uniqueunits)
          thisunit = uniqueunits{uidx};
          unitmask = strcmp(channelunits, thisunit);

          selectmask = namemask & descmask & scalemask & unitmask;
          if sum(selectmask) > 0
            casecount = casecount + 1;
            casedescs{casecount} = thisdesc;
            casescales(casecount) = thisscale;
            caseunits{casecount} = thisunit;
            casemasks{casecount} = selectmask;
          end

        end
      end
    end

    % Handle zero, one, or many cases. There really shouldn't be zero.

    if casecount > 1
      % Multiple cases for this channel prefix.
      % Use "PrefixN" rather than "Prefix" as the bank name.

      for cidx = 1:casecount
        thisbank = sprintf('%s%d', thisname, cidx);
        thismeta = metacommon;

        thismask = casemasks{cidx};
        thismeta.channels = channelnamenumbers(thismask);

        % FIXME - Force "analog", "zero is zero".
        thismeta.banktype = 'analog';
        thismeta.nativezerolevel = 0;

        thismeta.nativescale = casescales(cidx);
        thismeta.fpunits = caseunits{cidx};

        % Nonstandard metadata that we still want.
        thismeta.nativedesc = casedescs{cidx};

        thismeta.handle = struct( ...
          'format', 'monolithic', 'type', 'continuous', 'oefile', oefile, ...
          'oebank', oebankindex, 'selectmask', thismask );

        bankmetaset.(thisbank) = thismeta;
      end
    elseif casecount > 0
      % One case for this channel prefix.

      thisbank = thisname;
      thismeta = metacommon;

      thismask = casemasks{1};
      thismeta.channels = channelnamenumbers(thismask);

      % FIXME - Force "analog", "zero is zero".
      thismeta.banktype = 'analog';
      thismeta.nativezerolevel = 0;

      thismeta.nativescale = casescales(1);
      thismeta.fpunits = caseunits{1};

      % Nonstandard metadata that we still want.
      thismeta.nativedesc = casedescs{1};

      thismeta.handle = struct( ...
        'format', 'monolithic', 'type', 'continuous', 'oefile', oefile, ...
        'oebank', oebankindex, 'selectmask', thismask );

      bankmetaset.(thisbank) = thismeta;
    end

  end

end


%
% This is the end of the file.
