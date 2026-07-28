# Photovoltaic Case Example / 光伏算例示例

## Purpose / 目的

This example runs the six-PV LVRT aggregation case.

本示例用于运行六光伏低电压穿越聚合等值算例。

The case contains:

该算例包含：

```text
6 PV units
10.5 kV network voltage base
CP/CC mixed control types
Reactive-current-priority current limiting
```

```text
6 台光伏单元
10.5 kV 网络电压基准
恒功率/恒电流混合控制类型
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
photovoltaic_case;
```

---

## Key Parameters / 关键参数

```matlab
Sbase_MVA = 100;
Vbase_kV  = 10.5;
Vctrl_base_kV = 10.0;

s = [2;4;2;4;2;2];
ctrlType = [1;1;1;2;2;2];

pv.priority = 'q_first';
```

where:

其中：

| Variable | Meaning | 中文含义 |
|---|---|---|
| `s` | PV capacity vector | 光伏容量向量 |
| `ctrlType = 1` | Constant-power control | 恒功率控制 |
| `ctrlType = 2` | Constant-current control | 恒电流控制 |
| `q_first` | Reactive-current priority | 无功优先 |

---

## Expected Figures / 预期图像

The script generates figures such as:

程序会生成以下图像：

- PCC current comparison  
  并网点电流对比图

- Aggregation error decomposition  
  聚合误差分解图

- Common-Voltage-Reduction Error approximation  
  同电压压缩误差近似图

- Admissible-Law-Approximation Error approximation  
  允许函数类近似误差近似图

- PV terminal-voltage curves  
  光伏端电压曲线

---

## Expected Workspace Variable / 预期工作区变量

After running the script, the workspace should contain:

运行结束后，MATLAB 工作区中应包含：

```matlab
result
```

Typical fields include:

典型字段包括：

```matlab
result.Vp_abs
result.H
result.Hc
result.Heq
result.ecv
result.eal
result.etot
```
