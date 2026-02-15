function y = acc_controller_step(vE, d, vL, modePrev, aPrev, dt, vSet, Th, d0, Kv_free, Kd, Kv_rel, aMin, aMax, jMax, dDetectOn, dDetectOff, dEmergency)
% acc_controller_step Controller fallback used by MATLAB Fcn block.

mode = modePrev;
if modePrev == 0
    if d < dDetectOn
        mode = 1;
    end
else
    if d > dDetectOff
        mode = 0;
    end
end

if d < dEmergency
    aRaw = aMin;
else
    if mode == 0
        aRaw = Kv_free * (vSet - vE);
    else
        dRef = d0 + Th * vE;
        aRaw = Kd * (d - dRef) + Kv_rel * (vL - vE);
    end
end

if aRaw > aMax
    aSat = aMax;
elseif aRaw < aMin
    aSat = aMin;
else
    aSat = aRaw;
end

aHi = aPrev + jMax * dt;
aLo = aPrev - jMax * dt;
if aSat > aHi
    aCmd = aHi;
elseif aSat < aLo
    aCmd = aLo;
else
    aCmd = aSat;
end

if aCmd > aMax
    aCmd = aMax;
elseif aCmd < aMin
    aCmd = aMin;
end

y = [aCmd; mode];
