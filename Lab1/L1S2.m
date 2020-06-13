%% Data preparation

T2mPath = "./L1S2/T2m_1979.nc";
ncdisp(T2mPath);

lat = ncread(T2mPath, 'latitude');
lon = ncread(T2mPath, 'longitude');
t2mT2m = ncread(T2mPath, 't2m');


%% Session 2
% Convert Kelvin temperatures to celsius
% t2mC = convtemp(t2mT2m,'K','C');
% alternative
t2mC = t2mT2m - 273.15;

% extract data for January
t2mCJan = t2mC(:,:,1);
% plotting alternatives
imagesc(t2mCJan);
colorbar;
contourf(t2mCJan);
colorbar;

t2mCJanTransp = zeros(241,480);
for i = 1:241
    for j=1:480
        t2mCJanTransp(i,j) = t2mCJan(j,i);
    end
end
imagesc(lon,lat,t2mCJanTransp);


%% Session 3

% transpose matrix
t2mCT = zeros(241,480,12);

for i = 1:241
    for j=1:480
        for k=1:12
            t2mCT(i,j,k) = t2mC(j,i,k);
        end
    end
end


%
lat_min=60.98;
lat_max=83.27;
lon_min=360-71.30;
lon_max=360-11.01;

for i=1:480
    if lon(i) < lon_max
        lonMaxIndex=i;
    end
    if lon(i) > lon_min && lon(i-1) < lon_min
        lonMinIndex = i;
    end
end

latMinIndex=10;
latMaxIndex=39;


t2mMask=t2mCT(latMinIndex:latMaxIndex,lonMinIndex:lonMaxIndex,:);

pddMask = zeros(30,81);
sd_0 = 4.5;
for i=1:30
    for j=1:81
        pddMask(i,j) = pdd(t2mMask(i,j,:),sd_0);
    end
end

