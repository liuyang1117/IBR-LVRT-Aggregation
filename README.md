# IBR-LVRT-Aggregation-Cases  
# 逆变器型电源低电压穿越聚合等值算例

## Overview / 项目简介

This repository provides MATLAB implementations for low-voltage ride-through (LVRT) aggregation and error decomposition of inverter-based resource (IBR) clusters.

本仓库提供两个 MATLAB 算例，用于研究逆变器型电源集群在低电压穿越过程中的聚合等值、电流响应对比和误差分解。

The repository contains two main cases:

本仓库包含两个主算例：

| File | Case | Description |
|---|---|---|
| `matlab/photovoltaic_case.m` | Photovoltaic case / 光伏算例 | Six PV units connected to a 10.5 kV network |
| `matlab/wind_farm_case.m` | Wind farm case / 风电场算例 | Twelve wind turbines connected to a 66 kV collection network |

Both cases build a detailed multi-unit model, construct an aggregated equivalent model, solve the PCC current response over a voltage sweep, and compare the original and aggregated models.

两个算例都会构建详细多机模型、聚合等值模型，并扫描并网点电压，比较原始详细模型与等值模型的并网点电流响应。

---

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
  - voltage-dispersion error / 电压分散误差 `e_vd`
  - function-structure error / 函数结构误差 `e_fs`
  - total aggregation error / 总聚合误差 `e`

- Branch-adaptive approximation  
  分支自适应近似：


- Propagation-operator and condition-number analysis  
  传播算子范数和条件数分析

- Publication-style figures  
  论文风格图像绘制

---

## Repository Structure / 仓库结构

```text
IBR-LVRT-Aggregation-Cases/
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
│   └── case_parameters.csv
├── docs/
│   ├── code_section_map.md
│   ├── model_description.md
│   └── function_reference.md
├── examples/
│   └── run_example.md
├── results/
│   └── README.md
└── tests/
    └── smoke_test.m
```

---

## Requirements / 运行环境

The code requires MATLAB and Optimization Toolbox.

本代码需要 MATLAB 和 Optimization Toolbox。

```text
MATLAB R2020b or later
Optimization Toolbox
```

The nonlinear network equations are solved using `fsolve`.

程序使用 `fsolve` 求解非线性网络方程。

---

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

---

## Case Parameters / 算例参数

| Case | Voltage base | Unit count | Capacity vector | Priority |
|---|---:|---:|---|---|
| Photovoltaic case | 10.5 kV | 6 | `[2;4;2;4;2;2]` MW | q_first |
| Wind farm case | 66 kV | 12 | `[2;4;2;4;2;2;2;4;2;4;2;2]` MW | q_first |

The parameter summary is also available in:

参数汇总见：

```text
data/case_parameters.csv
```

---

## Notes / 注意事项

1. The scripts are self-contained MATLAB function files. Subfunctions such as network construction, IBR current models, trip iteration, Jacobian calculation, and plotting utilities are included in the same `.m` files.

   两个主程序均为自包含函数文件，网络构建、电流模型、脱网迭代、雅可比计算和绘图等子函数均放在同一个 `.m` 文件中。

2. The photovoltaic and wind farm cases share the same modeling framework but use different voltage bases, unit numbers, current-limit settings, and LVRT control parameters.

   光伏算例和风电场算例采用相同的建模框架，但电压基准、设备数量、电流限幅和低穿控制参数不同。

3. The output figures are generated directly by the MATLAB scripts.

   图像由 MATLAB 脚本直接生成。

---

## Citation / 引用

If this repository supports your research, please cite the associated paper or this repository using `CITATION.cff`.

如果本仓库对你的研究有帮助，请引用相关论文或使用 `CITATION.cff` 中的信息。

---

## License / 开源协议

This repository is released under the MIT License.

本仓库采用 MIT License 开源协议。

## Model Address / 模型地址

The complete CloudPSS models are available in this repository:

完整的 CloudPSS 模型代码可在本仓库中获取：

```text
https://github.com/liuyang1117/IBR-LVRT-Aggregation
