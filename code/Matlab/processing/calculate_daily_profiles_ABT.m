%% calculate_daily_profiles_ABT.m
% Sub-function of ABT; creates daily temperature-depth profiles by
% (1) averaging data into 1-m bins, (2) vertically interpolating data onto
% a 1-m regular grid, (3) smoothed with a 20-m window.
%
% Author: Camille Pagniello, University of Hawai'i at Manoa (cpagniel@hawaii.edu)
% 
% Last Update: 03/30/2026
%% Create daily datetime vector.

dt = datetime(year(PSAT.DateTime),...
    month(PSAT.DateTime),...
    day(PSAT.DateTime),'TimeZone','UTC');

dt = unique(dt);

%% Create 1-m bin averaged, interpolated, daily profiles.

for j = 1:length(dt)

    % Calculate index.
    ind_time = find(pfl.Date == dt(j));
    ind_toppID = find(pfl.TOPPID == PSAT.TOPPID(1));
    ind = intersect(ind_time,ind_toppID);

    if ~isempty(ind)
        % Subset PSAT based on day.
        tmp = PSAT(PSAT.Date == dt(j),:);

        % Average temperature data in 1-m bins.
        bins.d_bin = floor(min(tmp.Depth)):1:ceil(max(tmp.Depth))+1; % create 1-m bins between minimum and maximum depth
        bins.d_cat = discretize(tmp.Depth,bins.d_bin.'); % determine which bin each depth-temperature measurement was made in

        bins.t_avg = accumarray(bins.d_cat,tmp.ExternalTemperature,[],@mean); % take average of all temperatures in 1-m bin
        bins.t_binned = bins.t_avg(bins.t_avg ~= 0); bins.d_binned = bins.d_bin(bins.t_avg ~= 0); % remove empty bins between minimum and maximum depth

        if length(bins.t_binned) >= 4

            % Interpolate onto a 1-m regular grid between minimum and maximum depth.
            interp.d = min(bins.d_bin):1:max(bins.d_bin);
            interp.t = gsw_t_interp(bins.t_binned,bins.d_binned,interp.d);

            % Remove NaNs.
            interp.d = interp.d(~isnan(interp.t));
            interp.t = interp.t(~isnan(interp.t));

            % Smooth profile applying moving median with a window 20 m window.
            pfl.Depth{ind} = interp.d.';
            pfl.Temperature{ind} = smoothdata(interp.t,'movmedian',20);

            % Add NaNs from 0 to minimum depth if profile does not start at 0 m.
            if min(bins.d_bin) ~= 0
                pfl.Depth{ind} = [transpose(0:min(bins.d_bin)-1); pfl.Depth{ind}];
                pfl.Temperature{ind} = [NaN(length(0:min(bins.d_bin)-1),1); pfl.Temperature{ind}];
            end

            % Add NaNs from max depth down to 1500 m to standardize vector
            % length
            len = length(pfl.Depth{ind});
            if len < 1500
                pfl.Depth{ind} = [pfl.Depth{ind}; NaN(1500-len,1)];
                pfl.Temperature{ind} = [pfl.Temperature{ind}; NaN(1500-len,1)];
            end

        else

            pfl.Depth{ind} = NaN(1500,1);
            pfl.Temperature{ind} = NaN(1500,1);

        end

    %% Clear

    clear tmp
    clear bins
    clear interp
    clear len
    clear ind*

    end

end
clear j

clear dt

%% Assign blank arrays to empty cells on SSM days with no archival data

emptyCells = cellfun(@isempty, pfl.Temperature);
pfl.Depth(emptyCells) = {NaN(1500,1)};
pfl.Temperature(emptyCells) = {NaN(1500,1)};

clear emptyCells