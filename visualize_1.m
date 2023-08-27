

%%
KW_raw=KW_raw(1:fix(numel(T)/50));
T=T(1:fix(numel(T)/50));

%%
dt = datetime(t, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
dT = datetime(T, 'InputFormat', 'yyyyMMddHHmmss');
dt_sel = datetime(t_sel, 'InputFormat', 'yyyyMMddHHmmss');

%%
figure,
stairs(dt,KW);  hold on;
stairs(dt_sel,KW_sel)


%%
figure,
plot(dT,KW_raw); hold on;
stem(dt_sel-minutes(2.5),KW_sel*0+30);  hold on;

%% plot shifted dt_sel vs. ID
% map ids to reasonable range
ID_sel(ID_sel==1) = 7.9 ;   % not online
ID_sel(ID_sel==35) = 8 ;   % wait for booting
ID_sel(ID_sel==56) = 8.1 ;   % user off
ID_sel(ID_sel==34) = 14.13 ;   % boot
ID_sel(ID_sel==100) = 15.24 ;   % start prep
ID_sel(ID_sel==103) = 50 ;   % start meas
ID_sel(ID_sel==104) = 15.24 ;   % stop meas

diff_ID_sel=(abs([0;diff(ID_sel)])>0);


%%
figure,
plot(dT,KW_raw); hold on;

dt_sel_shifted=dt_sel-minutes(2.3);

stairs(dt_sel_shifted,ID_sel,'Marker','.'); hold on;
plot(dt_sel_shifted,diff_ID_sel,'Marker','x'); hold on;


datenum_dt=datenum(dt_sel_shifted);
dcm = datacursormode(gcf);   % get the data cursor mode of the current figure
set(dcm, 'UpdateFcn', @(src, event_obj) sprintf('ID: %d \n %s', event_obj.Position(2), datestr(datetime(event_obj.Position(1), 'ConvertFrom', 'datenum'), 'yyyy-mm-dd HH:MM:SS') ));

KWH_raw=cumsum(KW_raw);

plot(dT,KWH_raw)

[loc, locb] = ismember(datenum(dt_sel_shifted), datenum(dT),'rows');
locb(locb==0)=[];
stairs(dT(locb),[diff(KWH_raw(locb))./diff(datenum(locb)) ;0],'c')

%% integrate
dTN=datenum(dT);
[dTN_u,IA] = unique(dTN);
KW_raw_u=KW_raw(IA);

plot(dTN,trapz(dTN_u,KW_raw_u))


%%
dTN=datenum(dT);
dt_selN=datenum(dt_sel);

[dTN_u,IA] = unique(dTN);
KW_raw_u=KW_raw(IA);

[dt_sel_u,IA] = unique(dt_sel);
KW_raw_u=KW_raw(IA);

figure, plot(dTN_u,trapz(dTN_u,KW_raw_u),dt_sel,trapz(dt_sel,KW_sel))