# Code Section Map / 代码分段说明

This document maps the main code sections to their modeling purposes.

本文档说明主程序各代码段对应的建模功能。

---

## Photovoltaic Case / 光伏算例

Main file:

主文件：

```text
matlab/photovoltaic_case.m
```

| Section | Code title | Purpose | 中文说明 |
|---|---|---|---|
| 0 | Per-unit base-value settings | Base-value settings | 设置系统容量、电压和电流基准。 |
| 1 | Construct the system admittance matrix Y | Network admittance matrix | 构造网络节点导纳矩阵。 |
| 2 | PV capacity settings | Capacity settings | 设置设备容量向量和总容量。 |
| 3 | PV control-type settings | Control-type settings | 设置各设备的控制类型。 |
| 4 | Admittance-matrix partitioning | Admittance-matrix partitioning | 将导纳矩阵分成 PCC 和内部节点相关分块。 |
| 5 | Construct the equivalent admittance matrix Yeq | Equivalent admittance matrix | 构造聚合等值导纳矩阵。 |
| 6 | Detailed-model PV control parameters | Detailed-model control parameters | 设置详细模型电流指令、限幅值和低穿阈值。 |
| 7 | Detailed-model tripping-iteration parameters | Tripping-iteration parameters | 设置脱网迭代相关参数。 |
| 8 | Equivalent PV parameters | Equivalent-model parameters | 设置等值模型容量权重、限幅和阈值。 |
| 9 | Sweep the PCC voltage | PCC voltage sweep | 扫描并网点电压。 |
| 10 | fsolve solver settings | fsolve settings | 设置非线性求解器。 |
| 11 | Solve the detailed model, equivalent model, and common-voltage model | Model solving loop | 循环求解详细模型、等值模型和公共电压模型。 |
| 12 | Sort by voltage in ascending order | Data sorting | 按电压从小到大排序。 |
| 13 | Current conversion | Current conversion | 进行电流标幺和三相口径换算。 |
| 15 | Plotting | Plotting | 绘制模型对比、误差分解和传播算子图。 |
| 15.1 | Aggregation error decomposition | Code block | 代码功能段。 |
| 16 | Save results to the workspace | Save results | 保存结果到工作区。 |

---

## Wind Farm Case / 风电场算例

Main file:

主文件：

```text
matlab/wind_farm_case.m
```

| Section | Code title | Purpose | 中文说明 |
|---|---|---|---|
| 0 | Per-unit base values | Base-value settings | 设置系统容量、电压和电流基准。 |
| 1 | Construct the admittance matrix | Network admittance matrix | 构造网络节点导纳矩阵。 |
| 2 | Wind-turbine/PV capacity | Capacity settings | 设置设备容量向量和总容量。 |
| 3 | Control type | Control-type settings | 设置各设备的控制类型。 |
| 4 | Admittance-matrix partitioning | Admittance-matrix partitioning | 将导纳矩阵分成 PCC 和内部节点相关分块。 |
| 5 | Equivalent admittance matrix Yeq | Equivalent admittance matrix | 构造聚合等值导纳矩阵。 |
| 6 | Detailed-model control parameters | Detailed-model control parameters | 设置详细模型电流指令、限幅值和低穿阈值。 |
| 7 | Tripping-iteration parameters | Tripping-iteration parameters | 设置脱网迭代相关参数。 |
| 8 | Equivalent-model parameters | Equivalent-model parameters | 设置等值模型容量权重、限幅和阈值。 |
| 9 | Sweep the PCC voltage | PCC voltage sweep | 扫描并网点电压。 |
| 10 | fsolve settings | fsolve settings | 设置非线性求解器。 |
| 11 | Solve the detailed model, equivalent model, and common-voltage model | Model solving loop | 循环求解详细模型、等值模型和公共电压模型。 |
| 12 | Sort by voltage in ascending order | Data sorting | 按电压从小到大排序。 |
| 13 | Current conversion | Current conversion | 进行电流标幺和三相口径换算。 |
| 14 | Vp = 1 atvoltage | Voltage information | 输出 Vp=1 时的电压信息。 |
| 15 | Plotting | Plotting | 绘制模型对比、误差分解和传播算子图。 |
| 15.1 | Aggregation error decomposition | Code block | 代码功能段。 |
| 15.2 | Norm of the equivalent-side branch-adaptive propagation operator | Code block | 代码功能段。 |
| 15.3 | d/q decomposition error of delta_{alpha,beta} | Code block | 代码功能段。 |
| 16 | Save results | Save results | 保存结果到工作区。 |

---

## Reading Order / 阅读顺序

For first-time readers, the recommended reading order is:

第一次阅读代码时，建议顺序为：

```text
0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 8 -> 9 -> 11 -> 13 -> 15
```

The error-analysis part is mainly located in:

误差分析相关内容主要位于：

```text
9.1, 9.2, 11, 13, 15
```
