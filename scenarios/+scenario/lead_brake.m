function sc = lead_brake(dt, StopTime, overrides)
% scenario.lead_brake
% 0-20s:25m/s, 20-30s:15m/s, 30-end:22m/s

if nargin < 3
    overrides = struct();
end

N = floor(StopTime / dt) + 1;
t = (0:N-1)' * dt;
vL = 22 * ones(N,1);
vL(t < 20) = 25;
vL(t >= 20 & t < 30) = 15;
vL(t >= 30) = 22;

if isfield(overrides, 'vL_scale')
    vL = vL .* overrides.vL_scale;
end

sc.vL_ts = timeseries(vL, t);
end
