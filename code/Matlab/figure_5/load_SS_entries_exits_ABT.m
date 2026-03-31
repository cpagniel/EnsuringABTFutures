%% load_SS_entries_exits_ABT.m
% Sub-function of ABT.m; load entries and exits.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 12);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["eventid", "days", "year", "entrydate", "lastdate", "len", "age", "couldSpawn", "trueExit", "adjEntry", "adjExit", "inArea"];
opts.VariableTypes = ["double", "double", "categorical", "datetime", "datetime", "double", "double", "categorical", "categorical", "double", "double", "categorical"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["year", "couldSpawn", "trueExit", "inArea"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "entrydate", "InputFormat", "MM/dd/yyyy");
opts = setvaropts(opts, "lastdate", "InputFormat", "MM/dd/yyyy");

% Import the data
entryexitssupdated = readtable("***.csv", opts);

%% Clear temporary variables
clear opts

%% Assign Time Zone

entryexitssupdated.entrydate.TimeZone = 'UTC';
entryexitssupdated.lastdate.TimeZone = 'UTC';