%% ABT %%
% The following runs code to process, analyze and plot data related to 
% tag deployments on tuna from the North Atlantic.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026

%% Requirements

warning off

fdir = '***';

%% Load Data

load([fdir '***'])
run load_SSM_ABT
run load_entries_ABT

%% Create empty variables for dive metrics and other variables computed.

run blank_variables_ABT

%% Loop through toppIDs with archival/recovered data.

toppID = META.toppID(strcmp(META.archivaldata,'archdata'));

cnt = 0;
for i = 1:length(toppID)

    disp(i)

    k = find(toppID(i) == META.toppID);

    run load_archive_ABT
    run detect_dives_ABT
    run daily_dive_stats_ABT
    run hourly_dive_stats_ABT
    run calculate_TaT_ABT
    run calculate_TaD_ABT
    run calculate_daily_profiles_ABT
    
    clear PSAT

end
clear i k

B.dives = dives;
clear dives

%% Calculate horizontal speed.

run calculate_horizontal_speed_ABT

%% Assign stock to dives and SSM tracks

run assign_and_count_stock_ABT

%% Load ICCAT .shp file

cd([fdir '/data/shp']);
iccat = shaperead('ICCAT_polygons.shp');

%% Main Figures

% Figure 1
run plot_overview_map_all_series_with_bathy_ABT
run plot_overview_map_by_series_with_bathy_ABT

% Figure 2
run plot_horizontal_speed_map_all_ABT
run plot_daily_dive_frequency_map_all_ABT
run plot_dive_duration_map_all_ABT
run plot_dive_descent_rate_map_all_ABT
run plot_median_daynight_depth_map_all_ABT
run plot_daily_max_depth_map_all_ABT
run plot_time_in_mesopelagic_map_all_ABT

% Figure 3
run plot_overview_map_by_stock_ABT
run plot_bin_map_ABT

% Figure 4
run plot_overview_map_all_stock_ABT
run plot_overview_map_by_stock_by_quarter_ABT

% Figure 5
run load_SS_entries_exits_ABT
run update_spawning_entries_SS_ABT
run plot_TaT_in_spawning_ground_ABT

%% Supplemental Figures

% Figure S4
run plot_overview_map_all_series_ABT
run plot_overview_map_all_stock_ABT

% Figure S5
run plot_overview_map_all_stock_no_SS_ABT
run plot_overview_map_by_stock_by_quarter_no_SS_ABT
