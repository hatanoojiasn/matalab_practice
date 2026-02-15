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

% Hotfix for environments that still carry an old make_model_02.m body.
modelScript = fullfile(repoRoot, 'scripts', 'make_model_02.m');
if exist(modelScript, 'file')
    body = fileread(modelScript);
    if ~isempty(strfind(body, 'OutDataTypeStr'))
        body = strrep(body, ', ''OutDataTypeStr'', ''uint8''', '');
        fid = fopen(modelScript, 'w');
        fwrite(fid, body, 'char');
        fclose(fid);
        fprintf('[run_all] patched stale OutDataTypeStr in %s\n', modelScript);
    end
end

% Defensive cleanup for corporate copy/paste workflows.
for i = 1:numel(scriptList)
    if zz_sanitize_mfile(scriptList{i})
        fprintf('[run_all] sanitized file: %s\n', scriptList{i});
    end
end

run(scriptList{1});
run(scriptList{2});
run(scriptList{3});
run_mils();
run(scriptList{5});

fprintf('[run_all] all steps completed.\n');
