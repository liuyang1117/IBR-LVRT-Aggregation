%% Run all example cases
% 依次运行光伏算例和风电场算例。
clear; clc; close all;

fprintf('\n========== Running photovoltaic_case ==========%s', newline);
photovoltaic_case;

fprintf('\n========== Running wind_farm_case ==========%s', newline);
wind_farm_case;
