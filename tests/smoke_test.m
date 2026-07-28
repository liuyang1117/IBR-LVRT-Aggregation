% Smoke test for repository paths
% 仓库路径简单测试

clear; clc;
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repoRoot, 'matlab'));

assert(exist('photovoltaic_case', 'file') == 2, 'photovoltaic_case.m not found');
assert(exist('wind_farm_case', 'file') == 2, 'wind_farm_case.m not found');

disp('Smoke test passed.');
