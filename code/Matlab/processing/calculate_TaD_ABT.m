%% calculate_TaD_ABT.m
% Sub-function of ABT.m; calculates the number of observations in each
% depth bin per day.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026
%% Define bins.

binD = 0:10:1500;
% binD = [0 5 10 50:50:300 500 700 1000 1200];

%% Get unique dates in PSAT.

dt = unique(PSAT.Date);

%% Loop through days and compute number of observations in each bin.

disp('Calculate time at depth...');

for j = 1:length(dt)
    [tmp,~,~] = histcounts(...
        PSAT.Depth(PSAT.Date == dt(j)),binD);
    tmp(tmp == 0) = NaN; % replace zeros with NaNs

    ind_time = find(TaT.Date == dt(j));
    ind_toppID = find(TaT.TOPPID == PSAT.TOPPID(1));
    ind = intersect(ind_time,ind_toppID);

    for jj = 1:length(tmp)
        TaD(ind,jj + 8) = table(tmp(jj));
    end
    clear jj
    TaD.N(ind) = sum(PSAT.Date == dt(j));

    clear tmp
    clear ind*
end
clear j

clear dt
clear binD