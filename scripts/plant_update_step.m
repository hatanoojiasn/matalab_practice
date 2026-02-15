function y = plant_update_step(vE, d, vL, aCmd, dt)
% plant_update_step Plant fallback used by MATLAB Fcn block.

vE_next = vE + aCmd * dt;
if vE_next < 0
    vE_next = 0;
end

d_next = d + (vL - vE) * dt;
if d_next < 0
    d_next = 0;
end

y = [vE_next; d_next];
