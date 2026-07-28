# Parameter Description / 参数说明

This document explains the main parameters used in the MATLAB cases.

本文档说明 MATLAB 算例中使用的主要参数。

---

## 1. Base Values / 基准值

| Parameter | Meaning | 中文含义 | Typical value |
|---|---|---|---|
| `Sbase_MVA` | System power base | 系统容量基准 | 100 MVA |
| `Vbase_kV` | Network voltage base | 网络电压基准 | 10.5 kV for PV, 66 kV for wind farm |
| `Vctrl_base_kV` | Controller voltage base | 控制电压基准 | 10.0 kV for PV, 66.0 kV for wind farm |
| `Ibase_kA` | Current base | 电流基准 | `Sbase_MVA/(sqrt(3)*Vbase_kV)` |
| `Ilimit_base_ratio` | Current-limit conversion factor | 限幅基准换算系数 | `Vbase_kV/Vctrl_base_kV` |

---

## 2. Capacity and Control Type / 容量与控制类型

| Parameter | Meaning | 中文含义 |
|---|---|---|
| `s` | Device capacity vector | 设备容量向量 |
| `Ssum` | Total capacity | 总容量 |
| `ctrlType` | Control type vector | 控制类型向量 |
| `ctrlType = 1` | Constant-power active-current control | 恒功率型有功电流控制 |
| `ctrlType = 2` | Constant-current active-current control | 恒电流型有功电流控制 |

### Photovoltaic case / 光伏算例

```matlab
s = [2;4;2;4;2;2];
ctrlType = [1;1;1;2;2;2];
```

This means:

这表示：

| Unit | Capacity | Control type |
|---:|---:|---|
| 1 | 2 MW | CP |
| 2 | 4 MW | CP |
| 3 | 2 MW | CP |
| 4 | 4 MW | CC |
| 5 | 2 MW | CC |
| 6 | 2 MW | CC |

### Wind farm case / 风电场算例

```matlab
s = [2;4;2;4;2;2;2;4;2;4;2;2];
ctrlType = [1;2;1;2;1;1;1;2;1;2;1;1];
```

---

## 3. Detailed-Model Control Parameters / 详细模型控制参数

| Parameter | Meaning | 中文含义 |
|---|---|---|
| `pv.Id0_single` | Initial active-current command | 初始有功电流指令 |
| `pv.Iq0_single` | Initial reactive-current command | 初始无功电流指令 |
| `pv.Imax_single_vec` | Per-unit current limit of each device | 每台设备的电流限幅 |
| `pv.vpre` | Pre-fault control voltage | 故障前控制电压 |
| `pv.constP.vL` | LVRT entry threshold for CP units | 恒功率单元低穿进入阈值 |
| `pv.constP.vtrip` | Tripping threshold for CP units | 恒功率单元脱网阈值 |
| `pv.constP.vblock` | Blocking threshold for CP units | 恒功率单元封波阈值 |
| `pv.constI.vL` | LVRT entry threshold for CC units | 恒电流单元低穿进入阈值 |
| `pv.constI.vtrip` | Tripping threshold for CC units | 恒电流单元脱网阈值 |
| `pv.constI.vblock` | Blocking threshold for CC units | 恒电流单元封波阈值 |
| `pv.priority` | Current-limiting priority | 电流限幅优先级 |

---

## 4. Current-Limiting Priority / 电流限幅优先级

The code supports three priority rules:

代码支持三种电流限幅优先级：

| Value | Meaning | 中文含义 |
|---|---|---|
| `equal` | Proportional limiting | 等比例限幅 |
| `q_first` | Reactive-current priority | 无功优先 |
| `p_first` | Active-current priority | 有功优先 |

In the current cases:

在当前算例中：

```matlab
pv.priority = 'q_first';
```

This means that the reactive-current command is preserved first during current limiting.

这表示进入电流限幅时优先保留无功电流指令。

---

## 5. Equivalent-Model Parameters / 等值模型参数

| Parameter | Meaning | 中文含义 |
|---|---|---|
| `pv_eq.A` | Capacity ratio of CP units | 恒功率容量占比 |
| `pv_eq.B` | Capacity ratio of CC units | 恒电流容量占比 |
| `pv_eq.Seq` | Equivalent capacity | 等值容量 |
| `pv_eq.Imax_single` | Equivalent current limit | 等值电流限幅 |
| `pv_eq.vtrip` | Equivalent tripping threshold | 等值脱网阈值 |
| `pv_eq.vblock` | Equivalent blocking threshold | 等值封波阈值 |
| `pv_eq.priority` | Equivalent current-limiting priority | 等值限幅优先级 |

---

## 6. PV Benchmark Parameters / 光伏算例参数

| Case | Group | Imax | voff / vtrip | Meaning |
|---|---|---:|---:|---|
| I-a | All PVs | 1.0 | 0.4 | Homogeneous CP |
| I-b | All PVs | 1.0 | 0.4 | Mixed CP/CC with common thresholds |
| II | CP units | 1.0 | 0.4 | Admissible-Law-Approximation Error case |
| II | CC units | 1.1 | 0.3 | Admissible-Law-Approximation Error case |
| III | All PVs | 1.0 | 0.4 | Common-Voltage-Reduction Error case |

---

## 7. Wind Farm Case IV Parameters / 风电场算例 IV 参数

| Type | kq | Imax | voff | Turbine indices |
|---|---:|---:|---:|---|
| Type-A | 2.7 | 1.1 | 0.4 | 1, 3, 5, 6, 7, 9, 11, 12 |
| Type-B | 2.2 | 1.0 | 0.3 | 2, 4, 8, 10 |

---

## 8. Error Variables / 误差变量

| Variable | Meaning | 中文含义 |
|---|---|---|
| `H` | Original PCC current | 原始详细模型并网点电流 |
| `Hc` | Common-voltage model PCC current | 公共电压模型并网点电流 |
| `Heq` | Aggregated equivalent PCC current | 等值模型并网点电流 |
| `ecv` | Common-Voltage-Reduction Error | 同电压压缩误差 |
| `eal` | Admissible-Law-Approximation Error | 允许函数类近似误差 |
| `etot` | Total aggregation error | 总聚合误差 |
| `bcv` | Passive-network bias | 被动网络偏差 |
| `rI_alpha` | Common-voltage KCL residual | 公共电压 KCL 残差 |
| `delta_ab` | Admissible-law residual | 可允许允许函数类近似残差 |
| `mI` | Original-side branch mismatch residual | 原始侧分支切换残差 |
| `me` | Equivalent-side branch mismatch residual | 等值侧分支切换残差 |

---

## 9. Propagation and Conditioning / 传播算子与条件数

| Variable | Meaning | 中文含义 |
|---|---|---|
| `condMI_piecewise` | Condition number of original-side sensitivity matrix | 原始侧灵敏度矩阵条件数 |
| `condMe_piecewise` | Condition number of equivalent-side sensitivity matrix | 等值侧灵敏度矩阵条件数 |
| `Kcv_piecewiseNorm` | Norm of common-voltage-reduction propagation operator | 同电压压缩误差传播算子范数 |
| `Kal_piecewiseNorm` | Norm of admissible-law-approximation propagation operator | 允许函数类近似误差传播算子范数 |
