# Model Description / 模型说明

## Purpose / 目的

This repository studies whether the LVRT response of an IBR cluster can be represented by one aggregated equivalent unit.

本仓库研究一个 IBR 集群的低电压穿越响应是否可以由一个聚合等值单元表示。

## Original Detailed Model / 原始详细模型

The original network contains one PCC node and multiple internal IBR terminal nodes.

原始网络包含一个并网点节点和多个 IBR 端节点。

```math
\begin{bmatrix} I_p \\ I_I \end{bmatrix}
=
\begin{bmatrix} Y_{pp} & Y_{pI} \\ Y_{Ip} & Y_{II} \end{bmatrix}
\begin{bmatrix} V_p \\ V_I \end{bmatrix}
```

Each IBR is represented by a voltage-dependent LVRT current law:

每台 IBR 由电压相关的低穿电流函数表示：

```math
I_i = f_i(V_i)
```

## Aggregated Equivalent Model / 聚合等值模型

The aggregated model uses a reduced equivalent network and one equivalent IBR current law.

聚合等值模型使用一个降阶等值网络和一个等值 IBR 电流函数。

```math
Y_{ep}^{eq}V_p + Y_{ee}^{eq}V_e = F(V_e)
```

## Common-Voltage Intermediate Model / 公共电压中间模型

The common-voltage model assumes that all IBR terminal voltages are equal to one common voltage.

公共电压模型假设所有 IBR 端电压都等于同一个公共电压。

```math
G(V_c) = \sum_i f_i(V_c)
```

## Error Decomposition / 误差分解

The updated codes use the following decomposition:

更新后的代码采用如下误差分解：

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

The branch-adaptive approximations are denoted as:

对应分支自适应近似记为：

```math
\hat{e}_{cv},\quad \hat{e}_{al}
```

| Term | Meaning | 中文含义 |
|---|---|---|
| `ecv` | common-voltage / Common-Voltage-Reduction Error | 同电压压缩误差 |
| `eal` | Admissible-Law-Approximation Error | 允许函数类近似误差 |
| `etot` | total aggregation error | 总聚合误差 |
| `^ecv` | approximation of `ecv` | `ecv` 的近似值 |
| `^eal` | approximation of `eal` | `eal` 的近似值 |
