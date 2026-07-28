# Wind Farm Case Example / 风电场算例示例

## Purpose / 目的

This example runs the offshore wind farm LVRT aggregation case.

本示例用于运行海上风电场低电压穿越聚合等值算例。

The case contains:

该算例包含：

```text
12 wind turbines
66 kV collector network
Two turbine types
Reactive-current support
Reactive-current-priority current limiting
```

```text
12 台风机
66 kV 集电网络
两类风机
无功电流支撑
无功优先电流限幅
```

---

## MATLAB Commands / MATLAB 命令

Run the following commands in MATLAB:

在 MATLAB 中运行：

```matlab
clear;
clc;
close all;

addpath('matlab');
wind_farm_case;
```

---

## Key Parameters / 关键参数

```matlab
Sbase_MVA = 100;
Vbase_kV  = 66.0;

s = [2;4;2;4;2;2;2;4;2;4;2;2];
ctrlType = [1;2;1;2;1;1;1;2;1;2;1;1];
```

The two turbine types are:

两类风机为：

| Type | kq | Imax | voff | Turbine indices |
|---|---:|---:|---:|---|
| Type-A | 2.7 | 1.1 | 0.4 | 1, 3, 5, 6, 7, 9, 11, 12 |
| Type-B | 2.2 | 1.0 | 0.3 | 2, 4, 8, 10 |

---

## Expected Figures / 预期图像

The script generates figures such as:

程序会生成以下图像：

- PCC current comparison  
  并网点电流对比图

- Aggregation error decomposition  
  聚合误差分解图

- d/q decomposition of current or error terms  
  电流或误差项的 d/q 分解图

- Propagation-operator norm curves  
  传播算子范数曲线

- Terminal-voltage curves of all wind turbines  
  各风机端电压曲线

---

## Interpretation / 结果解释

If the Admissible-Law-Approximation Error `e_al` is dominant, the aggregation error mainly comes from approximating the aggregated response within the admissible equivalent law class.

如果允许函数类近似误差 `e_al` 占主导，说明聚合误差主要来自允许等值函数类对聚合响应的近似。

If the Common-Voltage-Reduction Error `e_cv` is dominant, the aggregation error mainly comes from reducing the detailed multi-terminal voltage model to a common-voltage representation.

如果同电压压缩误差 `e_cv` 占主导，说明聚合误差主要来自将多端电压模型压缩为同一公共电压表示。
