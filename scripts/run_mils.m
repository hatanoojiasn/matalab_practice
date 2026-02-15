function simOut = run_mils(overrides)
% run_mils Run MILS simulation and save plots.
% Usage:
%   run_mils()
%   run_mils(struct('vSet',27,'Th',1.2,'scenario','lead_brake'))

if nargin < 1
    overrides = struct();
end

thisFile = mfilename('fullpath');
repoRoot = fileparts(fileparts(thisFile));
modelName = 'acc_mils';
modelPath = fullfile(repoRoot, 'model', [modelName '.slx']);
dictPath = fullfile(repoRoot, 'data', 'acc_params.sldd');
resultsDir = fullfile(repoRoot, 'results');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

if ~exist(dictPath, 'file')
    run(fullfile(repoRoot, 'scripts', '01_make_dictionary.m'));
end
if ~exist(modelPath, 'file')
    run(fullfile(repoRoot, 'scripts', '02_make_model.m'));
end

addpath(repoRoot);
addpath(fullfile(repoRoot, 'scenarios'));

if ~bdIsLoaded(modelName)
    load_system(modelPath);
end

baseVals = localReadParams(dictPath, {'dt','StopTime'});
if isfield(overrides, 'dt')
    dt = overrides.dt;
else
    dt = baseVals.dt;
end
if isfield(overrides, 'StopTime')
    stopTimeVal = overrides.StopTime;
else
    stopTimeVal = baseVals.StopTime;
end

if isfield(overrides, 'scenario')
    scenarioName = char(overrides.scenario);
else
    scenarioName = 'lead_brake';
end

scFcn = str2func(['scenario.' scenarioName]);
sc = scFcn(dt, stopTimeVal, overrides);

simIn = Simulink.SimulationInput(modelName);
simIn = simIn.setModelParameter('StopTime', num2str(stopTimeVal));
simIn = simIn.setVariable('vL_ts', sc.vL_ts);

fields = fieldnames(overrides);
for i = 1:numel(fields)
    key = fields{i};
    if strcmp(key, 'scenario')
        continue;
    end
    simIn = simIn.setVariable(key, overrides.(key));
end

simOut = sim(simIn);

vE_log = simOut.get('vE_log');
d_log = simOut.get('d_log');
aCmd_log = simOut.get('aCmd_log');

localSavePlot(vE_log.time, vE_log.signals.values, 'Ego Speed vE [m/s]', fullfile(resultsDir, 'speed.png'));
localSavePlot(d_log.time, d_log.signals.values, 'Gap d [m]', fullfile(resultsDir, 'distance.png'));
localSavePlot(aCmd_log.time, aCmd_log.signals.values, 'Command Accel aCmd [m/s^2]', fullfile(resultsDir, 'accel.png'));

fprintf('[run_mils] Completed. scenario=%s, PNG saved in %s\n', scenarioName, resultsDir);

end

function out = localReadParams(dictPath, keys)
out = struct();
d = Simulink.data.dictionary.open(dictPath);
sec = getSection(d, 'Design Data');
for i = 1:numel(keys)
    k = keys{i};
    entryObj = getEntry(sec, k);
    p = getValue(entryObj);
    out.(k) = p.Value;
end
close(d);
end

function localSavePlot(t, y, yLabel, outPath)
f = figure('Visible', 'off');
plot(t, y, 'LineWidth', 1.5);
grid on;
xlabel('Time [s]');
ylabel(yLabel);
title(yLabel);
saveas(f, outPath);
close(f);
end
