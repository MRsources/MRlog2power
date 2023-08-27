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

%% Import mr3-energy-2015-conv   data from text file
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
KW_raw=KW_raw(1:fix(numel(T)/30));
T=T(1:fix(numel(T)/30));

%% switch to correct datetime format
dT = datetime(T, 'InputFormat', 'yyyyMMddHHmmss');
dt_sel = datetime(t_sel, 'InputFormat', 'yyyyMMddHHmmss');

%% find the time shift, for this data 2.3 min was ok
figure,
dt_sel_shifted=dt_sel-minutes(2.3);

plot(dT,KW_raw); hold on;
stem(dt_sel_shifted,datenum(dt_sel_shifted)*0+30);  hold on;

%% map ids to reasonable range
ID_sel(ID_sel==1) = 7 ;   % not online
ID_sel(ID_sel==35) = 8 ;   % wait for booting
ID_sel(ID_sel==56) = 9 ;   % user off
ID_sel(ID_sel==34) = 14.13 ;   % boot
ID_sel(ID_sel==100) = 15.24 ;   % start prep
ID_sel(ID_sel==103) = 50 ;   % start meas
ID_sel(ID_sel==104) = 25 ;   % stop meas

% better first shorten dt to dT:
dt_sel_shifted(dt_sel_shifted>max(dT))=[];  
ID_sel=ID_sel(1:numel(dt_sel_shifted));
seq_sel=seq_sel(1:numel(dt_sel_shifted));
log_sel=log_sel(1:numel(dt_sel_shifted));

%% plot shifted dt_sel vs. ID together with mapped IDs and avergae energy based on cumsum of fine energy
figure,
plot(dT,KW_raw,'DisplayName','measured Power [kW]'); hold on;
set(0, 'defaulttextInterpreter', 'none')
stairs(dt_sel_shifted,ID_sel,'Marker','.','DisplayName','ID change'); hold on;

datenum_dt=datenum(dt_sel_shifted);
dcm = datacursormode(gcf);   % get the data cursor mode of the current figure
set(dcm, 'UpdateFcn', @(src, event_obj) sprintf('%d , %s\navE:%.2f\n%s',src.Cursor.DataIndex,dt_sel_shifted(src.Cursor.DataIndex), event_obj.Position(2),strcat(log_sel(src.Cursor.DataIndex),seq_sel(src.Cursor.DataIndex)) ));

KWH_raw=cumsum(KW_raw);

% plot(dT,KWH_raw)

[loc, locb] = ismember(dt_sel_shifted,dT,'rows'); % this provides locations of all timepoints  dt  in the fine and unique list dT 
locb(locb==0)=[];  % as output 0 is given to non found values, we remove these form the index location list.

mean_energy=[diff(KWH_raw(locb))./diff(locb) ; KW_raw(locb(end))];    % this calculates the mean energy per event using locb as index in seconds, this can be 0 as loc b can have duplicates
KW_raw_sel=KW_raw(locb);
mean_energy(isnan(mean_energy))=KW_raw_sel(isnan(mean_energy));  % if we devide by zero we get a Nan, the delta t is below a second and the KW_raw is a good estimator for the average.

stairs(dT(locb),mean_energy,'c','DisplayName','averaged Power over event [kW]'); hold on;
legend show;

%% chec idx
idx=407
{dt_sel_shifted(idx),
ID_sel(idx),
seq_sel(idx),
log_sel(idx),
KW_raw_sel(idx),
mean_energy(idx)}

%%
input_datetime=datetime('2015-01-02 07:32:40');

lookup_E=[diff(KWH_raw(locb))./diff(datenum(locb)) ;0];
lookup_T=dT(locb);
diffs = abs(lookup_T - input_datetime);
[~, idx] = min(diffs); % Find the index of the minimum difference
energy = lookup_E(idx)  % Retrieve the energy from lookup_E using the index


%%

figure, plot(ID_sel,mean_energy,'.');


% Extract sequence types
SeqTypes = regexp(seq_sel, 'Sequence: (\w+)', 'tokens');
SeqTypes = [SeqTypes{:}]';  % Convert from cell array to string array
[uniqueSeqTypes, ~, seqIDs] = unique(SeqTypes);   % Find unique sequence types and encode them with an ID

%Extract sequence types
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


figure(), plot3(ID_sel,seqIDs,mean_energy,'.');
set(gca, 'TickLabelInterpreter', 'none')
yticks(1:numel(seqIDs));
yticklabels(uniqueSeq);

xticks(unique(ID_sel));
xticklabels({'not online','wait for booting','user off', 'boot','prep','stop seq','start seq'});





