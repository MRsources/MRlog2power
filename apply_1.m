%% Import protocol_sequence_energy_1 data from text file
% filename: protocol_sequence_energy_1.txt
    opts = delimitedTextImportOptions("NumVariables", 6);
    % Specify range and delimiter
    opts.DataLines = [1, Inf];
    opts.Delimiter = ",";
    % Specify column names and types
    opts.VariableNames = ["t_sel", "ID_sel", "Var3", "Var4", "log_sel", "seq_sel"];
    opts.SelectedVariableNames = ["t_sel", "ID_sel", "log_sel", "seq_sel"];
    opts.VariableTypes = ["string", "double", "string", "string", "string", "string"];
    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";

    % Specify variable properties
    opts = setvaropts(opts, ["t_sel", "Var3", "Var4", "log_sel", "seq_sel"], "WhitespaceRule", "preserve");
    opts = setvaropts(opts, ["t_sel", "Var3", "Var4", "log_sel", "seq_sel"], "EmptyFieldRule", "auto");
    opts = setvaropts(opts, "ID_sel", "DecimalSeparator", ",");
    opts = setvaropts(opts, "ID_sel", "ThousandsSeparator", ".");
    % Import the data
    tbl = readtable("protocol_sequence_energy_1.txt", opts);
    % Convert to output type
    t_sel = tbl.t_sel;
    ID_sel = tbl.ID_sel;
    log_sel = tbl.log_sel;
    seq_sel = tbl.seq_sel;
    % Clear temporary variables
    clear opts tbl

%% map ids to reasonable range
ID_sel(ID_sel==1) = 7.9 ;   % not online
ID_sel(ID_sel==35) = 8 ;   % wait for booting
ID_sel(ID_sel==56) = 8.1 ;   % user off
ID_sel(ID_sel==34) = 14.13 ;   % boot
ID_sel(ID_sel==100) = 15.24 ;   % start prep
ID_sel(ID_sel==103) = 50 ;   % start meas
ID_sel(ID_sel==104) = 15.24 ;   % stop meas
%%
% Filter out <missing> values
wantedIndices = find(~contains(log_sel, 'prepare'));
ID_sel=ID_sel(wantedIndices);
log_sel = log_sel(wantedIndices);
seq_sel=seq_sel(wantedIndices);
t_sel=t_sel(wantedIndices);
dt_sel = datetime(t_sel, 'InputFormat', 'yyyyMMddHHmmss');
dt_sel_shifted=dt_sel-minutes(2.3);

% Extract sequence types
SeqTypes = regexp(seq_sel, 'Sequence: (\w+)', 'tokens');
SeqTypes = [SeqTypes{:}]';  % Convert from cell array to string array
[uniqueSeqTypes, ~, seqIDs] = unique(SeqTypes);   % Find unique sequence types and encode them with an ID


%% Extract sequence types
% Extract sequence type or assign "none"
SeqTypes = cell(size(seq_sel));
for i = 1:length(seq_sel)
    try
        match = regexp(seq_sel{i}, ' Sequence: (\w+)', 'tokens');
    catch
        match=[];
    end
    if ~isempty(match)
        SeqTypes{i} = match{1}{1};
    else
        SeqTypes{i} = 'none';
    end
end

% Find unique sequence types and encode them with an ID
[uniqueSeq, ~, seqIDs] = unique(SeqTypes);

%%
% what do we have now:
%input (ID, seqID, protID, duration) ->   mean energy

%input (ID, seqID, duration) ->   mean energy
clear LOGEVENT;
LOGEVENT(:,1) = ID_sel;  
LOGEVENT(:,2) = seqIDs';
LOGEVENT(:,3) = [hours(diff(dt_sel));0];

figure, plot(dt_sel_shifted,LOGEVENT);

LOGEVENT=LOGEVENT';

%% load TARGET

% Import mr3-energy-2015-conv   data from text file
% mr3-energy-2015-conv.txt
        opts = delimitedTextImportOptions("NumVariables", 2);
        % Specify range and delimiter
        opts.DataLines = [1, Inf];
        opts.Delimiter = "\t";
        % Specify column names and types
        opts.VariableNames = ["T", "KW_raw"];
        opts.VariableTypes = ["string", "double"];
        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
        % Specify variable properties
        opts = setvaropts(opts, "T", "WhitespaceRule", "preserve");
        opts = setvaropts(opts, "T", "EmptyFieldRule", "auto");
        % Import the data
        tbl = readtable("mr3-energy-2015-conv.txt", opts);
        % Convert to output type
        T = tbl.T;
        KW_raw = tbl.KW_raw;
        % Clear temporary variables
        clear opts tbl


%% reduce data a bit for display
KW_raw=KW_raw(1:fix(numel(T)/5));
T=T(1:fix(numel(T)/5));
% switch to correct datetime format
dT = datetime(T, 'InputFormat', 'yyyyMMddHHmmss');

KWH_raw=cumsum(KW_raw);

[loc, locb] = ismember(dt_sel_shifted,dT,'rows');
locb(locb==0)=[];

lookup_E=[diff(KWH_raw(locb))./diff(datenum(locb)) ;0];
lookup_T=dT(locb);

%% this is our lookup table
input_datetime=datetime('2015-01-10 07:32:40');
diffs = abs(lookup_T - input_datetime);
[~, idx] = min(diffs); % Find the index of the minimum difference
energy = lookup_E(idx)  % Retrieve the energy from lookup_E using the index

%%
tic
for ii=1:numel(dt_sel_shifted)
    input_datetime=dt_sel_shifted(ii);
    diffs = abs(lookup_T - input_datetime);
    [~, idx] = min(diffs); % Find the index of the minimum difference
    ENERGY(ii) = lookup_E(idx);  % Retrieve the energy from lookup_E using the index
end
toc

LOGEVENT=LOGEVENT(:,1:8000);
ENERGY=ENERGY(:,1:8000);


%% test

E = lay4(LOGEVENT);

figure, plot(ENERGY,E,'x'); hold on;
plot(1:100,1:100,'k');


figure, stairs(dt_sel_shifted(1:8000),ENERGY); hold on;
stairs(dt_sel_shifted(1:8000),E); hold on;

plot(dT,KW_raw); hold on;


