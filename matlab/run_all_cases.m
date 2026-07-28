% Run all MATLAB cases
% 运行全部 MATLAB 算例

clear; clc; close all;
addpath(fileparts(mfilename('fullpath')));

disp('Running photovoltaic case...');
photovoltaic_case;

disp('Running wind farm case...');
wind_farm_case;

disp('All cases finished.');
