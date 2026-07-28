# Expected Outputs / 预期输出

This document lists the expected outputs after running the MATLAB cases.

本文档列出运行 MATLAB 算例后预期生成的结果。

---

## Photovoltaic Case / 光伏算例

Run:

运行：

```matlab
addpath('matlab');
photovoltaic_case;
```

Expected figures:

预期图像：

| Output | Description | 中文说明 |
|---|---|---|
| PCC current comparison | Original model vs aggregated model vs EMT points | 原始模型、等值模型和 EMT 点并网点电流对比 |
| Aggregation error decomposition | Total error, Common-Voltage-Reduction Error, and Admissible-Law-Approximation Error | 总误差、同电压压缩误差和允许函数类近似误差分解 |
| Common-Voltage-Reduction approximation | Approximation of `e_cv`, Common-Voltage-Reduction Error | 同电压压缩误差近似 |
| Admissible-Law-Approximation approximation | Approximation of `e_al`, Admissible-Law-Approximation Error | 允许函数类近似误差近似 |
| PV terminal voltages | Terminal-voltage curves of all PV units | 各光伏单元端电压曲线 |

---

## Wind Farm Case / 风电场算例

Run:

运行：

```matlab
addpath('matlab');
wind_farm_case;
```

Expected figures:

预期图像：

| Output | Description | 中文说明 |
|---|---|---|
| PCC current comparison | Original wind farm model vs aggregated model vs EMT points | 原始风电场模型、等值模型和 EMT 点对比 |
| Aggregation error decomposition | `e`, `e_cv`, and `e_al` | 总误差、同电压压缩误差和允许函数类近似误差 |
| d/q decomposition | d-axis and q-axis components of current or error | 电流或误差的 d/q 分量 |
| Propagation operator norm | Norms of `K_vd` and `K_fs` | 同电压压缩和允许函数类近似传播算子范数 |
| Wind turbine terminal voltages | Terminal-voltage curves of all wind turbines | 各风机端电压曲线 |

---

## Suggested File Names / 推荐文件名

```text
photovoltaic_case/pcc_current_comparison.png
photovoltaic_case/aggregation_error_decomposition.png
photovoltaic_case/terminal_voltage_profile.png

wind_farm_case/pcc_current_comparison.png
wind_farm_case/aggregation_error_decomposition.png
wind_farm_case/propagation_operator_norm.png

summary/case_error_summary.csv
```
