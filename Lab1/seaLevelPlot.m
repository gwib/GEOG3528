% read data from CSV
data = readtable('./Water_levels/9414750_meantrend.csv');

date = table2array(data(:,1)); % date column
time = table2array(data(:,2)); % time column
x = table2array(data(:,3)); % data column OBS: doesn't have measured values

% convert string to number for the measurements
x=cellfun(@str2num,x);