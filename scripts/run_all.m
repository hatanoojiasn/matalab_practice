%% run_all.m
% One-shot execution: setup -> dictionary -> model -> MILS -> codegen

thisFile = mfilename('fullpath');
if isempty(thisFile)
    st = dbstack('-completenames');
    thisFile = st(1).file;
end
repoRoot = fileparts(fileparts(thisFile));

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

run(scriptList{1});
run(scriptList{2});
run(scriptList{3});
run_mils();
run(scriptList{5});

fprintf('[run_all] all steps completed.\n');
