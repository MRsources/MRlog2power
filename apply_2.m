totalT=tic;
%% Import protocol_sequence_energy_1 data from text file
% filename: protocol_sequence_energy_1.txt
    % Specify range and delimiter
    opts.DataLines = [1, Inf];
    opts.Delimiter = ",";
    opts = delimitedTextImportOptions("NumVariables", 6);
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
ID_sel(ID_sel==100) = 14 ;   % start prep
ID_sel(ID_sel==103) = 50 ;   % start meas
ID_sel(ID_sel==104) = 15 ;   % stop meas
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
KW_raw=KW_raw(1:fix(numel(T)/10));   % needs roughly 1/10 for good training
T=T(1:fix(numel(T)/10));
% switch to correct datetime format
dT = datetime(T, 'InputFormat', 'yyyyMMddHHmmss');

KWH_raw=cumsum(KW_raw);

[loc, locb] = ismember(dt_sel_shifted,dT,'rows');
locb(locb==0)=[];

lookup_E=[diff(KWH_raw(locb))./diff(datenum(locb)) ;KW_raw(locb(end))];
KW_raw_sel=KW_raw(locb);
lookup_E(isnan(lookup_E))=KW_raw_sel(isnan(lookup_E));  % if we devide by zero we get a Nan, the delta t is below a second and the KW_raw_sel is a good estimator for the average.

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

% shorten dt to dT:
dt_sel_shifted(dt_sel_shifted>max(dT))=[];  

LOGEVENT=LOGEVENT(:,1:numel(dt_sel_shifted));
ENERGY=ENERGY(:,1:numel(dt_sel_shifted));

%% train
ENERGY(LOGEVENT(1,:)==15) =15.3;   % tweak: when ID is stop seq (15), set the energy to 15.3, the ON-IDLE basline value.
train_idx=numel(ENERGY)-fix(numel(ENERGY)/10);
ENERGY_train=ENERGY(:,1:train_idx);
LOGEVENT_train=LOGEVENT(:,1:train_idx);
NN_training_script()

%% load only test
if 0
    
    
end

%% test

E = net(LOGEVENT);
figure, plot(ENERGY,E,'x'); hold on;
plot(1:100,1:100,'k');

figure, 
ax1=subplot(2,1,1),
plot(dT,KW_raw,'r', 'Displayname','measured Power [kW]'); hold on;
stairs(dt_sel_shifted,ENERGY,'c', 'Displayname','avg. Power per Event [kW]' ); hold on;
stairs(dt_sel_shifted,E,'b', 'Displayname','predicted avg. Power [kW]'); hold on;

dcm = datacursormode(gcf);   % get the data cursor mode of the current figure
set(dcm, 'UpdateFcn', @(src, event_obj) sprintf('%d , %s\navE:%.2f\n%s',src.Cursor.DataIndex,dt_sel_shifted(src.Cursor.DataIndex), event_obj.Position(2),strcat(log_sel(src.Cursor.DataIndex),seq_sel(src.Cursor.DataIndex)) ));
stem(dt_sel_shifted(train_idx),60,'Color','magenta', 'Displayname','start of unseen test data'); hold on;
legend show; ylabel('power in kW'); grid on; ylim([0 80])

ax2=subplot(4,1,3),
plot(dt_sel_shifted(2:end),cumsum(ENERGY(1:end-1)'.*hours([diff(dt_sel_shifted)])),'c.-','Markersize',10, 'Displayname','avg. Energy per Event [kWh]' ); hold on;
plot(dt_sel_shifted(2:end),cumsum(E(1:end-1)'.*hours([diff(dt_sel_shifted)])),'b.--', 'Displayname','predicted Energy [kWh]'); hold on;
legend show;  legend('Location','northwest'); ylabel('energy in kWh'); grid on;
ax3=subplot(4,1,4),
plot(dt_sel_shifted(2:end),0.4 * cumsum(E(1:end-1)'.*hours([diff(dt_sel_shifted)])),'b.-', 'Displayname','predicted cost [€] assuming (0.4 €/kWh)'); hold on;
legend show; legend('Location','northwest'); ylabel('cost in €'); grid on;
linkaxes([ax1, ax2,ax3], 'x');

totalTimeElapsed=toc(totalT)
toc(totalT)

