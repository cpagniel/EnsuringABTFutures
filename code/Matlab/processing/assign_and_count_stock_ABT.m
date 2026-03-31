%% assign_and_count_stock_ABT.m
% Sub-function of ABT.m; assigns stock information from META to other
% structures and calculates how many stocks are in each bin.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026
%% Assign stock to other structures.

ss = unique(META.stock);

B.dives.stock(ismember(B.dives.toppID,META.toppID(strcmp(META.stock,ss{1})))) = {'GOM'};
B.dives.stock(ismember(B.dives.toppID,META.toppID(strcmp(META.stock,ss{2})))) = {'MED'};
B.dives.stock(ismember(B.dives.toppID,META.toppID(strcmp(META.stock,ss{3})))) = {'SS'};

B.speed.stock(ismember(B.speed.toppid,META.toppID(strcmp(META.stock,ss{1})))) = {'GOM'};
B.speed.stock(ismember(B.speed.toppid,META.toppID(strcmp(META.stock,ss{2})))) = {'MED'};
B.speed.stock(ismember(B.speed.toppid,META.toppID(strcmp(META.stock,ss{3})))) = {'SS'};

TaT.Stock(ismember(TaT.TOPPID,META.toppID(strcmp(META.stock,ss{1})))) = {'GOM'};
TaT.Stock(ismember(TaT.TOPPID,META.toppID(strcmp(META.stock,ss{2})))) = {'MED'};
TaT.Stock(ismember(TaT.TOPPID,META.toppID(strcmp(META.stock,ss{3})))) = {'SS'};

TaD.Stock(ismember(TaD.TOPPID,META.toppID(strcmp(META.stock,ss{1})))) = {'GOM'};
TaD.Stock(ismember(TaD.TOPPID,META.toppID(strcmp(META.stock,ss{2})))) = {'MED'};
TaD.Stock(ismember(TaD.TOPPID,META.toppID(strcmp(META.stock,ss{3})))) = {'SS'};

pfl.Stock(ismember(pfl.TOPPID,META.toppID(strcmp(META.stock,ss{1})))) = {'GOM'};
pfl.Stock(ismember(pfl.TOPPID,META.toppID(strcmp(META.stock,ss{2})))) = {'MED'};
pfl.Stock(ismember(pfl.TOPPID,META.toppID(strcmp(META.stock,ss{3})))) = {'SS'};

clear ss

%% Add number of stocks

% Add number of stocks to speed
for j = 1:height(SSM)
    ind_time = find(B.speed.datetime == SSM.Date(j));
    ind_topp = find(B.speed.toppid == SSM.TOPPID(j));

    ind = intersect(ind_time,ind_topp);

    B.speed.NumStock(ind) = SSM.NumStock(j);

end
clear j
clear ind*

% Add number of stocks to dives
for j = 1:height(SSM)
    ind_time = find(B.dives.day == SSM.Date(j));
    ind_topp = find(B.dives.toppID == SSM.TOPPID(j));

    ind = intersect(ind_time,ind_topp);

    B.dives.NumStock(ind) = SSM.NumStock(j);

end
clear j
clear ind*

% Add number of stocks to TaD and TaT
TaD.NumStock = SSM.NumStock;
TaT.NumStock = SSM.NumStock;
pfl.NumStock = SSM.NumStock;

% Add if in spawning ground to TaD and TaT
TaD.InSpawningGround = SSM.InSpawningGround;
TaT.InSpawningGround = SSM.InSpawningGround;
pfl.InSpawningGround = SSM.InSpawningGround;