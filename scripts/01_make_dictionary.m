%% 01_make_dictionary.m
% Create data dictionary and register ACC parameters as Simulink.Parameter.

thisFile = mfilename('fullpath');
if isempty(thisFile)
    st = dbstack('-completenames');
    thisFile = st(1).file;
end
repoRoot = fileparts(fileparts(thisFile));
dictPath = fullfile(repoRoot, 'data', 'acc_params.sldd');

if exist(dictPath, 'file')
    delete(dictPath);
end

dictObj = Simulink.data.dictionary.create(dictPath);
dData = getSection(dictObj, 'Design Data');

params = {
    'dt',         0.05;
    'StopTime',   60;
    'vSet',       25;
    'Th',         1.4;
    'd0',         8;
    'Kv_free',    0.5;
    'Kd',         0.25;
    'Kv_rel',     0.6;
    'aMin',      -3.5;
    'aMax',       2.0;
    'jMax',       1.5;
    'dDetectOn', 32;
    'dDetectOff',36;
    'dEmergency',10;
    'vE0',       20;
    'd_init',    40;
    };

for i = 1:size(params,1)
    name = params{i,1};
    val  = params{i,2};
    p = Simulink.Parameter(val);
    p.DataType = 'double';
    p.Min = -inf;
    p.Max = inf;
    try
        p.CoderInfo.StorageClass = 'ExportedGlobal';
    catch
        % If storage class cannot be set in this environment, keep default.
    end
    addEntry(dData, name, p);
end

saveChanges(dictObj);
close(dictObj);

fprintf('[01_make_dictionary] created: %s\n', dictPath);
