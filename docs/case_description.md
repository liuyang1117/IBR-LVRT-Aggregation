# Case Description / 算例说明

## Overview / 概述

The paper uses four case studies to validate the LVRT aggregability analysis.

论文通过四组算例验证 IBR 集群低穿响应的聚合等值理论。

All currents are expressed in per unit with the system power base:

所有电流均以如下系统容量基准进行标幺化：

```text
Sbase = 100 MVA
```

The representative PCC voltage levels used for EMT validation are:

EMT 验证中使用的典型并网点电压水平为：

```text
|Vp| = 1.0, 0.8, 0.6, 0.5, 0.4, 0.3, 0.2 p.u.
```

---

## Case I-a / 算例 I-a

### English

Case I-a is an exact-aggregatable benchmark.  
All six PV units are connected under the common-voltage condition and use homogeneous constant-power (CP) LVRT commands.  
Because all units share the same normalized LVRT law and the same voltage input, their physical summed current law remains admissible.

### 中文

算例 I-a 是一个可精确聚合的基准算例。  
六台光伏单元处于公共电压条件下，并采用同质的恒功率（CP）低穿指令。  
由于所有单元具有相同的归一化低穿规律，并且输入电压相同，因此物理求和后的电流函数仍属于可允许的低穿函数类。

### Key parameters / 关键参数

```text
Imax = 1.0
voff = 0.4
```

---

## Case I-b / 算例 I-b

### English

Case I-b is also exact-aggregatable.  
The six PV units are still under the common-voltage condition.  
Units 1, 3, 5, and 6 use constant-power commands, while units 2 and 4 use constant-current commands.  
The LVRT entry threshold, current limit, and tripping threshold are kept common.

### 中文

算例 I-b 同样可以精确聚合。  
六台光伏单元仍处于公共电压条件下。  
其中 1、3、5、6 号单元采用恒功率指令，2、4 号单元采用恒电流指令。  
低穿进入阈值、电流限幅值和脱网阈值保持一致。

### Key parameters / 关键参数

```text
Imax = 1.0
voff = 0.4
```

---

## Case II / 算例 II

### English

Case II keeps the common-voltage setting of Case I-b but introduces different current limits and tripping thresholds between CP and CC units.  
The common-voltage-reduction mechanism is removed, but the physical summed current law may contain multiple switching boundaries.  
Therefore, the aggregation error is dominated by the Admissible-Law-Approximation Error `e_al`.

### 中文

算例 II 保留算例 I-b 的公共电压条件，但在恒功率单元和恒电流单元之间引入不同的电流限幅值和脱网阈值。  
此时同电压压缩机制被消除，但物理求和后的电流函数可能包含多个切换边界。  
因此，该算例的聚合误差主要由允许函数类近似误差 `e_al` 主导。

### Key parameters / 关键参数

```text
CP group: Imax = 1.0, voff = 0.4
CC group: Imax = 1.1, voff = 0.3
```

---

## Case III / 算例 III

### English

Case III uses homogeneous CP commands but modifies the network parameters so that different PV units experience different terminal voltages.  
The individual LVRT laws are homogeneous, but the common-voltage condition no longer holds.  
Therefore, the aggregation error is dominated by the Common-Voltage-Reduction Error `e_cv`.

### 中文

算例 III 采用同质恒功率低穿指令，但通过修改网络参数使不同光伏单元经历不同的端电压。  
虽然各单元控制规律是同质的，但公共电压条件不再成立。  
因此，该算例的聚合误差主要由同电压压缩误差 `e_cv` 主导。

### Key parameters / 关键参数

```text
Imax = 1.0
voff = 0.4
```

---

## Case IV / 算例 IV

### English

Case IV is a realistic offshore wind farm case.  
It contains 12 PMSG wind turbines connected to the PCC through a collector network.  
The turbine terminal voltages are naturally nonuniform during LVRT.  
The turbines are divided into two types with different reactive-current support gains, current limits, and tripping thresholds.

### 中文

算例 IV 是一个实际海上风电场算例。  
该算例包含 12 台永磁同步发电机（PMSG）风机，并通过集电网络接入并网点。  
低穿期间，各风机端电压自然呈现不一致。  
12 台风机被划分为两类，两类风机具有不同的无功电流支撑系数、电流限幅值和脱网阈值。

### Key parameters / 关键参数

| Type / 类型 | kq | Imax | voff | Turbine indices / 风机编号 |
|---|---:|---:|---:|---|
| Type-A | 2.7 | 1.1 | 0.4 | 1, 3, 5, 6, 7, 9, 11, 12 |
| Type-B | 2.2 | 1.0 | 0.3 | 2, 4, 8, 10 |

---

## Error Summary / 误差结果总结

| Case | Dominant mechanism | 中文说明 |
|---|---|---|
| I-a | Exact aggregation | 精确聚合 |
| I-b | Exact aggregation | 精确聚合 |
| II | Admissible-Law-Approximation Error | 允许函数类近似误差主导 |
| III | Common-Voltage-Reduction Error | 同电压压缩误差主导 |
| IV | Both ecv and eal errors | 同电压压缩误差和允许函数类近似误差共同存在，允许函数类近似误差更明显 |
