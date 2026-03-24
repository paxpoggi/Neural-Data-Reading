%==========================================================================
% Recursively walks through a Matlab hierarchy and converts it to the
% hierarchy of java.util.ArrayListS and java.util.MapS. Then calls
% Snakeyaml to write it to a file.
%=========================================================================
function result = WriteYaml(filename, data, flowstyle)
    if ~exist('flowstyle','var')
        flowstyle = 0;
    end;
    if ~ismember(flowstyle, [0,1])
        error('Flowstyle must be 0,1 or empty.');
    end;
    result = [];
    [pth,~,~] = fileparts(mfilename('fullpath'));
    try
        import('org.yaml.snakeyaml.*');
        javaObject('Yaml');
    catch
        dp = [pth filesep 'external' filesep 'snakeyaml-1.9.jar'];
        if not(ismember(dp, javaclasspath ('-dynamic')))
        	javaaddpath(dp); % javaaddpath clears global variables...!?
        end
        import('org.yaml.snakeyaml.*');
    end;
    javastruct = scan(data);
    dumperopts = DumperOptions();
    dumperopts.setLineBreak(...
        javaMethod('getPlatformLineBreak',...
        'org.yaml.snakeyaml.DumperOptions$LineBreak'));
    if flowstyle
        classes = dumperopts.getClass.getClasses;
        flds = classes(3).getDeclaredFields();
        fsfld = flds(1);
        if ~strcmp(char(fsfld.getName), 'FLOW')
            error(['Accessed another field instead of FLOW. Please correct',...
            'class/field indices (this error maybe caused by new snakeyaml version).']);
        end;
        dumperopts.setDefaultFlowStyle(fsfld.get([]));
    end;
    yaml = Yaml(dumperopts);
    
    output = yaml.dump(javastruct);
    if ~isempty(filename)
        fid = fopen(filename,'w');
        fprintf(fid,'%s',char(output) );
        fclose(fid);
    else
        result = output;
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan(r)
    if ischar(r)
        result = scan_char(r);
    elseif isstring(r)
        result = scan_string(r);
    elseif iscell(r)
        result = scan_cell(r);
    elseif iscategorical(r)
        result = scan_categorical(r);           % <-- NEW
    elseif istable(r)
        % flatten tables to scalar struct, then recurse
        result = scan(table2struct(r, 'ToScalar', true));  % <-- NEW
    elseif isord(r)
        result = scan_ord(r);
    elseif isstruct(r)
        result = scan_struct(r);
    elseif isnumeric(r)
        result = scan_numeric(r);
    elseif islogical(r)
        result = scan_logical(r);
    elseif isdatetime(r) || isa(r,'DateTime')
        result = scan_datetime(r);              % support modern datetime
    elseif isduration(r) || iscalendarduration(r)
        result = scan_duration(r);              % <-- NEW
    else
        error(['Cannot handle type: ' class(r)]);
    end
end

%--------------------------------------------------------------------------
%
%
function result = scan_numeric(r)
    if isempty(r)
        result = java.util.ArrayList();
    else
        result = java.lang.Double(r);
    end
end

%--------------------------------------------------------------------------
%
%

function result = scan_logical(r)
    if isempty(r)
        result = java.util.ArrayList();
    else
        result = java.lang.Boolean(r);
    end
end

%--------------------------------------------------------------------------
%
%
function result = scan_string(r)
    if(isrowvector(r))  
        result = scan_string_row(r);
    elseif(iscolumnvector(r))
        result = scan_string_column(r);
    elseif(ismymatrix(r))
        result = scan_string_matrix(r);
    elseif(issingle(r));
        result = scan_string_single(r);
    elseif(isempty(r))
        result = java.util.ArrayList();
    else
        error('Unknown string content.');
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_char(r)
    if isempty(r)
        result = java.util.ArrayList();
    else
        result = java.lang.String(r);
    end
end

