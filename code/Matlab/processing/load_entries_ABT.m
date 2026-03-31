%% load_entries_ABT.m
% Sub-function of ABT.m; loads data associated with spawning area entries
% and exits.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026
%% Load GOM

cd([fdir '***'])
entries = readtable("***.csv");
entries.stock = repmat({'GOM'},height(entries),1);

%% Load MED

tmp = readtable("***.csv");
tmp.stock = repmat({'MED'},height(tmp),1);
entries = [entries; tmp];

clear tmp

%% Load SS 

tmp = readtable("***.csv");
tmp.stock = repmat({'SS'},height(tmp),1);
entries = [entries; tmp];

clear tmp