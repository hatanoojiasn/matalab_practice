%% run_all.m
% One-shot execution: setup -> dictionary -> model -> MILS -> codegen

thisFile = mfilename('fullpath');
if isempty(thisFile)
    st = dbstack('-completenames');
    thisFile = st(1).file;
end
repoRoot = fileparts(fileparts(thisFile));

% Ensure helper functions in scripts/ are callable from any cwd.
addpath(fullfile(repoRoot, 'scripts'));

% Auto-fix legacy/invalid MATLAB filenames if a bad merge restored them.
legacyMap = {
    fullfile(repoRoot, 'scripts', '00_setup.m'), fullfile(repoRoot, 'scripts', 'setup_00.m')
    fullfile(repoRoot, 'scripts', '01_make_dictionary.m'), fullfile(repoRoot, 'scripts', 'make_dictionary_01.m')
    fullfile(repoRoot, 'scripts', '02_make_model.m'), fullfile(repoRoot, 'scripts', 'make_model_02.m')
    fullfile(repoRoot, 'scripts', '04_codegen.m'), fullfile(repoRoot, 'scripts', 'codegen_04.m')
    };
for i = 1:size(legacyMap, 1)
    oldPath = legacyMap{i, 1};
    newPath = legacyMap{i, 2};
    if exist(oldPath, 'file') && ~exist(newPath, 'file')
        movefile(oldPath, newPath, 'f');
        fprintf('[run_all] renamed legacy script: %s -> %s\n', oldPath, newPath);
    end
end

scriptList = {
    fullfile(repoRoot, 'scripts', 'setup_00.m')
    fullfile(repoRoot, 'scripts', 'make_dictionary_01.m')
    fullfile(repoRoot, 'scripts', 'make_model_02.m')
    fullfile(repoRoot, 'scripts', 'run_mils.m')
    fullfile(repoRoot, 'scripts', 'codegen_04.m')
    };

% Defensive cleanup for corporate copy/paste workflows.
for i = 1:numel(scriptList)
    if zz_sanitize_mfile(scriptList{i})
        fprintf('[run_all] sanitized file: %s\n', scriptList{i});
    end
end

% Lightweight session cleanup so rerun is deterministic.
if bdIsLoaded('acc_mils')
    close_system('acc_mils', 0);
end
try
    Simulink.data.dictionary.closeAll('-discard');
catch
    try
        Simulink.data.dictionary.closeAll;
    catch
    end
end
if evalin('base', 'exist(''vL_ts'',''var'')')
    evalin('base', 'clear vL_ts');
end
if evalin('base', 'exist(''vE_log'',''var'')')
    evalin('base', 'clear vE_log');
end
if evalin('base', 'exist(''d_log'',''var'')')
    evalin('base', 'clear d_log');
end
if evalin('base', 'exist(''aCmd_log'',''var'')')
    evalin('base', 'clear aCmd_log');
end

run(scriptList{1});
run(scriptList{2});
run(scriptList{3});
run_mils();
run(scriptList{5});

fprintf('[run_all] all steps completed.\n');
