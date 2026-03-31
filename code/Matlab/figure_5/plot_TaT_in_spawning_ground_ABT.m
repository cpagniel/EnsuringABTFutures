%% plot_TaT_in_spawning_ground_ABT.m
% Sub-function of ABT.m; calculates TaT for each stock within their spawning grounds.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026

%% Create list of TOPP IDs.

toppID = META.toppID(strcmp(META.archivaldata,'archdata'));

%% Define bins.

binT = 0:2:30;

%% Get the number of stocks.

ss = unique(META.stock);

%% Create TaT for each stock within spawning ground.

% First, take median for each toppID and then take median of all toppIDs.
% Make sure that these are in the spawning ground.

tmp = NaN(length(toppID),length(binT));

timeattemp.median = NaN(length(ss),length(binT));
timeattemp.mad = NaN(length(ss),length(binT));

for i = 1:length(ss)
    for j = 1:length(toppID)
        tmp(j,:) = median(table2array(TaT(strcmp(TaT.Stock,ss{i}) & TaT.TOPPID == toppID(j) & TaT.InSpawningGround == 1,9:24))./TaT.N(strcmp(TaT.Stock,ss{i}) & TaT.TOPPID == toppID(j) & TaT.InSpawningGround == 1),'omitnan');
    end
    timeattemp.median(i,:) = median(tmp,'omitnan');
    timeattemp.mad(i,:) = mad(tmp,1);
end
clear i
clear j
clear tmp

%% Plot.

for i = 1:length(ss)

    figure;

    t = tiledlayout(1,1);
    ax1 = axes(t);

    b = barh(binT,timeattemp.median(i,:)*100,'histc');
    b.EdgeColor = 'k';
    b.FaceColor = cmap.stock(i,:);
    b.LineWidth = 1;

    hold on

    er = errorbar(timeattemp.median(i,:)*100,binT+1,[],timeattemp.mad(i,:)*100,'horizontal');
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    er.LineWidth = 1;

    set(gca,'ydir','reverse','FontSize',16,'linewidth',2,'tickdir','out');
    xlabel('Median % Time at Temperature','FontSize',20); 
    ylabel('Temperature (^oC)','FontSize',20);
    xlim([0 100]); ylim([0 32]); set(gca,'XTick',0:25:100);
    set(gca,'XTickLabels',{'0';'25';'50';'75';'100'});
    set(gca,'YTick',1:2:32);
    set(gca,'YTickLabels',{'0-2'; '2-4'; '4-6'; '6-8'; '8-10'; '10-12';...
                    '12-14'; '14-16'; '16-18'; '18-20'; '20-22'; '22-24'; '24-26'; '26-28'; '28-30'; '30-32'});
    axis square

    %% Save

    cd([fdir '/figures'])
    exportgraphics(gcf,['TaT_in_spawning_ground_' ss{i} '.png'],'Resolution',300)

    close all
    
    %% Clear

    clear ax*
    clear t
    clear b
    clear er

end
clear i
clear binT