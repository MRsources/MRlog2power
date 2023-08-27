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
KW_raw=KW_raw(1:fix(numel(T)/10));
T=T(1:fix(numel(T)/10));

%% switch to correct datetime format
dT = datetime(T, 'InputFormat', 'yyyyMMddHHmmss');
dt_sel = datetime(t_sel, 'InputFormat', 'yyyyMMddHHmmss');

%% find the time shift, for this data 2.3 min was ok
figure,
dt_sel_shifted=dt_sel-minutes(2.3);

plot(dT,KW_raw); hold on;
stem(dt_sel_shifted,datenum(dt_sel_shifted)*0+30);  hold on;

%% map ids to reasonable range
ID_sel(ID_sel==1) = 7.9 ;   % not online
ID_sel(ID_sel==35) = 8 ;   % wait for booting
ID_sel(ID_sel==56) = 8.1 ;   % user off
ID_sel(ID_sel==34) = 14.13 ;   % boot
ID_sel(ID_sel==100) = 15.24 ;   % start prep
ID_sel(ID_sel==103) = 50 ;   % start meas
ID_sel(ID_sel==104) = 15.24 ;   % stop meas

%% plot shifted dt_sel vs. ID together with mapped IDs and avergae energy based on cumsum of fine energy
figure,
plot(dT,KW_raw); hold on;

stairs(dt_sel_shifted,ID_sel,'Marker','.'); hold on;

datenum_dt=datenum(dt_sel_shifted);
dcm = datacursormode(gcf);   % get the data cursor mode of the current figure
set(dcm, 'UpdateFcn', @(src, event_obj) sprintf('ID: %d \n %s', event_obj.Position(2), datestr(datetime(event_obj.Position(1), 'ConvertFrom', 'datenum'), 'yyyy-mm-dd HH:MM:SS') ));

KWH_raw=cumsum(KW_raw);

% plot(dT,KWH_raw)

[loc, locb] = ismember(dt_sel_shifted,dT,'rows');
locb(locb==0)=[];
stairs(dT(locb),[diff(KWH_raw(locb))./diff(datenum(locb)) ;0],'c')



%%
input_datetime=datetime('2015-01-02 07:32:40');

lookup_E=[diff(KWH_raw(locb))./diff(datenum(locb)) ;0];
lookup_T=dT(locb);
diffs = abs(lookup_T - input_datetime);
[~, idx] = min(diffs); % Find the index of the minimum difference
energy = lookup_E(idx)  % Retrieve the energy from lookup_E using the index

%%
mean_energy=[diff(KWH_raw(locb))./diff(datenum(locb)) ;0];

figure, plot(ID_sel,mean_energy);









