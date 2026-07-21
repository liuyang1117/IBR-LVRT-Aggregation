%% Smoke test for repository structure
% This test checks whether the main MATLAB files exist and are callable by name.
% It does not execute the full nonlinear simulation.

clear; clc;

requiredFiles = {
    fullfile('matlab', 'photovoltaic_case.m')
    fullfile('matlab', 'wind_farm_case.m')
    fullfile('matlab', 'run_photovoltaic_case.m')
    fullfile('matlab', 'run_wind_farm_case.m')
};

for k = 1:numel(requiredFiles)
    assert(exist(requiredFiles{k}, 'file') == 2, ['Missing file: ', requiredFiles{k}]);
end

addpath('matlab');

assert(exist('photovoltaic_case', 'file') == 2, 'photovoltaic_case is not on MATLAB path.');
assert(exist('wind_farm_case', 'file') == 2, 'wind_farm_case is not on MATLAB path.');

disp('Smoke test passed.');
