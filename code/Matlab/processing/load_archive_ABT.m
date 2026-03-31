%% load_archive_NT
% Sub-function of ABT.m; loads data from recovered tags.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026
%% Load data.

filename = split(META.dc{k},'/');
PSAT = readtable([fdir '/data/tag/dc/' filename{end}]);
PSAT = PSAT(:,[3:6 8:13]);

PSAT.Properties.VariableNames = {'Depth' 'LightLevel' 'InternalTemperature' ...
    'ExternalTemperature' 'Year' 'Month' 'Day' 'Hour' 'Min' 'Sec'};

PSAT.DateTime = datetime(PSAT.Year,PSAT.Month,PSAT.Day,...
    PSAT.Hour,PSAT.Min,PSAT.Sec);
PSAT(:,5:10) = [];
PSAT = movevars(PSAT, 'DateTime', 'Before', 'Depth');

tmp = split(filename{end},'_');
PSAT.TOPPID = str2double(tmp{1})*ones(size(PSAT,1),1);
PSAT = movevars(PSAT, 'TOPPID', 'Before', 'DateTime');

clear filename
clear tmp

%% Time Zone Correction

if META.timezone_correction(META.toppID == PSAT.TOPPID(1)) >= 0
    tz = ['+0' num2str(META.timezone_correction(META.toppID == PSAT.TOPPID(1))) ':00'];
else
    tz = ['-0' num2str(abs(META.timezone_correction(META.toppID == PSAT.TOPPID(1)))) ':00'];
end
PSAT.DateTime.TimeZone = tz;
clear tz

PSAT.DateTime.TimeZone = 'UTC';

PSAT.Date = datetime(year(PSAT.DateTime),month(PSAT.DateTime),day(PSAT.DateTime),'TimeZone','UTC');
PSAT = movevars(PSAT, 'Date', 'Before', 'Depth');

%% Remove data before deployment date.

PSAT(PSAT.Date < META.taggingdate(META.toppID == PSAT.TOPPID(1)),:) = [];

%% Remove data after first date of "last".

date_rm = min([META.popdate(META.toppID == PSAT.TOPPID(1)),...
    META.recdate(META.toppID == PSAT.TOPPID(1)), ...
    META.date_last_depth(META.toppID == PSAT.TOPPID(1)), ...
    META.date_last_light(META.toppID == PSAT.TOPPID(1)), ...
    META.date_last_etemp(META.toppID == PSAT.TOPPID(1)), ...
    META.date_last_lon(META.toppID == PSAT.TOPPID(1))]);

PSAT(PSAT.Date >= date_rm,:) = [];

clear date_rm

%% Interpolate SSM positions to match PSAT data.

PSAT.Longitude = interp1(datenum(SSM.Date(SSM.TOPPID == PSAT.TOPPID(1))),...
    SSM.lon(SSM.TOPPID == PSAT.TOPPID(1)),datenum(PSAT.DateTime));

PSAT.Latitude = interp1(datenum(SSM.Date(SSM.TOPPID == PSAT.TOPPID(1))),...
    SSM.lat(SSM.TOPPID == PSAT.TOPPID(1)),datenum(PSAT.DateTime));

%% Find sunrise and sunset time to determine if observation is day or night.

[SRISE,SSET] = sunrise(PSAT.Latitude,PSAT.Longitude,0,0,PSAT.DateTime);
PSAT.DayNight = zeros(height(PSAT),1);
PSAT.DayNight(PSAT.DateTime > datetime(SRISE,'ConvertFrom','datenum','TimeZone','UTC') & PSAT.DateTime < datetime(SSET,'ConvertFrom','datenum','TimeZone','UTC')) = 1;

clear SRISE
clear SSET

clear TOPPID

%% Remove duplicate observations

[~, ind] = unique(PSAT.DateTime,'last');
PSAT = PSAT(ind,:);

clear ind