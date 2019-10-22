% plotting measured water level for March 2017

% read data from CSV
data = readtable('./Water_levels/CO-OPS_9414750_wl_Alameda.csv');

date = table2array(data(:,1)); % date column
time = table2array(data(:,2)); % time column
x = table2array(data(:,3)); % datacolumn

% convert string to number for the measurements
x=cellfun(@str2num,x);

% creating string of joint date and time of the day
date_str=strcat(date,{','},time);
dateNumber = datenum([date_str],'yyyy/mm/dd,HH:MM');

% creating date as number from start of measurement period March 1, 2017
date = dateNumber-dateNumber(1);

% plotting
wl_plot = plot(date,x);
dt = diff(date);
dtbar = mean(dt); %TODO: what is this for?
title('Predicted Water Levels March 2017');
xlabel('Day Number');
ylabel('Water Level [m]');
