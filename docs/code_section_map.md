# Code Section Map / 代码分段说明

This document summarizes the major code blocks in `photovoltaic_case.m` and `wind_farm_case.m`.

本文档说明 `photovoltaic_case.m` 和 `wind_farm_case.m` 的主要代码段。

## Common framework / 公共框架

Both scripts follow the same overall workflow:

两个程序采用相同的整体流程：

| Section | Purpose | 中文说明 |
|---|---|---|
| 0 | Base-value definition | 设置容量、电压、电流标幺基准 |
| 1 | Network admittance matrix construction | 构造系统导纳矩阵 `Y` |
| 2 | Unit capacity definition | 设置光伏/风机容量向量 `s` |
| 3 | Control type definition | 设置控制类型 `ctrlType` |
| 4 | Admittance matrix partition | 将 `Y` 分块为 `Ypp`, `YpI`, `YIp`, `YII` |
| 5 | Equivalent admittance matrix | 构造聚合等值网络 `Yeq` |
| 6 | Detailed unit control parameters | 设置详细模型控制参数 |
| 7 | Trip-iteration parameters | 设置脱网迭代参数 |
| 8 | Aggregated equivalent parameters | 设置等值模型参数 |
| 9 | PCC voltage sweep | 扫描并网点电压 |
| 9.1 | Common-voltage model variables | 定义公共电压模型与误差分解变量 |
| 9.2 | Function-structure error variables | 定义函数结构误差近似变量 |
| 10 | `fsolve` options | 设置非线性求解器 |
| 11 | Model solution loop | 逐点求解详细模型、等值模型和公共电压模型 |
| 12 | Data sorting | 按电压从小到大排序 |
| 13 | Current conversion | 电流标幺和三相口径换算 |
| 13.1 | d/q error decomposition | 对误差项进行 d/q 分解 |
| 14 | Voltage check at `Vp = 1` | 输出额定点电压和状态检查 |
| 15 | Figures | 绘制电流、误差、条件数、传播算子和电压图 |

## Photovoltaic case / 光伏算例

File:

```text
matlab/photovoltaic_case.m
```

Main characteristics:

- voltage base: 10.5 kV
- controller voltage base: 10.0 kV
- six PV units
- capacity vector: `[2;4;2;4;2;2]` MW
- control type vector: `[1;1;1;2;2;2]`
- current-limiting priority: `q_first`

## Wind farm case / 风电场算例

File:

```text
matlab/wind_farm_case.m
```

Main characteristics:

- voltage base: 66 kV
- controller voltage base: 66 kV
- twelve wind turbines
- capacity vector: `[2;4;2;4;2;2;2;4;2;4;2;2]` MW
- control type vector: `[1;2;1;2;1;1;1;2;1;2;1;1]`
- current-limiting priority: `q_first`

## Main outputs / 主要输出

The scripts produce:

- PCC current curves for original, common-voltage, and aggregated models
- aggregation error curves
- voltage-dispersion error approximation
- function-structure error approximation
- branch mismatch count
- condition-number curves
- propagation-operator norm curves
- d/q decomposition curves
- unit terminal voltage curves
