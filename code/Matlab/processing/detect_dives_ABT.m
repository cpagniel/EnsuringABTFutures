%% detect_dives_ABT.m
% Sub-function of ABT; detects dives based on return excursions
% through a threshold.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026
%% Calculate sampling rate.

disp('Calculate sampling rate...')

META.sample_rate(META.toppID == PSAT.TOPPID(1)) = seconds(PSAT.DateTime(10)-PSAT.DateTime(9)); % because sometimes the first few samples are not evenly spaces

%% Apply median filter with a 75 second window to smooth data.

disp('Smooth data...')

PSAT.DepthSmooth = smoothdata(PSAT.Depth,'movmedian',75/META.sample_rate(META.toppID == PSAT.TOPPID(1)));

%% Calculate depth threshold every 18 hours in the top 10 m.

disp('Compute depth threshold...')

s_dt = datetime(year(PSAT.DateTime(1)),month(PSAT.DateTime(1)),day(PSAT.DateTime(1)),hour(PSAT.DateTime(1)),0,0,'TimeZone','UTC');
e_dt = datetime(year(PSAT.DateTime(end)),month(PSAT.DateTime(end)),day(PSAT.DateTime(end)),hour(PSAT.DateTime(end))+1,0,0,'TimeZone','UTC');
dt = s_dt:hours(18):e_dt;
if max(dt) < e_dt
    dt = [dt, dt(end) + hours(18)];
    dt = [dt, dt(end) + hours(18)];
end

tmp = [];
for j = 1:length(dt)-1
    tmp  = [tmp; median(roundn(PSAT.DepthSmooth(PSAT.DepthSmooth <= 10 & PSAT.DateTime > dt(j) & PSAT.DateTime <= dt(j+1)),0))*ones(sum(PSAT.DateTime > dt(j) & PSAT.DateTime <= dt(j+1)),1)]; % m
end
tmp = fillmissing(tmp,'previous');
if length(tmp) ~= length(PSAT.DepthSmooth)
    tmp = [tmp; tmp(end)*ones(1,length(PSAT.DepthSmooth)-length(tmp))];
end
B.T{i} = tmp;
clear j

clear *dt
clear tmp

%% Generate indices of start and end of dives.
% Compute max, min, mean and median depth (m). Compute dive duration
% (hours) and inter-dive-interval (hours). Compute maximum descent and
% ascent rate (m/s).

disp('Find start and end of times...')

ind = PSAT.DepthSmooth >= B.T{i}; % is the depth above or below the threshold?
ind = ischange(double(ind)); % determine where there is a change from 0 to 1 and 1 to 0
ind = find(ind);

tbl = table([[1; ind-1], [ind; length(PSAT.DepthSmooth)]],'VariableNames',{'index'}); % start and end index of each potential dive
clear ind

for j = 1:length(tbl.index)
    tmp.dive_depth(j,:) = [max(PSAT.DepthSmooth(tbl.index(j,1):tbl.index(j,2))); min(PSAT.DepthSmooth(tbl.index(j,1):tbl.index(j,2)))];
    tmp.depthrange = tmp.dive_depth(:,1) - tmp.dive_depth(:,2);
end
clear j

ind = tmp.depthrange >= 10; % must span at least 10 m
tbl = tbl(ind,:);
clear ind

tbl.start_time = PSAT.DateTime(tbl.index(:,1));
tbl.end_time = PSAT.DateTime(tbl.index(:,2));
tbl.duration = hours(tbl.end_time - tbl.start_time);
tbl.IDI = [hours(tbl.start_time(2:end) - tbl.end_time(1:end-1)); NaN];

tbl.month = month(tbl.start_time);
tbl.day = datetime(year(tbl.start_time),month(tbl.start_time),day(tbl.start_time),'TimeZone','UTC');
tbl.hour = hour(tbl.start_time);

tbl.start_depth = PSAT.Depth(tbl.index(:,1));
tbl.end_depth = PSAT.Depth(tbl.index(:,2));

for j = 1:length(tbl.index)
    [tbl.max_depth(j), ind] = max(PSAT.Depth(tbl.index(j,1):tbl.index(j,2)));
    tbl.min_depth(j) = min(PSAT.Depth(tbl.index(j,1):tbl.index(j,2)));
    tbl.range_depth(j) = tbl.max_depth(j) - tbl.min_depth(j);

    tbl.mean_depth(j) = mean(PSAT.Depth(tbl.index(j,1):tbl.index(j,2)));
    tbl.std_depth(j) = std(PSAT.Depth(tbl.index(j,1):tbl.index(j,2)));
    tbl.median_depth(j) = median(PSAT.Depth(tbl.index(j,1):tbl.index(j,2)));
    tbl.mad_depth(j) = mad(PSAT.Depth(tbl.index(j,1):tbl.index(j,2)),1);

    sub.time = PSAT.DateTime(tbl.index(j,1):tbl.index(j,2));
    sub.depth = PSAT.Depth(tbl.index(j,1):tbl.index(j,2));

%     [~,ind] = max(sub.depth);
%     tbl.max_descent(j) = (max(sub.depth)-sub.depth(1))./seconds(sub.time(ind)-sub.time(1));
%     tbl.max_ascent(j) = abs(max(sub.depth)-sub.depth(end))./abs(seconds(sub.time(ind)-sub.time(end)));

    if ind ~= 1 && ind ~= length(sub.time) && ind ~= length(sub.time)-1  % as long as maximum depth is not the first point in the dive, second to last or last point in the timeseries
        tbl.max_descent(j) = max((diff(sub.depth(1:ind)))./(seconds(diff(sub.time(1:ind)))));
        t = abs((diff(sub.depth(ind:end)))./(seconds(diff(sub.time(ind:end)))));
        tbl.max_ascent(j) = max(t(t > 0));
    else
        tbl.max_descent(j) = NaN;
        tbl.max_ascent(j) = NaN;
    end

    clear sub
    clear t
end
clear j
clear ind
clear tmp

tbl.toppID = toppID(i)*ones(height(tbl),1);
tbl = movevars(tbl,'toppID','Before','index');

tbl.lat = NaN(height(tbl),1);
tbl.lon = NaN(height(tbl),1);

tbl.lon = interp1(datenum(SSM.Date(SSM.TOPPID == toppID(i))),...
    SSM.lon(SSM.TOPPID == toppID(i)),datenum(tbl.start_time));

tbl.lat = interp1(datenum(SSM.Date(SSM.TOPPID ==  toppID(i))),...
    SSM.lat(SSM.TOPPID ==  toppID(i)),datenum(tbl.start_time));

%% Find sunrise and sunset time to determine if observation is day or night.

[SRISE,SSET] = sunrise(tbl.lat,tbl.lon,0,0,tbl.start_time);
tbl.DayNight = zeros(height(tbl),1);
tbl.DayNight(tbl.start_time > datetime(SRISE,'ConvertFrom','datenum','TimeZone','UTC') & tbl.start_time < datetime(SSET,'ConvertFrom','datenum','TimeZone','UTC')) = 1;

clear SRISE
clear SSET

%% Add to dives to master.

if ~exist('dives','var')
    dives = tbl;
else
    dives = [dives; tbl];
end

clear tbl