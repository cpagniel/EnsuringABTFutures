%% hourly_dive_stats_ABT.m
% Sub-function of ABT; computes hourly dive statistics.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026
%% Compute number of dives per hour.

disp('Compute number of dives per hour...');

for k = 0:1:23
    for j = 1:height(SSM)
        if ismember(SSM.TOPPID(j),toppID(i))

            ind_day = find(dives.day == SSM.Date(j));
            ind_topp = find(dives.toppID == SSM.TOPPID(j));

            ind = intersect(ind_day,ind_topp);

            ind_hour = find(dives.hour == k);

            ind = intersect(ind_hour,ind);

            SSM.(['DivesPerHour' num2str(k)])(j) = length(ind);

        end
    end
end
clear j k
clear ind*

%% Compute hourly median diving depth.

disp('Compute hourly median depth...')

PSAT.Hour = hour(PSAT.DateTime);

tmp = groupsummary(PSAT,{'TOPPID','Date','Hour'},'median','Depth');
tmp = removevars(tmp,'GroupCount');

for k = 0:1:23
    for j = 1:height(SSM)
        if ismember(SSM.TOPPID(j),toppID(i))

            ind_day = find(tmp.Date == SSM.Date(j));
            ind_topp = find(tmp.TOPPID == SSM.TOPPID(j));

            ind = intersect(ind_day,ind_topp);

            ind_hour = find(tmp.Hour == k);

            ind = intersect(ind_hour,ind);

            if ~isempty(ind)
                SSM.(['MedDepthHour' num2str(k)])(j) = tmp.median_Depth(ind);
            end

        end
    end
end
clear j k
clear ind*
clear tmp