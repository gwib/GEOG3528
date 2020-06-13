function [Tex] = pdd(Tmm,s_stat)
% Tmm = monthly mean temperature
% s_stat is standard deviation, usually used 4.5Deg, overpredicts melt
pdd_sum = 0.0; % start sum at 0
d_time=1/12; % time step is one month
for n=1:12   % month counter
    pdd_sum = pdd_sum + ( s_stat/sqrt(2.*pi)*exp(-0.5*(Tmm(n)/s_stat)^2) ... % continue next line
    + 0.5*Tmm(n)*erfc(-Tmm(n)/s_stat/sqrt(2.)) )*d_time; % positive degree days (in a * deg C)
end

Tex = pdd_sum; % temperature excess   (deg C)