%% daily_dive_stats_ABT.m
% Sub-function of ABT; computes daily dive statistics.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026
%% Compute number of dives per day.

disp('Compute number of dives per day...');

for j = 1:height(SSM)
    if ismember(SSM.TOPPID(j),toppID(i))

        ind_time = find(dives.day == SSM.Date(j));
        ind_topp = find(dives.toppID == SSM.TOPPID(j));

        ind = intersect(ind_time,ind_topp);

        SSM.DivesPerDay(j) = length(ind);

    end
end
clear j
clear ind*

%% Compute daily max depth.

disp('Compute daily maximum depth...');

tmp = groupsummary(PSAT,{'TOPPID','Date'},'max','Depth');
tmp = removevars(tmp,'GroupCount');

for j = 1:height(tmp)

        ind_time = find(tmp.Date(j) == SSM.Date);
        ind_topp = find(tmp.TOPPID(j) == SSM.TOPPID);

        ind = intersect(ind_time,ind_topp);

        SSM.MaxDepth(ind) = tmp.max_Depth(j);

end
clear j
clear ind*
clear tmp

%% Compute day median diving depth.

disp('Compute median depth during the day...')

tmp = groupsummary(PSAT,{'TOPPID','Date','DayNight'},'median','Depth');
tmp = removevars(tmp,'GroupCount');
tmp = tmp(tmp.DayNight == 1,:);
tmp.Properties.VariableNames{4} = 'median_Depth_day';
tmp(:,3) = [];

for j = 1:height(tmp)

        ind_time = find(tmp.Date(j) == SSM.Date);
        ind_topp = find(tmp.TOPPID(j) == SSM.TOPPID);

        ind = intersect(ind_time,ind_topp);

        SSM.MedDayDepth(ind) = tmp.median_Depth_day(j);

end
clear j
clear ind*
clear tmp

%% Compute night median diving depth.

disp('Compute median depth at night...')

tmp = groupsummary(PSAT,{'TOPPID','Date','DayNight'},'median','Depth');
tmp = removevars(tmp,'GroupCount');
tmp = tmp(tmp.DayNight == 0,:);
tmp.Properties.VariableNames{4} = 'median_Depth_night';
tmp(:,3) = [];

for j = 1:height(tmp)

        ind_time = find(tmp.Date(j) == SSM.Date);
        ind_topp = find(tmp.TOPPID(j) == SSM.TOPPID);

        ind = intersect(ind_time,ind_topp);

        SSM.MedNigDepth(ind) = tmp.median_Depth_night(j);

end
clear j
clear ind*
clear tmp

%% Compute daily time in mesopelagic.

disp('Compute daily time in mesopelagic...')

for j = 1:height(SSM)
    if ismember(SSM.TOPPID(j),toppID(i))
        ind_time = find(PSAT.Date == SSM.Date(j));
        ind_topp = find(PSAT.TOPPID == SSM.TOPPID(j));

        ind = intersect(ind_time,ind_topp);

        SSM.TimeinMeso(j) = sum(PSAT.Depth(ind) >= 200)/(24*60*60/META.sample_rate(META.toppID == SSM.TOPPID(j)))*100;

        if SSM.Date(j) == min(SSM.Date(SSM.TOPPID == SSM.TOPPID(j))) || SSM.Date(j) == max(SSM.Date(SSM.TOPPID == SSM.TOPPID(j)))
            SSM.TimeinMeso(j) = NaN;
        end

    end
end
clear j
clear ind*