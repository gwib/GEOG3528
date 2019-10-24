T2mPath = "./L1S2/T2m_1979.nc";
ncdisp(T2mPath);

latT2m = ncread(T2mPath, 'latitude');
lonT2m = ncread(T2mPath, 'longitude');
t2mT2m = ncread(T2mPath, 't2m');

% Convert Kelvin temperatures to celsius
% t2mC = convtemp(t2mT2m,'K','C');
% alternative
t2mC = t2mT2m - 273.15;

t2mCJan = t2mC(:,:,1);
% plotting alternatives
imagesc(t2mCJan);
colorbar;
contourf(t2mCJan);
colorbar;

% transpose matrix
t2mCJanTranspLoop = zeros(241,480);

for i = 1:241
    for j=1:480
        t2mCJanTranspLoop(i,j) = t2mCJan(j,i);
    end
end

imagesc(lonT2m,latT2m,t2mCJanTranspLoop);
