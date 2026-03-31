%% plot_overview_map_by_stock_ABT %%
% Sub-function of ABT.m; plots SSM tracks of all tags colored by
% stock.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026

for i = 1:length(unique(META.stock))

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
    % SS = 0,0.773,1

    cmap.stock = [1,0,0;  0.122,0.122,1; 0,0.773,1];

    %% Get unique stocks.

    ss = unique(META.stock);

    %% Plot SSM positions.

    % by stock

    if i == 1
        % GOM
        m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{1})))),...
            SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{1})))),...
            'ko','MarkerFaceColor',cmap.stock(1,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

    elseif i == 2

        % Med
        m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{2})))),...
            SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{2})))),...
            'ko','MarkerFaceColor',cmap.stock(2,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

    elseif i == 3

        % SS
        m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{3})))),...
            SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{3})))),...
            'ko','MarkerFaceColor',cmap.stock(3,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

    end

    %% Plot ICCAT boxes.

    for j = 1:length(iccat)
        m_line(iccat(j).X,iccat(j).Y,'linewi',2,'color','k','linestyle','-')
    end
    clear j

    %% Create figure border.

    m_grid('linewi',2,'tickdir','in','linest','none','fontsize',14);

    %% Add north arrow and scale bar.

    m_northarrow(-95,65,4,'type',2,'linewi',2);
    m_ruler([.03 .23],.1,2,'fontsize',16,'ticklength',0.01);

    %% Set location of figure to match bin_map

    set(gca,'Position',[0.1300 0.1100 0.7750 0.8150]);

    %% Save figure.

    cd([fdir '/figures']);
    if i == 1
        exportgraphics(gcf,'overview_map_GOM_ABT.png','Resolution',300);
    elseif i == 2
        exportgraphics(gcf,'overview_map_Med_ABT.png','Resolution',300);
    elseif i == 3
        exportgraphics(gcf,'overview_map_SS_ABT.png','Resolution',300);
    end

    %% Clear

    clear ax* h* m* *LIMS
    clear cs ch
    clear h1
    clear ans

    close gcf

end
clear i