%% plot_overview_map_all_series_with_bathy_ABT %%
% Sub-function of ABT.m; plots SSM tracks of all tags colored by
% series.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026

%% Create figure and axes for bathymetry.

figure('Position',[476 334 716 532]);

%% Set projection of map.

LATLIMS = [8 70]; LONLIMS = [-100 40];
m_proj('miller','lon',LONLIMS,'lat',LATLIMS);

%% Plot bathymetry.

[cs,ch] = m_etopo2('contourf',-8000:500:0,'edgecolor','none');
caxis([-10000 0]);

colormap(m_colmap('blue'));

hold on

%% Plot land.

m_coast('patch',[.85 .85 .85]);

hold on

%% Set colormap.

% by series
% Canaries = 0,0.773,1
% Ireland = 0.298,0.902,0
% Norway = 0.122,0.122,1
% Canada = 1,0.666,0
% USA = 1,1,0

cmap.series = [0,0.773,1;  0.298,0.902,0; 0.122,0.122,1; 1,0.666,0; 1,1,0];

%% Get unique deployment years.

ss = unique(META.series);

%% Plot SSM positions.

% by series

% Canada
m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.series,ss{1})))),...
    SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.series,ss{1})))),...
    'ko','MarkerFaceColor',cmap.series(4,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

hold on

% Norway
m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.series,ss{4})))),...
    SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.series,ss{4})))),...
    'ko','MarkerFaceColor',cmap.series(3,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

% United States
m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.series,ss{5})))),...
    SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.series,ss{5})))),...
    'ko','MarkerFaceColor',cmap.series(5,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

% Ireland
m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.series,ss{3})))),...
    SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.series,ss{3})))),...
    'ko','MarkerFaceColor',cmap.series(2,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

% Canaries
m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.series,ss{2})))),...
    SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.series,ss{2})))),...
    'ko','MarkerFaceColor',cmap.series(1,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

m(1) = m_plot(-100,100,'o','MarkerFaceColor',cmap.series(1,:),'MarkerEdgeColor','k','MarkerSize',5,'LineWidth',0.8);
m(2) = m_plot(-100,100,'o','MarkerFaceColor',cmap.series(2,:),'MarkerEdgeColor','k','MarkerSize',5,'LineWidth',0.8);
m(3) = m_plot(-100,100,'o','MarkerFaceColor',cmap.series(3,:),'MarkerEdgeColor','k','MarkerSize',5,'LineWidth',0.8);
m(4) = m_plot(-100,100,'o','MarkerFaceColor',cmap.series(4,:),'MarkerEdgeColor','k','MarkerSize',5,'LineWidth',0.8);
m(5) = m_plot(-100,100,'o','MarkerFaceColor',cmap.series(5,:),'MarkerEdgeColor','k','MarkerSize',5,'LineWidth',0.8);

%% Plot ICCAT meridian.

m_line([-45 -45],[8 70],'linewi',2,'color','k','linestyle','--')

%% Create figure border.

m_grid('linewi',2,'tickdir','in','linest','none','fontsize',14);

%% Add north arrow and scale bar.

m_northarrow(-95,65,4,'type',2,'linewi',2);
m_ruler([.03 .23],.1,2,'fontsize',16,'ticklength',0.01);

%% Bathymetry Bar

h1 = m_contfbar([.645 .945],.315,cs,ch,'endpiece','no','FontSize',14);

xlabel(h1,'Bottom Depth (m)','FontWeight','bold');

%% Set location of figure to match bin_map

set(gca,'Position',[0.1300 0.1100 0.7750 0.8150]);

%% Add Legend

[~,icon] = legend(m,{'Canaries','Ireland','Norway','Canada','USA'},'FontSize',14,'Position',[0.76 0.625 0.13 0.1664]);
icons = findobj(icon, 'type', 'line');
set(icons,'MarkerSize',12);
clear ss
clear icon*

%% Save figure.

cd([fdir '/figures']);
exportgraphics(gcf,'overview_map_all_series_with_bathy_ABT.png','Resolution',300);

%% Clear

clear ax* h* m* *LIMS
clear cs ch
clear h1
clear ans

close gcf