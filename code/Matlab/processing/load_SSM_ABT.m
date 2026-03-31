%% load_SSM_ABT.m
% Sub-function of ABT.m; load SSM tracks.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026
%% Go To Folder

cd([fdir '/data/SSM']);

%% Load All SSM Tracks

% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 27);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["Var1", "tkey", "Var3", "toppid", "Var5", "Var6", "Var7", "Var8", "datetime", "seriesname", "length", "age", "Var13", "Var14", "Var15", "Var16", "lat", "lon", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27"];
opts.SelectedVariableNames = ["tkey", "toppid", "datetime", "seriesname", "length", "age", "lat", "lon"];
opts.VariableTypes = ["char", "double", "char", "double", "char", "char", "char", "char", "datetime", "char", "double", "double", "char", "char", "char", "char", "double", "double", "char", "char", "char", "char", "char", "char", "char", "char", "char"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["Var1", "Var3", "Var5", "Var6", "Var7", "Var8", "seriesname", "Var13", "Var14", "Var15", "Var16", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var1", "Var3", "Var5", "Var6", "Var7", "Var8", "seriesname", "Var13", "Var14", "Var15", "Var16", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "datetime", "InputFormat", "MM/dd/yyyy HH:mm");

% Import the data
SSM = readtable("***.csv", opts);

% Clear temporary variables
clear opts

%% Only Keep SSM from toppID in META List

ind = ismember(SSM.toppid,META.toppID);
SSM = SSM(ind,:);

clear ind

%% Sort By Tkey

[~,ind] = sort(SSM.tkey);
SSM = SSM(ind,:);

SSM = removevars(SSM, 'tkey');

clear ind

%% Rename Series

SSM.series = SSM.seriesname;
SSM = movevars(SSM, 'series', 'Before', 'length');

META.series(contains(META.series,'North Carolina')) = {'United States'};
META.series(contains(META.series,'Hatteras')) = {'United States'};
META.series(contains(META.series,'Canada')) = {'Canada'};
META.series(contains(META.series,'Ireland')) = {'Ireland'};
META.series(contains(META.series,'Norway')) = {'Norway'};
META.series(contains(META.series,'Canaries')) = {'Canaries'};

SSM.series(contains(SSM.series,'North Carolina')) = {'United States'};
SSM.series(contains(SSM.series,'Hatteras')) = {'United States'};
SSM.series(contains(SSM.series,'Canada')) = {'Canada'};
SSM.series(contains(SSM.series,'Ireland')) = {'Ireland'};
SSM.series(contains(SSM.series,'Norway')) = {'Norway'};
SSM.series(contains(SSM.series,'Canaries')) = {'Canaries'};

%% Create Date Variable

SSM.Date = datetime(year(SSM.datetime),month(SSM.datetime),day(SSM.datetime),'TimeZone','UTC');
SSM = movevars(SSM, 'Date', 'Before', 'datetime');
SSM = removevars(SSM, 'datetime');

%% Determine Sunset and Sunrise Time

[SSM.SRISE,SSM.SSET] = sunrise(SSM.lat,SSM.lon,0,0,SSM.Date);
SSM.SRISE = datetime(SSM.SRISE,'ConvertFrom','datenum','TimeZone','UTC'); 
SSM.SSET = datetime(SSM.SSET,'ConvertFrom','datenum','TimeZone','UTC');

%% Determine if within spawning ground

% in spawning ground = 1
% outside spawning ground = 0

SSM.InSpawningGround = zeros(height(SSM),1);

% GOM
cd([fdir '/data/shp/gom'])
tmp = shaperead('iho.shp');
region.GOM = [tmp.X; tmp.Y];
region.GOM = region.GOM(:,850:length(tmp.X));
region.GOM = [[-80.7952, -80, -80, -82.9999; 24.8105, 24.8105, 23.0116, 23.0116], region.GOM];
SSM.InSpawningGround(inpolygon(SSM.lon,SSM.lat,region.GOM(1,:),region.GOM(2,:))) = 1;

% Mediterranean Sea
region.Med = [-5.6061,-5.6061,5,36,36,-5.6061;...
    30,40,46,46,30,30];
SSM.InSpawningGround(inpolygon(SSM.lon,SSM.lat,region.Med(1,:),region.Med(2,:))) = 1;

% Slope Sea
cd([fdir '/data/shp/slope_shape'])
tmp = shaperead('slope_sea2.shp');
region.SS = [tmp.X; tmp.Y];
SSM.InSpawningGround(inpolygon(SSM.lon,SSM.lat,region.SS(1,:),region.SS(2,:))) = 1;

clear tmp

%% Rename variables

SSM.Properties.VariableNames{1} = 'TOPPID';

%% Assign Stock

ss = unique(META.stock);

SSM.Stock(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{1})))) = {'GOM'};
SSM.Stock(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{2})))) = {'MED'};
SSM.Stock(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{3})))) = {'SS'};

%% Count number of stocks.

% Bin SSM Positions
binned.LONedges = -100:1:40;
binned.LATedges = 8:1:70;

[binned.N,~,~,binned.indLON,binned.indLAT] = histcounts2(SSM.lon,SSM.lat,binned.LONedges,binned.LATedges); % number of daily geolocations
SSM.Index = sub2ind(size(binned.N),binned.indLON+1,binned.indLAT+1);

tmp = groupcounts(groupcounts(SSM,["Index","Stock"]),"Index");

% Add number of stocks to SSM
SSM.NumStock = zeros(height(SSM),1);
for i = 1:length(tmp.Index)
    SSM.NumStock(ismember(SSM.Index,tmp.Index(i))) = tmp.GroupCount(i);
end
clear i
clear tmp
