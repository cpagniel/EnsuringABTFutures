%% plot_overview_map_by_stock_by_quarter_ABT %%
% Sub-function of ABT.m; plots SSM tracks of all tags colored by
% stock and quarter.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026

%% Set quarters.

qq = month(SSM.Date);
qq(qq == 12 | qq == 1 | qq == 2) = 1;
qq(qq == 3 | qq == 4 | qq == 5) = 2;
qq(qq == 6 | qq == 7 | qq == 8) = 3;
qq(qq == 9 | qq == 10 | qq == 11) = 4;

SSM.Quarter = qq;

clear qq

%% Loop through all quarters

for i = 1:4

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

    % by stock and quarter

    % GOM
    m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{1}))) & SSM.Quarter == i),...
        SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{1}))) & SSM.Quarter == i),...
        'ko','MarkerFaceColor',cmap.stock(1,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

    hold on

    % Med
    m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{2}))) & SSM.Quarter == i),...
        SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{2}))) & SSM.Quarter == i),...
        'ko','MarkerFaceColor',cmap.stock(2,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

    % SS
    m_plot(SSM.lon(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{3}))) & SSM.Quarter == i),...
        SSM.lat(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{3}))) & SSM.Quarter == i),...
        'ko','MarkerFaceColor',cmap.stock(3,:),'MarkerEdgeColor','k','MarkerSize',4,'LineStyle','none','LineWidth',0.8);

    m(1) = m_plot(-100,100,'o','MarkerFaceColor',cmap.stock(1,:),'MarkerEdgeColor','k','MarkerSize',5,'LineWidth',0.8);
    m(2) = m_plot(-100,100,'o','MarkerFaceColor',cmap.stock(2,:),'MarkerEdgeColor','k','MarkerSize',5,'LineWidth',0.8);
    m(3) = m_plot(-100,100,'o','MarkerFaceColor',cmap.stock(3,:),'MarkerEdgeColor','k','MarkerSize',5,'LineWidth',0.8);

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

    %% Add Legend

    [~,icon] = legend(m,{['Gulf: ' num2str(roundn(mean(SSM.length(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{1}))) & SSM.Quarter == i),'omitnan'),0)) ...
        ' CFL (n = ' num2str(length(unique(SSM.TOPPID(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{1}))) & SSM.Quarter == i)))) ')'],...
        ['Med: ' num2str(roundn(mean(SSM.length(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{2}))) & SSM.Quarter == i),'omitnan'),0)) ...
        ' CFL (n = ' num2str(length(unique(SSM.TOPPID(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{2}))) & SSM.Quarter == i)))) ')'],...
        ['SS: ' num2str(roundn(mean(SSM.length(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{3}))) & SSM.Quarter == i),'omitnan'),0)) ...
        ' CFL (n = ' num2str(length(unique(SSM.TOPPID(ismember(SSM.TOPPID,META.toppID(strcmp(META.stock,ss{3}))) & SSM.Quarter == i)))) ')']},'FontSize',14,...
        'Position',[0.7 0.245 0.13 0.157]);
    icons = findobj(icon, 'type', 'line');
    set(icons,'MarkerSize',12);
    clear ss
    clear icon*

    %% Save figure.

    cd([fdir '/figures']);
    if i == 1
        exportgraphics(gcf,'overview_map_Winter_ABT.png','Resolution',300);
    elseif i == 2
        exportgraphics(gcf,'overview_map_Spring_ABT.png','Resolution',300);
    elseif i == 3
        exportgraphics(gcf,'overview_map_Summer_ABT.png','Resolution',300);
    elseif i == 4
        exportgraphics(gcf,'overview_map_Fall_ABT.png','Resolution',300);
    end

    %% Clear

    clear ax* h* m* *LIMS
    clear cs ch
    clear h1
    clear ans

    close gcf

end
clear i