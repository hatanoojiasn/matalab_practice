%% 00_setup.m
% Repository bootstrap: folder creation, path setup, and dependency checks.

thisFile = mfilename('fullpath');
if isempty(thisFile)
    st = dbstack('-completenames');
    thisFile = st(1).file;
end
repoRoot = fileparts(fileparts(thisFile));

requiredDirs = {'model', 'data', 'scripts', 'results', 'build', 'scenarios'};
for i = 1:numel(requiredDirs)
    p = fullfile(repoRoot, requiredDirs{i});
    if ~exist(p, 'dir')
        mkdir(p);
    end
end

addpath(repoRoot);
addpath(fullfile(repoRoot, 'scripts'));
addpath(fullfile(repoRoot, 'model'));
addpath(fullfile(repoRoot, 'data'));
addpath(fullfile(repoRoot, 'scenarios'));

fprintf('[00_setup] repoRoot: %s\n', repoRoot);
fprintf('[00_setup] Simulink license: %d\n', license('test','Simulink'));
fprintf('[00_setup] Simulink Coder license: %d\n', license('test','Simulink_Coder'));
