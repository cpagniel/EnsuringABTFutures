%% plot_horizontal_speed_map_all_ABT.m
% Sub-function of ABT.m; plots median horizontal speeed in 
% 1 x 1 degree bins.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026

%% Create list of unique toppIDs.

toppID = unique(SSM.TOPPID);

%% Create figure and axes for bathymetry. 

figure('Position',[476 334 716 532]);

%% Set projection of map.

LATLIMS = [8 70]; LONLIMS = [-100 40];
m_proj('miller','lon',LONLIMS,'lat',LATLIMS);

%% Compute median of speed (m/s) in each bin.

binned.LONedges = -100:1:40;
binned.LATedges = 8:1:70;

[binned.mz,binned.LONmid,binned.LATmid] = twodmed(B.speed.lon,B.speed.lat,...
        B.speed.Speed_m_per_s,binned.LONedges,binned.LATedges);
bins.all.speed = binned.mz.';

m_pcolor(binned.LONmid-0.5,binned.LATmid-0.5,binned.mz);

hold on

%% Plot land.

m_coast('patch',[.85 .85 .85]);

hold on

%% Create figure border.

m_grid('linewi',2,'tickdir','in','linest','none','fontsize',14);

%% Add north arrow and scale bar.

m_northarrow(-95,65,4,'type',2,'linewi',2);
m_ruler([.03 .23],.1,2,'fontsize',16,'ticklength',0.01);

%% Plot patch.

m_patch([-10 39.5 39.5 -10 -10],[10 10 26 26 10],'w');
clear p

%% Add colorbar

h = colorbar('FontSize',14,'Location','southoutside'); 
colormap(cmocean('deep',8))
set(h,'Position',[0.6493 0.3341 0.2325 0.0244])
ylabel(h,'Speed (m/s)','FontSize',16,'FontWeight','bold');
caxis([0 2]);
h.Ticks = 0:0.5:2;

%% Set location of figure to match bin_map

set(gca,'Position',[0.1300 0.1100 0.7750 0.8150]);

%% Save

cd([fdir '/figures']);
exportgraphics(gcf,'speed_map_ABT.png','Resolution',300)

%% Clear

clear h* binned *LIMS
clear tmp
clear ans

close gcf