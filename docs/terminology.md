# Terminology / 术语说明

This repository uses the following error terminology consistently.

本仓库统一采用以下误差术语。

| Symbol | English name | Chinese name | Definition | 中文定义 |
|---|---|---|---|---|
| `ecv` / `e_cv` | Common-Voltage-Reduction Error | 同电压压缩误差 | Error caused by reducing multiple detailed internal terminal voltages to one common-voltage representation. | 将多个详细内部端电压压缩为一个公共电压表示时产生的误差。 |
| `eal` / `e_al` | Admissible-Law-Approximation Error | 允许函数类近似误差 | Error caused by approximating the summed heterogeneous LVRT current law using an admissible equivalent law. | 用允许的等值函数类去近似异质低穿控制律求和结果时产生的误差。 |
| `etot` | Total aggregation error | 总聚合误差 | Difference between the detailed model PCC current and the equivalent model PCC current. | 详细模型并网点电流与等值模型并网点电流之间的差值。 |

## Symbol relation / 符号关系

```math
H - H_{eq} = e_{cv} + e_{al}
```

where:

其中：

```math
e_{cv}=H-H_c
```

```math
e_{al}=H_c-H_{eq}
```
