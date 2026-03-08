%% make_dictionary_01.m
% Create data dictionary and register ACC parameters as Simulink.Parameter.

thisFile = mfilename('fullpath');
if isempty(thisFile)
    st = dbstack('-completenames');
    thisFile = st(1).file;
end
repoRoot = fileparts(fileparts(thisFile));
dictPath = fullfile(repoRoot, 'data', 'acc_params.sldd');

try
    Simulink.data.dictionary.closeAll('-discard');
catch
    Simulink.data.dictionary.closeAll;
end

if exist(dictPath, 'file')
    delete(dictPath);
end

dictObj = Simulink.data.dictionary.create(dictPath);
dData = getSection(dictObj, 'Design Data');

params = {
    'Ts',         0.05;
    'dt',         0.05;   % compatibility alias for scripts/scenarios
    'StopTime',   60;
    'vSet',       25;
    'd0',         8;
    'time_gap',   1.4;
    'Kv',         0.5;
    'Kgap',       0.25;
    'Kdv',        0.6;
    'd_switch',   32;
    'amin',      -3.5;
    'amax',       2.0;
    'vE0',       20;
    'd_init',    40;
    % legacy names kept for backwards override compatibility
    'Th',         1.4;
    'Kv_free',    0.5;
    'Kd',         0.25;
    'Kv_rel',     0.6;
    'aMin',      -3.5;
    'aMax',       2.0;
    'jMax',       1.5;
    'dDetectOn', 32;
    'dDetectOff',36;
    'dEmergency',10;
    };

for i = 1:size(params,1)
    name = params{i,1};
    val  = params{i,2};
    p = Simulink.Parameter(val);
    p.DataType = 'double';
    try
        p.CoderInfo.StorageClass = 'ExportedGlobal';
    catch
    end
    addEntry(dData, name, p);
end

saveChanges(dictObj);
close(dictObj);

fprintf('[01_make_dictionary] created: %s\n', dictPath);
