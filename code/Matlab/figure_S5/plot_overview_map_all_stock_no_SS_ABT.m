%% plot_overview_map_all_stock_no_SS_ABT %%
% Sub-function of ABT.m; plots SSM tracks of all tags colored by
% stock.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026
%% Create figure and axes for bathymetry.

figure('Position',[476 334 716 532]);

%% Set projection of map.

LATLIMS = [8 70]; LONLIMS = [-100 40];
m_proj('miller','lon',LONLIMS,'lat',LATLIMS);

%% Plot land.

m_coast('patch',[.85 .85 .85]);

hold on

%% Set colormap.

% by stock
% GOM = 1,0,0
% Med = 0.122,0.122,1
% SS = 0.298,0.902,0

cmap.stock = [1,0,0;  0.122,0.122,1; 0.298,0.902,0];

%% Get unique deployment years.

ss = unique(META.stock);

%% Plot SSM positions.

% by stock

% GOM
m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{1})))),...
    SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{1})))),...
    'ko','MarkerFaceColor',cmap.stock(1,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

hold on

% Med
m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{2})))),...
    SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{2})))),...
    'ko','MarkerFaceColor',cmap.stock(2,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

m(1) = m_plot(-100,100,'o','MarkerFaceColor',cmap.stock(1,:),'MarkerEdgeColor','k','MarkerSize',5,'LineWidth',0.8);
m(2) = m_plot(-100,100,'o','MarkerFaceColor',cmap.stock(2,:),'MarkerEdgeColor','k','MarkerSize',5,'LineWidth',0.8);

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

%% Set location of figure to match bin_map

set(gca,'Position',[0.1300 0.1100 0.7750 0.8150]);

%% Add Legend

[~,icon] = legend(m,{['Gulf: ' num2str(roundn(mean(META.length(strcmp(META.stock,ss{1}))),0)) ...
    ' CFL (n = ' num2str(sum(strcmp(META.stock,ss{1}))) ')'],...
    ['Med: ' num2str(roundn(mean(META.length(strcmp(META.stock,ss{2}))),0)) ...
    ' CFL (n = ' num2str(sum(strcmp(META.stock,ss{2}))) ')']},'FontSize',14,...
    'Position',[0.7 0.245 0.13 0.157]);icons = findobj(icon, 'type', 'line');
set(icons,'MarkerSize',12);
clear ss
clear icon*

%% Save figure.

cd([fdir '/figures']);
exportgraphics(gcf,'overview_map_all_stock_no_SS_ABT.png','Resolution',300);

%% Clear

clear ax* h* m* *LIMS
clear cs ch
clear h1
clear ans

close gcf