close all



ground.saturation_rocks = 0.5; %Volumetric fraction of the pure "rock system", i.e. only rocks, no stones or fines
ground.saturation_stones = 0.5;
ground.saturation_fines = 0.5;

%these must be made dependent on temperature, water content, etc
ground.bedrock2rocks = 0.0005; %fraction per year -> 0.1 means that 10% of the bedrock volume in a cell will go over to rocks in one year
ground.rocks2stones = 0.00001;
ground.rocks2fines = 0.000005;
ground.stones2fines = 0.000005;

ground.move_velocity_rocks = 0.001; %1mm/year, upward velocity of a single rock
ground.move_velocity_stones = 0.0005; %0.5mm/year

%---------------------------

timestep = 1; % one year
store_interval =10; %store results every ten years
ground.D = repmat(0.1,20,1); %2m of initial depth

%start with 100% bedrock, you can also define a different initial state

ground.fines = zeros(20,1);
ground.stones = zeros(20,1);
ground.rocks = zeros(20,1);
ground.bedrock = ones(20,1);



ground.rocksD = ground.rocks .* ground.D;
ground.stonesD = ground.stones .* ground.D;
ground.finesD = ground.fines .* ground.D;
ground.bedrockD = ground.bedrock .* ground.D;


% initialize the arrays to store results
results_rocks = [];
results_stones = [];
results_fines = [];
results_porosity = [];
res_sum=[];
res_surface_pos=[];


for years =1:26000   %26000years
    ground = erosion(ground, timestep);
    ground = get_D(ground);
    ground = move_rocks_up(ground, timestep);
    ground = move_stones_up(ground, timestep);
    
    
    if mod(years,store_interval)==0  %store results every XX years
        
        results_rocks = [results_rocks ground.rocks];
        results_stones = [results_stones ground.stones];
        results_fines =[ results_fines ground.fines];
        results_porosity = [results_porosity ground.porosity];
        res_sum = [res_sum; sum(ground.rocksD)+sum(ground.stonesD) + sum(ground.finesD)];
        res_surface_pos =[res_surface_pos; sum(ground.D)];
    end
end

plot(res_surface_pos) %Fig 1
figure
imagesc(results_rocks) %Fig 2
colorbar
figure
imagesc(results_stones) % Fig 3
colorbar
figure
imagesc(results_fines) %Fig 4
colorbar



function ground = erosion(ground, timestep)
%timestep in years

eroding_bedrock_volume = 0.1;

bedrock_erodable = ground.bedrockD.*0;

for i=1:size(ground.bedrockD,1)
   bedrock_erodable(i,1) = min(ground.bedrockD(i,1), eroding_bedrock_volume);
   eroding_bedrock_volume =  max(eroding_bedrock_volume - bedrock_erodable(i,1), 0);
end

flux_bedrockD = - bedrock_erodable .*ground.bedrock2rocks ;

flux_rocksD =  - ground.rocksD .* (ground.rocks2stones + ground.rocks2fines)  + bedrock_erodable .*ground.bedrock2rocks;
flux_stonesD = ground.rocksD .* ground.rocks2stones - ground.stonesD .* ground.stones2fines;
flux_finesD = ground.rocksD .* ground.rocks2fines + ground.stonesD .* ground.stones2fines;

ground.bedrockD = ground.bedrockD  + flux_bedrockD.* timestep;
ground.rocksD = ground.rocksD + flux_rocksD .* timestep;
ground.stonesD = ground.stonesD + flux_stonesD .* timestep;
ground.finesD = ground.finesD + flux_finesD .* timestep;
end


function ground = get_D(ground)

ground.D = ground.bedrockD;

ground.D = ground.D +  ground.rocksD ./ ground.saturation_rocks; %real space
void_space = ground.rocksD ./ ground.saturation_rocks - ground.rocksD; %rock space, meter of free spce that can be filled

stones_underD = min(ground.stonesD ./ ground.saturation_stones, void_space); % real space
stones_overD = max(0, ground.stonesD ./ ground.saturation_stones  - void_space); %real space
ground.D = ground.D + stones_overD;  %real space
void_space = void_space - stones_underD.* ground.saturation_stones + stones_overD .* (1-ground.saturation_stones); %rock space

fines_underD = min(ground.finesD ./ ground.saturation_fines, void_space); %real space
fines_overD = max(0, ground.finesD ./ ground.saturation_fines - void_space); 
%ground.D = ground.D + fines_overD;

% route fines down
space4fines = (void_space - fines_underD) .* ground.saturation_fines; %in "rock space"
for i = size(space4fines,1):-1:2
    j=i-1;
    while space4fines(i,1)>0 && j>0
       go_down = min(space4fines(i,1), 0.9.* ground.finesD(j,1).*ground.saturation_fines); %90% can go down in one timestep, can be made dependent on unfrozen conditions
       ground.finesD(i,1) = ground.finesD(i,1) + go_down;
       ground.finesD(j,1) = ground.finesD(j,1) - go_down;
       space4fines(i,1) = space4fines(i,1) - go_down;
       space4fines(j,1) = space4fines(j,1) + go_down;
       j=j-1;
   end
end

%recalculate
fines_underD = min(ground.finesD ./ ground.saturation_fines, void_space);
fines_overD = max(0, ground.finesD ./ ground.saturation_fines - void_space);
ground.D = ground.D + fines_overD;

