%% calculate_horizontal_speed_ABT.m
% Sub-function of ABT.m; calculates horizontal speed.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026
%% Calulate horizontal speed.

toppID = unique(SSM.TOPPID);

for i = 1:length(toppID)
    tmp.lat = SSM.lat(SSM.TOPPID == toppID(i));
    tmp.lon = SSM.lon(SSM.TOPPID == toppID(i));
    tmp.date = SSM.Date(SSM.TOPPID == toppID(i));

    tbl = table(toppID(i)*ones(sum(SSM.TOPPID == toppID(i))-1,1),'VariableNames',{'toppid'});
    tbl.Distance_km = m_lldist(tmp.lon,tmp.lat);
    tbl.Speed_m_per_s = tbl.Distance_km*1000./86400; % 1 day = 86400 seconds
    tbl.lat = tmp.lat(1:end-1);
    tbl.lon = tmp.lon(1:end-1);
    tbl.datetime = tmp.date(1:end-1);
    
    if isfield(B,'speed')
        B.speed = [B.speed; tbl];
    else
        B.speed = tbl;
    end

    clear tbl
    clear tmp

end
clear i
clear toppID