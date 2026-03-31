%% update_spawning_entries_SS_ABT.m
% Subfunction of ABT.m; correct SS entries file.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026

%%

toppID_SS = unique(entryexitssupdated.eventid/100);

for i = 1:height(TaT)
    disp(i)
    if ismember(TaT.TOPPID(i),toppID_SS)
        if TaT.InSpawningGround(i) == 1
            sub = entryexitssupdated(entryexitssupdated.eventid/100 == TaT.TOPPID(i),:);
            sub = sub(sub.inArea == "TRUE",:);
            for j = 1:height(sub)
                if TaT.Date(i) >= sub.entrydate(j) && TaT.Date(i) <= sub.lastdate(j)
                    TaT.InSpawningGround(i) = 1;
                else
                    TaT.InSpawningGround(i) = 0;
                end
            end
            clear j
            clear sub
        end
    end
end
clear i
clear toppID_SS