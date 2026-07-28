# IBR-LVRT-Aggregation

逆变器型电源低电压穿越聚合等值

## Overview / 项目简介

This repository provides MATLAB implementations for studying the low-voltage ride-through (LVRT) aggregation of inverter-based resource (IBR) clusters. The main objective is to investigate under what conditions the LVRT response of an IBR cluster can be exactly reproduced by one equivalent unit.

本仓库提供用于研究逆变器型电源（IBR）集群低电压穿越（LVRT）聚合等值问题的 MATLAB 算例。其核心目标是分析在什么条件下，一个 IBR 集群的低穿响应能够由一个等值单元精确复现。

The theoretical framework derives the necessary and sufficient conditions for exact aggregation and identifies two independent sources that may prevent exact aggregation: the Common-Voltage-Reduction Error and the Admissible-Law-Approximation Error.

该理论框架推导了精确聚合的充要条件，并指出导致无法精确聚合的两个独立误差来源：同电压压缩误差和允许函数类近似误差。

When exact aggregation is not possible, the aggregation error is decomposed into two components: Common-Voltage-Reduction Error and Admissible-Law-Approximation Error. In the MATLAB codes, these two components are denoted by `ecv` and `eal`, respectively.

当无法实现精确聚合时，聚合误差被分解为同电压压缩误差和允许函数类近似误差。在 MATLAB 程序中，这两项分别统一记为 `ecv` 和 `eal`。

In addition to the MATLAB algebraic simulations, the corresponding case studies were also implemented on the CloudPSS electromagnetic-transient (EMT) simulation platform. The EMT results are used to validate the effectiveness of the theoretical analysis and MATLAB numerical results.

除 MATLAB 代数模型仿真外，本文还在 CloudPSS 电磁暂态仿真平台上搭建了对应算例模型，并通过电磁暂态结果验证理论分析和 MATLAB 数值结果的有效性。

## Model Address / 模型地址

The complete CloudPSS models are available at:

完整的 CloudPSS 模型可在以下地址获取：

```text
https://cloudpss.net/model/liuyang/CaseI-a
https://cloudpss.net/model/liuyang/CaseI-b
https://cloudpss.net/model/liuyang/CaseII
https://cloudpss.net/model/liuyang/CaseIII
https://cloudpss.net/model/liuyang/CaseIV
```

## Main Cases / 主算例

| File | Case | Description |
|---|---|---|
| `matlab/photovoltaic_case.m` | Photovoltaic case / 光伏算例 | Six PV units connected to a 10.5 kV network |
| `matlab/wind_farm_case.m` | Wind farm case / 风电场算例 | Twelve wind turbines connected to a 66 kV collection network |

Both cases build a detailed multi-unit model, construct an aggregated equivalent model, solve the PCC current response over a voltage sweep, and compare the original and aggregated models.

两个算例都会构建详细多机模型、聚合等值模型，并扫描并网点电压，比较原始详细模型与等值模型的并网点电流响应。


## Terminology / 术语说明

This repository uses the following error names consistently in the MATLAB code, documents, examples, and result descriptions.

本仓库在 MATLAB 代码、文档、示例和结果说明中统一采用以下误差名称。

| Symbol | English name | Chinese name | Meaning | 中文说明 |
|---|---|---|---|---|
| `ecv` / `e_cv` | Common-Voltage-Reduction Error | 同电压压缩误差 | Error introduced when the detailed internal terminal voltages are reduced to a common-voltage representation. | 将详细模型中的多个内部端电压压缩为同一个公共电压表示时产生的误差。 |
| `eal` / `e_al` | Admissible-Law-Approximation Error | 允许函数类近似误差 | Error introduced when the summed heterogeneous LVRT current laws are approximated by an admissible equivalent law. | 将异质低穿电流控制律求和后的结果，用一个允许的等值函数类近似时产生的误差。 |

## Main Features / 主要功能

- Network admittance matrix construction  
  系统导纳矩阵构建

- Detailed multi-unit IBR model  
  多台逆变器型电源详细模型

- Aggregated equivalent network model  
  聚合等值网络模型

- Trip logic under LVRT  
  低电压穿越过程中的脱网逻辑

- Common-voltage intermediate model  
  公共电压中间模型

- Error decomposition  
  误差分解：

  - `ecv` / `e_cv`: Common-Voltage-Reduction Error / 同电压压缩误差
  - `eal` / `e_al`: Admissible-Law-Approximation Error / 允许函数类近似误差
  - `etot`: total aggregation error / 总聚合误差

