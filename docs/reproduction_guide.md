# Reproduction Guide / 复现说明

## 1. Environment / 运行环境

The MATLAB scripts require:

MATLAB 程序需要：

```text
MATLAB R2020b or later
Optimization Toolbox
```

The nonlinear equations are solved using `fsolve`.

非线性方程使用 `fsolve` 求解。

---

## 2. Repository Preparation / 仓库准备

After downloading or cloning the repository, open MATLAB in the repository root directory.

下载或克隆仓库后，在仓库根目录打开 MATLAB。

The expected structure is:

推荐仓库结构为：

```text
IBR-LVRT-Aggregation-Cases/
├── README.md
├── data/
├── docs/
├── matlab/
├── results/
└── tests/
```

---

## 3. Run the Photovoltaic Case / 运行光伏算例

```matlab
addpath('matlab');
photovoltaic_case;
```

This script runs the six-PV LVRT aggregation case.

该脚本运行六光伏低穿聚合等值算例。

Expected outputs include:

预期输出包括：

- PCC current comparison  
  并网点电流对比图

- Aggregation error decomposition  
  聚合误差分解图

- Common-voltage-reduction and Admissible-Law-Approximation Error approximation  
  同电压压缩误差和允许函数类近似误差近似图

- Terminal voltage curves  
  端电压变化曲线

---

## 4. Run the Wind Farm Case / 运行风电场算例

```matlab
addpath('matlab');
wind_farm_case;
```

This script runs the offshore wind farm LVRT aggregation case.

该脚本运行海上风电场低穿聚合等值算例。

Expected outputs include:

预期输出包括：

- PCC current comparison between original, aggregated, and EMT points  
  原始模型、等值模型和 EMT 点的并网点电流对比图

- Aggregation error decomposition  
  聚合误差分解图

- d/q decomposition of selected error terms  
  误差项 d/q 分解图

- Propagation-operator norm curves  
  传播算子范数曲线

- Wind-turbine terminal-voltage curves  
  风机端电压变化曲线

---

## 5. Run All Cases / 运行全部算例

```matlab
addpath('matlab');
run_all_cases;
```

This runs both the photovoltaic and wind farm cases.

该命令依次运行光伏算例和风电场算例。

---

## 6. Check the Results / 检查结果

After running the scripts, MATLAB will generate figures directly.

运行脚本后，MATLAB 会直接生成图像。

The scripts also save key results into the MATLAB workspace, usually as a structure named:

脚本还会将关键结果保存到 MATLAB 工作区，一般变量名为：

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
result.condMI_piecewise
result.condMe_piecewise
result.Kcv_piecewiseNorm
result.Kal_piecewiseNorm
```

---

## 7. Optional: Save Figures / 可选：保存图像

If the code includes automatic figure saving, figures will be saved into:

如果代码中启用了自动保存图片，图像会保存到：

```text
results/
```

If not, figures can be manually exported from MATLAB.

如果没有启用自动保存，也可以在 MATLAB 图窗中手动导出。

---

## 8. Common Problems / 常见问题

### Problem 1: `fsolve` is not found

### 问题 1：找不到 `fsolve`

Reason:

原因：

```text
Optimization Toolbox is not installed.
```

```text
未安装 Optimization Toolbox。
```

Solution:

解决方法：

```text
Install MATLAB Optimization Toolbox.
```

```text
安装 MATLAB Optimization Toolbox。
```

---

### Problem 2: MATLAB cannot find the function

### 问题 2：MATLAB 找不到函数

Reason:

原因：

```text
The matlab/ folder has not been added to the MATLAB path.
```

```text
没有把 matlab/ 文件夹加入 MATLAB 路径。
```

Solution:

解决方法：

```matlab
addpath('matlab');
```

---

### Problem 3: The function name does not match the file name

### 问题 3：函数名和文件名不一致

In MATLAB, the first function name must match the `.m` file name.

在 MATLAB 中，主函数名必须和 `.m` 文件名一致。

For example:

例如：

```text
photovoltaic_case.m  ->  function photovoltaic_case
wind_farm_case.m     ->  function wind_farm_case
```

---

## 9. Recommended Reproduction Order / 推荐复现顺序

```text
1. Read README.md
2. Read docs/model_description.md
3. Read docs/parameter_description.md
4. Run photovoltaic_case
5. Run wind_farm_case
6. Compare generated figures with the paper figures
```

```text
1. 阅读 README.md
2. 阅读 docs/model_description.md
3. 阅读 docs/parameter_description.md
4. 运行 photovoltaic_case
5. 运行 wind_farm_case
6. 将生成图像与论文图像进行对比
```
