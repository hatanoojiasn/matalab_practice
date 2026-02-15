function sc = cut_in(dt, StopTime, overrides)
% scenario.cut_in
% Initial free flow then abrupt slow lead vehicle cut-in around 18s.

if nargin < 3
    overrides = struct();
end

N = floor(StopTime / dt) + 1;
t = (0:N-1)' * dt;
vL = 27 * ones(N,1);
vL(t >= 18 & t < 28) = 13;
vL(t >= 28) = 21;

if isfield(overrides, 'cutin_time')
    tc = overrides.cutin_time;
    vL = 27 * ones(N,1);
    vL(t >= tc & t < tc + 10) = 13;
    vL(t >= tc + 10) = 21;
end

sc.vL_ts = timeseries(vL, t);
end