ground.porosity = 1-(ground.bedrockD + ground.rocksD + ground.stonesD + ground.finesD) ./ ground.D;
ground.bedrock = ground.bedrockD ./ ground.D;
ground.rocks = ground.rocksD ./ ground.D;
ground.stones = ground.stonesD ./ ground.D;
ground.fines = ground.finesD ./ ground.D;
end


function ground = move_rocks_up(ground, timestep)

%1. move rocks up, stones and fines down 

rocks_upD = ground.move_velocity_rocks .*timestep.* ground.rocks(2:end,1); %in rock space
%route fines down first
fines_downD = min(rocks_upD .* ground.fines(1:end-1,1).* ground.saturation_fines, ground.finesD(1:end-1,1));
volume_left = rocks_upD - fines_downD ./ ground.saturation_fines;
%then stones
stones_downD = min(volume_left .* ground.stones(1:end-1,1) .* ground.saturation_stones, ground.stonesD(1:end-1,1));
volume_left = volume_left - stones_downD ./ ground.saturation_stones;
% the remaining rock volume cannot move, since only rock gets replaced by rock, if everything is rocks, nothing moves anymore
rocks_upD = rocks_upD - volume_left;

ground.rocksD(1:end-1,1) =  ground.rocksD(1:end-1,1) + rocks_upD;
ground.rocksD(2:end,1) =  ground.rocksD(2:end,1) - rocks_upD;

ground.finesD(1:end-1,1) =  ground.finesD(1:end-1,1) - fines_downD;
ground.finesD(2:end,1) =  ground.finesD(2:end,1) + fines_downD;

ground.stonesD(1:end-1,1) =  ground.stonesD(1:end-1,1) - stones_downD;
ground.stonesD(2:end,1) =  ground.stonesD(2:end,1) + stones_downD;

%recalculate state variables

ground.D = ground.bedrockD;

ground.D = ground.D +  ground.rocksD ./ ground.saturation_rocks; %real space
void_space = ground.rocksD ./ ground.saturation_rocks - ground.rocksD; %rock space, meter of free spce that can be filled

stones_underD = min(ground.stonesD ./ ground.saturation_stones, void_space); % real space
stones_overD = max(0, ground.stonesD ./ ground.saturation_stones  - void_space); %real space
ground.D = ground.D + stones_overD;  %real space
void_space = void_space - stones_underD.* ground.saturation_stones + stones_overD .* (1-ground.saturation_stones); %rock space

%recalculate
fines_underD = min(ground.finesD ./ ground.saturation_fines, void_space);
fines_overD = max(0, ground.finesD ./ ground.saturation_fines - void_space);
ground.D = ground.D + fines_overD;

ground.porosity = 1-(ground.bedrockD + ground.rocksD + ground.stonesD + ground.finesD) ./ ground.D;
ground.bedrock = ground.bedrockD ./ ground.D;
ground.rocks = ground.rocksD ./ ground.D;
ground.stones = ground.stonesD ./ ground.D;
ground.fines = ground.finesD ./ ground.D;

end


function ground = move_stones_up(ground, timestep)
%2. move stones up, fines down


stones_upD = ground.move_velocity_stones .* timestep .* ground.stones(2:end,1); %in stone space
%route fines down
fines_downD = min(stones_upD .* ground.fines(1:end-1,1).* ground.saturation_fines, ground.finesD(1:end-1,1));
volume_left = stones_upD - fines_downD ./ ground.saturation_fines;

% the remaining stone volume cannot move, since only rock gets replaced by rock, if everything is rocks, nothing moves anymore
stones_upD = stones_upD - volume_left;

ground.stonesD(1:end-1,1) =  ground.stonesD(1:end-1,1) + stones_upD;
ground.stonesD(2:end,1) =  ground.stonesD(2:end,1) - stones_upD;

ground.finesD(1:end-1,1) =  ground.finesD(1:end-1,1) - fines_downD;
ground.finesD(2:end,1) =  ground.finesD(2:end,1) + fines_downD;

%recalculate state variables

ground.D = ground.bedrockD;

ground.D = ground.D +  ground.rocksD ./ ground.saturation_rocks; %real space
void_space = ground.rocksD ./ ground.saturation_rocks - ground.rocksD; %rock space, meter of free spce that can be filled

stones_underD = min(ground.stonesD ./ ground.saturation_stones, void_space); % real space
stones_overD = max(0, ground.stonesD ./ ground.saturation_stones  - void_space); %real space
ground.D = ground.D + stones_overD;  %real space
void_space = void_space - stones_underD.* ground.saturation_stones + stones_overD .* (1-ground.saturation_stones); %rock space

%recalculate
fines_underD = min(ground.finesD ./ ground.saturation_fines, void_space);
fines_overD = max(0, ground.finesD ./ ground.saturation_fines - void_space);
ground.D = ground.D + fines_overD;

ground.porosity = 1-(ground.bedrockD + ground.rocksD + ground.stonesD + ground.finesD) ./ ground.D;
ground.bedrock = ground.bedrockD ./ ground.D;
ground.rocks = ground.rocksD ./ ground.D;
ground.stones = ground.stonesD ./ ground.D;
ground.fines = ground.finesD ./ ground.D;

end










