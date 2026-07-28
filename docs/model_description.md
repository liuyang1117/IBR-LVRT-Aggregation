# Model Description / 模型说明

## 1. Purpose / 目的

This document explains the modeling framework used in the MATLAB cases for LVRT aggregation of inverter-based resource (IBR) clusters.

本文档说明 MATLAB 算例中使用的逆变器型电源（IBR）低电压穿越（LVRT）聚合等值建模框架。

The core question is:

核心问题是：

```text
When can the LVRT response of an IBR cluster be reproduced by one aggregated equivalent unit?
```

```text
什么时候一个 IBR 集群的低穿响应可以由一个等值单元准确复现？
```

---

## 2. Original Cluster Model / 原始集群模型

The original system contains one point of common coupling (PCC) and multiple IBR units.

原始系统由一个并网点（PCC）和多个 IBR 单元组成。

The nodal network equation is written as:

网络节点方程写为：

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
V_I
\end{bmatrix}
```

where:

其中：

| Symbol | Meaning | 中文含义 |
|---|---|---|
| `Vp` | PCC voltage | 并网点电压 |
| `Ip` | Network current injection at PCC | 并网点网络注入电流 |
| `VI` | IBR terminal-voltage vector | IBR 端电压向量 |
| `II` | Network current injections at IBR terminal nodes | IBR 端节点网络注入电流 |
| `Ypp, YpI, YIp, YII` | Admittance matrix blocks | 导纳矩阵分块 |

During LVRT steady state, each IBR is modeled as a voltage-controlled current source:

低穿稳态期间，每台 IBR 被建模为电压控制电流源：

```math
I_i = f_i(V_i)
```

The internal voltage vector is solved from:

内部电压向量由下式求解：

```math
Y_{Ip}V_p + Y_{II}V_I = f(V_I)
```

The external PCC current response of the original cluster is:

原始集群的外部并网点电流响应为：

```math
H(V_p) = -\left(Y_{pp}V_p + Y_{pI}V_I(V_p)\right)
```

---

## 3. Aggregated Equivalent Model / 聚合等值模型

The aggregated model replaces the original multi-IBR cluster with one equivalent IBR and one equivalent two-port network.

聚合等值模型用一个等值 IBR 和一个等值二端口网络替代原始多 IBR 集群。

The equivalent network equation is:

等值网络方程为：

```math
\begin{bmatrix}
I_p^{eq} \\
I_e
\end{bmatrix}
=
\begin{bmatrix}
Y_{pp}^{eq} & Y_{pe}^{eq} \\
Y_{ep}^{eq} & Y_{ee}^{eq}
\end{bmatrix}
\begin{bmatrix}
V_p \\
V_e
\end{bmatrix}
```

The equivalent internal voltage is determined by:

等值内部电压由下式确定：

```math
Y_{ep}^{eq}V_p + Y_{ee}^{eq}V_e = F(V_e)
```

The equivalent PCC current is:

等值并网点电流为：

```math
H_{eq}(V_p) = -\left(Y_{pp}^{eq}V_p + Y_{pe}^{eq}V_e(V_p)\right)
```

---

## 4. LVRT Current Function Class / 低穿电流函数类

The admissible LVRT current function generally contains three parts:

可允许的低穿电流函数通常包括三个部分：

1. Unsaturated current command  
   未限幅电流指令

2. Current-limiting operator  
   电流限幅算子

3. Gate / tripping logic  
   封波或脱网逻辑

The representative form is:

代表性形式为：

```math
\phi(V) = g(v)\left(u_d(v)+ju_q(v)\right)e^{j\theta}
```

where `V = ve^{jθ}`.

其中 `V = ve^{jθ}`。

---

## 5. Common-Voltage Intermediate Model / 公共电压中间模型

To separate error sources, the code introduces a common-voltage intermediate model.

为了分离误差来源，代码引入了公共电压中间模型。

The common-voltage approximation assumes:

公共电压近似假设：

```math
\hat{V}_I = \mathbf{1}V_c
```

The same-input summed current law is:

同输入电压下的总电流函数为：

```math
G(V_c) = \mathbf{1}^T f(\mathbf{1}V_c)
       = \sum_{i=1}^{n} f_i(V_c)
```

The common-voltage model satisfies:

公共电压模型满足：

```math
Y_{ee}^{eq}V_c + Y_{ep}^{eq}V_p = G(V_c)
```

The corresponding PCC current is:

对应并网点电流为：

```math
H_c(V_p) = -\left(Y_{pp}^{eq}V_p + Y_{pe}^{eq}V_c(V_p)\right)
```

---

## 6. Error Decomposition / 误差分解

The aggregation error is:

聚合误差为：

```math
e = H - H_{eq}
```

By inserting the common-voltage model, the error is decomposed as:

通过引入公共电压模型，误差可分解为：

```math
e = H - H_{eq}
  = \underbrace{H-H_c}_{e_{cv}}
  + \underbrace{H_c-H_{eq}}_{e_{al}}
```

where `e_cv` is the Common-Voltage-Reduction Error and `e_al` is the Admissible-Law-Approximation Error.

其中 `e_cv` 为同电压压缩误差，`e_al` 为允许函数类近似误差。

| Error term | Meaning | 中文含义 |
|---|---|---|
| `e_cv` | Common-Voltage-Reduction Error | 同电压压缩误差 |
| `e_al` | Admissible-Law-Approximation Error | 允许函数类近似误差 |
| `e` | Total aggregation error | 总聚合误差 |

### Common-Voltage-Reduction Error / 同电压压缩误差

`e_cv` measures the error introduced when the original multi-terminal voltage model is reduced to a common-voltage representation.

`e_cv` 衡量将原始多端电压模型压缩为同一公共电压表示时引入的误差。

### Admissible-Law-Approximation Error / 允许函数类近似误差

`e_al` measures the error introduced when the same-input summed current law is approximated by one admissible equivalent LVRT current law.

`e_al` 衡量将同输入总电流函数近似为一个允许的等值低穿电流函数类时引入的误差。

---

## 7. Exact Aggregability / 精确可聚合性

Exact aggregation requires:

精确聚合要求：

```math
H_{eq}(V_p) = H(V_p), \quad \forall V_p \in \Omega_p
```

The paper identifies two independent obstacles to exact aggregation:

论文指出，精确聚合存在两个相互独立的障碍：

1. Network-induced voltage dispersion  
   网络导致的端同电压压缩

2. Non-closure of heterogeneous LVRT laws under summation  
   异质低穿电流函数在求和下不封闭

---

## 8. Practical Interpretation / 工程理解

If `e_cv` dominates, the aggregation error mainly comes from the common-voltage reduction process.

如果 `e_cv` 占主导，说明聚合误差主要来自同电压压缩过程。

If `e_al` dominates, the aggregation error mainly comes from approximating the aggregated current response within the admissible equivalent law class.

如果 `e_al` 占主导，说明聚合误差主要来自允许等值函数类对聚合电流响应的近似。
