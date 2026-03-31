%% plot_bin_map_ABT.m
% Sub-function of ABT.m; plots SSM tracks of binned by days in 
% 1 x 1 degree bins.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026

%% Create figure and axes for bathymetry. 

figure('Position',[476 334 716 532]);

%% Set projection of map.

LATLIMS = [8 70]; LONLIMS = [-100 40];
m_proj('miller','lon',LONLIMS,'lat',LATLIMS);

%% Bin SSM Positions

binned.LONedges = -100:1:40;
binned.LATedges = 8:1:70;

[binned.N,~,~,binned.indLON,binned.indLAT] = histcounts2(SSM.lon,SSM.lat,binned.LONedges,binned.LATedges); % number of daily geolocations
SSM.Index = sub2ind(size(binned.N),binned.indLON+1,binned.indLAT+1);

tmp = groupcounts(groupcounts(SSM,["Index" "TOPPID" ]),"Index");
binned.n = zeros(size(binned.N)); % number of unique toppids per bin
binned.n(tmp.Index) = tmp.GroupCount;
clear tmp

binned.Nn = (1-(binned.n./length(unique(SSM.TOPPID)))).*binned.N; % number of daily geolocations x 1 - number of tags in bin/total number of tags

binned.LONmid = diff(binned.LONedges)/2 + -100:1:40;
binned.LATmid = diff(binned.LATedges)/2 + 8:1:70;

m_pcolor(binned.LONmid-0.5,binned.LATmid-0.5,binned.Nn.');

hold on

%% Plot land.

m_coast('patch',[.85 .85 .85]);

hold on

%% Plot ICCAT boxes.

for i = 1:length(iccat)
    m_line(iccat(i).X,iccat(i).Y,'linewi',2,'color','k','linestyle','-')
end
clear i

%% Create figure border.

m_grid('linewi',2,'tickdir','in','linest','none','fontsize',14);

%% Add north arrow and scale bar.

m_northarrow(-95,65,4,'type',2,'linewi',2);
m_ruler([.03 .23],.1,2,'fontsize',16,'ticklength',0.01);

%% Add colorbar

p = get(gca,'Position');

h = colorbar('FontSize',16); 
cmap.bin = flipud(hot(95));
cmap.bin = [1,1,1; cmap.bin(6:end,:)];
colormap(cmap.bin);
ylab = ylabel(h,'Standardized Total Daily Positions','FontSize',16);
caxis([0 90]);

set(gca,'Position',p);
ylab.Position(1) = ylab.Position(1) - 0.13;

clear ylab
clear p

%% Save

cd([fdir '/figures']);
exportgraphics(gcf,'bin_map_ABT_update.png','Resolution',300)

%% Clear

clear h* binned *LIMS
clear ans

close gcf