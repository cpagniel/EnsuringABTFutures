%% plot_median_daynight_depth_map_all_ABT.m
% Sub-function of ABT.m; plots median day and night dive depth in
% 1 x 1 degree bins.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026

for i = 0:1

    %% Create figure and axes for bathymetry.

    figure('Position',[476 334 716 532]);

    %% Set projection of map.

    LATLIMS = [8 70]; LONLIMS = [-100 40];
    m_proj('miller','lon',LONLIMS,'lat',LATLIMS);

    %% Bin SSM Positions

    binned.LONedges = -100:1:40;
    binned.LATedges = 8:1:70;

    if i == 1
        [binned.mz,binned.LONmid,binned.LATmid] = twodmed(SSM.lon,...
            SSM.lat,...
            SSM.MedDayDepth,binned.LONedges,binned.LATedges);
        bins.all.median_depth_day = binned.mz.';
    elseif i == 0
        [binned.mz,binned.LONmid,binned.LATmid] = twodmed(SSM.lon,...
            SSM.lat,...
            SSM.MedNigDepth,binned.LONedges,binned.LATedges);
        bins.all.median_depth_night = binned.mz.';
    end

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
    tmp = getPyPlot_cMap('gnuplot2_r',48);
    colormap(tmp(5:end-3,:));
    set(h,'Position',[0.6493 0.3341 0.2325 0.0244])
    caxis([0 150]);

    if i == 0
        ylabel(h,'Median Night Depth (m)','FontSize',16,'FontWeight','bold');
    elseif i == 1
        ylabel(h,'Median Day Depth (m)','FontSize',16,'FontWeight','bold');
    end

    clear tmp

    %% Set location of figure to match bin_map

    set(gca,'Position',[0.1300 0.1100 0.7750 0.8150]);

    %% Save

    cd([fdir '/figures']);
    if i == 0
        exportgraphics(gcf,'median_night_depth_map_ABT.png','Resolution',300);
    elseif i == 1
        exportgraphics(gcf,'median_day_depth_map_ABT.png','Resolution',300);
    end

    %% Clear

    clear h* binned *LIMS
    clear ans

    close gcf

end
clear i