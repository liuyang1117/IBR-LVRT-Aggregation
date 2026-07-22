# Model Description / 模型说明

## Network model / 网络模型

The network is represented by a nodal admittance matrix:

```math
\begin{bmatrix}
I_p \\
I_I
\end{bmatrix}
=
\begin{bmatrix}
Y_{pp} & Y_{pI} \\
Y_{Ip} & Y_{II}
\end{bmatrix}
\begin{bmatrix}
V_p \\
U
\end{bmatrix}
```

where `Vp` is the PCC voltage and `U` contains the internal passive node and all IBR terminal voltages.

网络采用节点导纳矩阵建模，其中 `Vp` 为并网点电压，`U` 包含中间无源节点和各逆变器端电压。

## Aggregated equivalent network / 聚合等值网络

The scripts construct an equivalent two-node network `Yeq` from the original detailed admittance matrix and capacity-weighting vector.

程序基于原始详细导纳矩阵和容量权重构造两节点等值网络 `Yeq`。

## Detailed IBR model / 详细逆变器模型

Each unit uses a voltage-dependent LVRT current model with:

- active-current command
- reactive-current command
- current-limiting priority
- current magnitude limit
- trip/block threshold

每台设备包含有功电流、无功电流、限幅优先级、电流限幅值和脱网/封波阈值。

## Common-voltage intermediate model / 公共电压中间模型

The common-voltage model assumes that all unit terminal voltages are represented by a shared voltage `Vc`.

公共电压模型假设所有设备端电压可由同一个公共电压 `Vc` 表示。

## Error decomposition / 误差分解

The total aggregation error is decomposed as:

```math
e = H - H_{eq} = e_{vd} + e_{fs}
```

where:

```math
e_{vd} = H - H_c
```

is the voltage-dispersion error, and

```math
e_{fs} = H_c - H_{eq}
```

is the function-structure error.

其中 `e_vd` 表示电压分散误差，`e_fs` 表示函数结构误差。

## Branch-adaptive approximation / 分支自适应近似

The scripts use branch-adaptive formulas:

- consistent branches
- inconsistent branches

程序根据公共电压分支与真实分支是否一致，自动选择对应的近似公式。
