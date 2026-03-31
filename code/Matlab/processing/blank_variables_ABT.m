%% blank_variables_ABT.m
% Sub-function of ABT.m; creates blank variables for dive metrics, etc.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026
%% Create blank variables for loop.

SSM.DivesPerDay = NaN(height(SSM),1);
SSM.MaxDepth = NaN(height(SSM),1);
SSM.MedDayDepth = NaN(height(SSM),1);
SSM.MedNigDepth = NaN(height(SSM),1);
SSM.TimeinMeso = NaN(height(SSM),1);

SSM.DivesPerHour0 = NaN(height(SSM),1);
SSM.DivesPerHour1 = NaN(height(SSM),1);
SSM.DivesPerHour2 = NaN(height(SSM),1);
SSM.DivesPerHour3 = NaN(height(SSM),1);
SSM.DivesPerHour4 = NaN(height(SSM),1);
SSM.DivesPerHour5 = NaN(height(SSM),1);
SSM.DivesPerHour6 = NaN(height(SSM),1);
SSM.DivesPerHour7 = NaN(height(SSM),1);
SSM.DivesPerHour8 = NaN(height(SSM),1);
SSM.DivesPerHour9 = NaN(height(SSM),1);
SSM.DivesPerHour10 = NaN(height(SSM),1);
SSM.DivesPerHour11 = NaN(height(SSM),1);
SSM.DivesPerHour12 = NaN(height(SSM),1);
SSM.DivesPerHour13 = NaN(height(SSM),1);
SSM.DivesPerHour14 = NaN(height(SSM),1);
SSM.DivesPerHour15 = NaN(height(SSM),1);
SSM.DivesPerHour16 = NaN(height(SSM),1);
SSM.DivesPerHour17 = NaN(height(SSM),1);
SSM.DivesPerHour18 = NaN(height(SSM),1);
SSM.DivesPerHour19 = NaN(height(SSM),1);
SSM.DivesPerHour20 = NaN(height(SSM),1);
SSM.DivesPerHour21 = NaN(height(SSM),1);
SSM.DivesPerHour22 = NaN(height(SSM),1);
SSM.DivesPerHour23 = NaN(height(SSM),1);

SSM.MedDepthHour0 = NaN(height(SSM),1);
SSM.MedDepthHour1 = NaN(height(SSM),1);
SSM.MedDepthHour2 = NaN(height(SSM),1);
SSM.MedDepthHour3 = NaN(height(SSM),1);
SSM.MedDepthHour4 = NaN(height(SSM),1);
SSM.MedDepthHour5 = NaN(height(SSM),1);
SSM.MedDepthHour6 = NaN(height(SSM),1);
SSM.MedDepthHour7 = NaN(height(SSM),1);
SSM.MedDepthHour8 = NaN(height(SSM),1);
SSM.MedDepthHour9 = NaN(height(SSM),1);
SSM.MedDepthHour10 = NaN(height(SSM),1);
SSM.MedDepthHour11 = NaN(height(SSM),1);
SSM.MedDepthHour12 = NaN(height(SSM),1);
SSM.MedDepthHour13 = NaN(height(SSM),1);
SSM.MedDepthHour14 = NaN(height(SSM),1);
SSM.MedDepthHour15 = NaN(height(SSM),1);
SSM.MedDepthHour16 = NaN(height(SSM),1);
SSM.MedDepthHour17 = NaN(height(SSM),1);
SSM.MedDepthHour18 = NaN(height(SSM),1);
SSM.MedDepthHour19 = NaN(height(SSM),1);
SSM.MedDepthHour20 = NaN(height(SSM),1);
SSM.MedDepthHour21 = NaN(height(SSM),1);
SSM.MedDepthHour22 = NaN(height(SSM),1);
SSM.MedDepthHour23 = NaN(height(SSM),1);

TaT = SSM(:,1:8);
TaT.temp0 = NaN(height(TaT),1);
TaT.temp2 = NaN(height(TaT),1);
TaT.temp4 = NaN(height(TaT),1);
TaT.temp6 = NaN(height(TaT),1);
TaT.temp8 = NaN(height(TaT),1);
TaT.temp10 = NaN(height(TaT),1);
TaT.temp12 = NaN(height(TaT),1);
TaT.temp14 = NaN(height(TaT),1);
TaT.temp16 = NaN(height(TaT),1);
TaT.temp18 = NaN(height(TaT),1);
TaT.temp20 = NaN(height(TaT),1);
TaT.temp22 = NaN(height(TaT),1);
TaT.temp24 = NaN(height(TaT),1);
TaT.temp26 = NaN(height(TaT),1);
TaT.temp28 = NaN(height(TaT),1);
TaT.temp30 = NaN(height(TaT),1);
TaT.N = NaN(height(TaT),1);

binD = 0:10:1500;

TaD = SSM(:,1:8);
for i = 1:length(binD)
    TaD.(['depth' num2str(binD(i))]) = NaN(height(TaD),1);
end
clear i
TaD.N = NaN(height(TaD),1);

clear binD

pfl = SSM(:,1:8);
pfl.Depth = cell(height(pfl),1);
pfl.Temperature = cell(height(pfl),1);