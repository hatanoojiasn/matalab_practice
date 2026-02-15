%% run_all.m
% One-shot execution: setup -> dictionary -> model -> MILS -> codegen

thisFile = mfilename('fullpath');
if isempty(thisFile)
    st = dbstack('-completenames');
    thisFile = st(1).file;
end
repoRoot = fileparts(fileparts(thisFile));

run(fullfile(repoRoot, 'scripts', '00_setup.m'));
run(fullfile(repoRoot, 'scripts', '01_make_dictionary.m'));
run(fullfile(repoRoot, 'scripts', '02_make_model.m'));
run_mils();
run(fullfile(repoRoot, 'scripts', '04_codegen.m'));

fprintf('[run_all] all steps completed.\n');