- Branch-adaptive approximation for `ecv` and `eal`  
  针对 `ecv` 和 `eal` 的分支自适应近似

- Propagation-operator and condition-number analysis  
  传播算子范数和条件数分析

- Publication-style figures  
  论文风格图像绘制

## Repository Structure / 仓库结构

```text
IBR-LVRT-Aggregation/
├── README.md
├── LICENSE
├── CITATION.cff
├── .gitignore
├── matlab/
│   ├── photovoltaic_case.m
│   ├── wind_farm_case.m
│   ├── run_photovoltaic_case.m
│   ├── run_wind_farm_case.m
│   └── run_all_cases.m
├── data/
│   ├── README.md
│   ├── case_study_summary.csv
│   ├── pv_benchmark_control_parameters.csv
│   ├── wind_farm_caseiv_control_parameters.csv
│   ├── global_settings_and_voltage_levels.csv
│   └── code_case_mapping.csv
├── docs/
│   ├── README.md
│   ├── model_description.md
│   ├── case_description.md
│   ├── parameter_description.md
│   ├── figure_outputs.md
│   ├── terminology.md
│   ├── update_notes_ecv_eal.md
│   ├── reproduction_guide.md
│   ├── code_section_map.md
│   └── function_reference.md
├── examples/
│   ├── README.md
│   ├── run_example.md
│   ├── photovoltaic_case_example.md
│   ├── wind_farm_case_example.md
│   └── result_check_example.md
├── results/
│   ├── README.md
│   ├── expected_outputs.md
│   ├── result_variables.md
│   ├── figure_naming_rule.md
│   ├── photovoltaic_case/
│   ├── wind_farm_case/
│   └── summary/
└── tests/
    └── smoke_test.m
```

## Requirements / 运行环境

The code requires MATLAB and Optimization Toolbox.

本代码需要 MATLAB 和 Optimization Toolbox。

- MATLAB R2020b or later
- Optimization Toolbox

The nonlinear network equations are solved using `fsolve`.

程序使用 `fsolve` 求解非线性网络方程。

## Quick Start / 快速开始

Open MATLAB in the repository root directory and run:

在仓库根目录打开 MATLAB，运行：

```matlab
addpath('matlab');
photovoltaic_case;
```

or:

或者：

```matlab
addpath('matlab');
wind_farm_case;
```

Run both cases:

运行两个算例：

```matlab
addpath('matlab');
run_all_cases;
```

## Case Parameters / 算例参数

| Case | Voltage base | Unit count | Capacity vector | Control type vector | Priority |
|---|---:|---:|---|---|---|
| Photovoltaic case / 光伏算例 | 10.5 kV | 6 | `[2;4;2;4;2;2]` MW | `[1;1;1;2;2;2]` | `q_first` |
| Wind farm case / 风电场算例 | 66 kV | 12 | `[2;4;2;4;2;2;2;4;2;4;2;2]` MW | `[1;2;1;2;1;1;1;2;1;2;1;1]` | `q_first` |

The parameter summary is also available in:

参数汇总见：

```text
data/
```

## Updated Naming / 更新后的变量命名

The updated MATLAB codes use the following unified names:

更新后的 MATLAB 程序统一采用以下变量名：

| Symbol / variable | Meaning | 中文含义 |
|---|---|---|
| `ecv` | common-voltage / Common-Voltage-Reduction Error | 同电压压缩误差 |
| `eal` | Admissible-Law-Approximation Error | 允许函数类近似误差 |
| `^ecv` | approximation of `ecv` | `ecv` 的近似值 |
| `^eal` | approximation of `eal` | `eal` 的近似值 |

## Notes / 注意事项

The scripts are self-contained MATLAB function files. Subfunctions such as network construction, IBR current models, trip iteration, Jacobian calculation, and plotting utilities are included in the same `.m` files.

两个主程序均为自包含函数文件，网络构建、电流模型、脱网迭代、雅可比计算和绘图等子函数均放在同一个 `.m` 文件中。

The output figures are generated directly by the MATLAB scripts. The updated wind-farm code includes additional figures for approximation residuals and d/q component analysis.

图像由 MATLAB 脚本直接生成。更新后的风电场程序额外增加了近似残差和 d/q 分解相关图像。

## Citation / 引用

If this repository supports your research, please cite the associated paper or this repository using `CITATION.cff`.

如果本仓库对你的研究有帮助，请引用相关论文或使用 `CITATION.cff` 中的信息。

## License / 开源协议

This repository is released under the MIT License.

本仓库采用 MIT License 开源协议。