%--------------------------------------------------------------------------
%
%
function result = scan_datetime(r)
    % datestr 30..in ISO8601 format
    %java.text.SimpleDateFormat('yyyymmdd'T'HH:mm:ssz" );
    
    [Y, M, D, H, MN,S] = datevec(double(r));            
	result = java.util.GregorianCalendar(Y, M-1, D, H, MN,S);
	result.setTimeZone(java.util.TimeZone.getTimeZone('UTC'));
    
    %tz = java.util.TimeZone.getTimeZone('UTC');
    %cal = java.util.GregorianCalendar(tz);
    %cal.set
    %result = java.util.Date(datestr(r));
end

%--------------------------------------------------------------------------
%
%
function result = scan_cell(r)
    if(isrowvector(r))  
        result = scan_cell_row(r);
    elseif(iscolumnvector(r))
        result = scan_cell_column(r);
    elseif(ismymatrix(r))
        result = scan_cell_matrix(r);
    elseif(issingle(r));
        result = scan_cell_single(r);
    elseif(isempty(r))
        result = java.util.ArrayList();
    else
        error('Unknown cell content.');
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_ord(r)
    if(isrowvector(r))
        result = scan_ord_row(r);
    elseif(iscolumnvector(r))
        result = scan_ord_column(r);
    elseif(ismymatrix(r))
        result = scan_ord_matrix(r);
    elseif(issingle(r))
        result = scan_ord_single(r);
    elseif(isempty(r))
        result = java.util.ArrayList();
    else
        error('Unknown ordinary array content.');
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_cell_row(r)
    result = java.util.ArrayList();
    for ii = 1:size(r,2)
        result.add(scan(r{ii}));
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_cell_column(r)
    result = java.util.ArrayList();
    for ii = 1:size(r,1)
        tmp = r{ii};
        if ~iscell(tmp)
            tmp = {tmp};
        end;
        result.add(scan(tmp));
    end;    
end

%--------------------------------------------------------------------------
%
%
function result = scan_cell_matrix(r)
    result = java.util.ArrayList();
    for ii = 1:size(r,1)
        i = r(ii,:);
        result.add(scan_cell_row(i));
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_cell_single(r)
    result = java.util.ArrayList();
    result.add(scan(r{1}));
end

%--------------------------------------------------------------------------
%
%
function result = scan_string_row(r)
    result = java.util.ArrayList();
    for ii = 1:size(r,2)
        result.add(scan(r{ii}));
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_string_column(r)
    result = java.util.ArrayList();
    for ii = 1:size(r,1)
        tmp = r{ii};
        if ~isstring(tmp)
            tmp = {tmp};
        end;
        result.add(scan(tmp));
    end;    
end

%--------------------------------------------------------------------------
%
%
function result = scan_string_matrix(r)
    result = java.util.ArrayList();
    for ii = 1:size(r,1)
        i = r(ii,:);
        result.add(scan_string_row(i));
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_string_single(r)
    result = java.util.ArrayList();
    result.add(scan(r{1}));
end

%--------------------------------------------------------------------------
%
%
function result = scan_ord_row(r)
    result = java.util.ArrayList();
    for i = r
        result.add(scan(i));
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_ord_column(r)
    result = java.util.ArrayList();
    for i = 1:size(r,1)
        result.add(scan_ord_row(r(i)));
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_ord_matrix(r)
    result = java.util.ArrayList();
    for i = r'
        result.add(scan_ord_row(i'));
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_ord_single(r)
    result = java.util.ArrayList();
    for i = r'
        result.add(r);
    end;
end


%--------------------------------------------------------------------------
%
%
function result = scan_struct(r)
    result = java.util.LinkedHashMap();
    for i = fields(r)'
        key = i{1};
        val = r.(key);
        result.put(key,scan(val));
    end;
end
%--------------------------------------------------------------------------
%
%

function result = scan_categorical(r)
    % Convert categorical to strings for YAML
    if isempty(r)
        result = java.util.ArrayList();
        return;
    end
    if isscalar(r)
        if isundefined(r)
            s = '';
        else
            s = char(string(r));
        end
        result = java.lang.String(s);
    else
        result = java.util.ArrayList();
        c = cellstr(r);                         % cell array of char
        for ii = 1:numel(c)
            s = c{ii};
            if strcmp(s,'<undefined>'), s = ''; end
            result.add(java.lang.String(s));
        end
    end
end
%--------------------------------------------------------------------------
%
%
function result = scan_duration(r)
    % Serialize duration/calendarDuration as text (e.g., '00:00:01')
    if isempty(r)
        result = java.util.ArrayList();
        return;
    end
    if isscalar(r)
        result = java.lang.String(char(r));
    else
        result = java.util.ArrayList();
        for ii = 1:numel(r)
            result.add(java.lang.String(char(r(ii))));
        end
    end
end




