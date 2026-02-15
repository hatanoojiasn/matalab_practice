%% 04_codegen.m
% Run ACG build (grt target) when Simulink Coder is available.

thisFile = mfilename('fullpath');
if isempty(thisFile)
    st = dbstack('-completenames');
    thisFile = st(1).file;
end
repoRoot = fileparts(fileparts(thisFile));
modelName = 'acc_mils';
modelPath = fullfile(repoRoot, 'model', [modelName '.slx']);

if ~exist(modelPath, 'file')
    run(fullfile(repoRoot, 'scripts', '02_make_model.m'));
end

if ~license('test', 'Simulink_Coder')
    fprintf('[04_codegen] Simulink Coder unavailable. Skip slbuild.\n');
    return;
end

load_system(modelPath);

Simulink.fileGenControl('set', ...
    'CodeGenFolder', fullfile(repoRoot, 'build', 'codegen'), ...
    'CacheFolder', fullfile(repoRoot, 'build', 'cache'), ...
    'createDir', true);

set_param(modelName, 'SystemTargetFile', 'grt.tlc');
slbuild(modelName);

fprintf('[04_codegen] slbuild success for model %s\n', modelName);
